// Copyright 2016 InnerFunction Ltd.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  Created by Julian Goacher on 13/09/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFCMSCommandProtocol.h"
#import "IFFileIO.h"
#import "IFCMSFileset.h"
#import "IFCMSContentAuthority.h"
#import "IFContentProvider.h"
#import "IFAppContainer.h"

#define URLEncode(s)    ([s stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]])
#define IsSecure        ([_authManager isLoggedIn] ? @"true" : @"false")

@interface IFCMSCommandProtocol ()

/// Start a content refresh.
- (QPromise *)refresh:(NSArray *)args;
/// Update the file db and fileset schema.
//- (QPromise *)updateSchema:(NSArray *)args;
/// Download a fileset.
- (QPromise *)downloadFileset:(NSArray *)args;

@end

@implementation IFCMSCommandProtocol

- (id)initWithAuthority:(IFCMSContentAuthority *)authority {
    self = [super init];
    if (self) {
        self.cms = authority.cms;
        _authManager = authority.authManager;
        _logoutAction = authority.logoutAction;
        // Use a copy of the file DB to avoid problems with multi-thread access.
        self.fileDB = [authority.fileDB newInstance];
        self.httpClient = authority.provider.httpClient;
        // Register command handlers.
        __block id this = self;
        [self addCommand:@"refresh" withBlock:^QPromise *(NSArray *args) {
            return [this refresh:args];
        }];
        /*
        [self addCommand:@"update-schema" withBlock:^QPromise *(NSArray *args) {
            return [this updateSchema:args];
        }];
        */
        [self addCommand:@"download-fileset" withBlock:^QPromise *(NSArray *args) {
            return [this downloadFileset:args];
        }];
    }
    return self;
}

- (QPromise *)refresh:(NSArray *)args {
    
    _promise = [QPromise new];
    
    NSString *refreshURL = [_cms urlForUpdates];
    
    // Query the file DB for the latest commit ID.
    NSString *commit = nil, *group = nil;
    NSMutableDictionary *params = [NSMutableDictionary new];
    params[@"secure"] = IsSecure;
    
    // Read current group fingerprint.
    NSDictionary *record = [_fileDB readRecordWithID:@"$group" fromTable:@"fingerprints"];
    if (record) {
        group = record[@"current"];
        params[@"group"] = group;
    }
    
    // Read latest commit ID.
    NSArray *rs = [_fileDB performQuery:@"SELECT id, max(date) FROM commits" withParams:@[]];
    if ([rs count] > 0) {
        // File DB contains previous commits, read latest commit ID and add as request parameter.
        NSDictionary *record = rs[0];
        commit = [record[@"id"] description];
        params[@"since"] = commit;
    }
    // Otherwise simply omit the 'since' parameter; the feed will return all records in the file DB.

    // Fetch updates from the server.
    [_httpClient get:refreshURL data:params]
    .then((id)^(IFHTTPClientResponse *response) {
    
        // Create list of follow up commands.
        NSMutableArray *commands = [NSMutableArray new];
        
        NSInteger responseCode = response.httpResponse.statusCode;
        if (responseCode == 401) {
            // Authentication failure.
            if (_logoutAction) {
                [[IFAppContainer getAppContainer] postMessage:_logoutAction sender:self];
            }
            else {
                [_authManager logout];
            }
            [_promise resolve:commands];
            return nil;
        }
        
        // Read the updates data.
        id updateData = [response parseData];
        if ([updateData isKindOfClass:[NSString class]]) {
            // Indicates a server error
            NSLog(@"%@ %@", response.httpResponse.URL, updateData);
            [_promise resolve:commands];
            return nil;
        }

        /*
        // Check file DB schema version.
        id version = [updateData valueForKeyPath:@"db.version"];
        if (![version isEqual:_fileDB.version]) {
            // Update the file DB schema and then schedule a new refresh.
            id updateSchema = @{
                @"name": [self qualifyName:@"update-schema"],
                @"args": @[ version ]
            };
            id refresh = @{
                @"name": [self qualifyName:@"refresh"],
                @"args": @[]
            };
            [commands addObject:updateSchema];
            [commands addObject:refresh];
            NSLog(@"Database version mismatch error");
        }
        else {
        */
            // Write updates to database.
            NSDictionary *updates = [updateData valueForKeyPath:@"db"];
            // A map of fileset category names to a 'since' commit value (may be null).
            NSMutableDictionary *updatedCategories = [NSMutableDictionary new];
        
            // Start a DB transaction.
            [_fileDB beginTransaction];
        
        
            // Check group fingerprint to see if a migration is needed.
            NSString *updateGroup = [updateData valueForKeyPath:@"repository.group"];
            BOOL migrate = ![group isEqualToString:updateGroup];
            if (migrate) {
                // Performing a migration due to an ACM group ID change; mark all files as
                // provisionaly deleted.
                [_fileDB performUpdate:@"UPDATE files SET status='deleted'" withParams:@[]];
            }
        
            // Shift current fileset fingerprints to previous.
            [_fileDB performUpdate:@"UPDATE fingerprints SET previous=current" withParams:@[]];

            // Apply all downloaded updates to the database.
            for (NSString *tableName in updates) {
                BOOL isFilesTable = [@"files" isEqualToString:tableName];
                NSArray *table = updates[tableName];
                for (NSDictionary *values in table) {
                    [_fileDB upsertValues:values intoTable:tableName];
                    // If processing the files table then record the updated file category name.
                    if (isFilesTable) {
                        NSString *category = values[@"category"];
                        NSString *status = values[@"status"];
                        if (category != nil && ![@"deleted" isEqualToString:status]) {
                            if (commit) {
                                updatedCategories[category] = commit;
                            }
                            else {
                                updatedCategories[category] = [NSNull null];
                            }
                        }
                    }
                }
            }
        
            // Check for deleted files.
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSArray *deleted = [_fileDB performQuery:@"SELECT id, path FROM files WHERE status='deleted'" withParams:@[]];
            for (NSDictionary *record in deleted) {
                // Delete cached file, if exists.
                NSString *path = [_fileDB cacheLocationForFile:record];
                if (path && [fileManager fileExistsAtPath:path]) {
                    [fileManager removeItemAtPath:path error:nil];
                }
            }
        
            // Delete obsolete records.
            [_fileDB performUpdate:@"DELETE FROM files WHERE status='deleted'" withParams:@[]];

            // Prune ORM related records.
            [_fileDB pruneRelatedValues];
        
            // Read list of fileset names with modified fingerprints.
            NSArray *rows = [_fileDB performQuery:@"SELECT category FROM fingerprints WHERE current != previous" withParams:@[]];
            for (NSDictionary *row in rows) {
                NSString *category = row[@"category"];
                if ([@"$group" isEqualToString:category]) {
                    // The ACM group fingerprint entry - skip.
                    continue;
                }
                // Map the category name to null - this indicates that the category is updated,
                // but there is no 'since' parameter, so download a full update.
                updatedCategories[category] = [NSNull null];
            }
        
            // Queue downloads of updated category filesets.
            NSString *command = [self qualifyName:@"download-fileset"];
            for (id category in [updatedCategories keyEnumerator]) {
                id since = updatedCategories[category];
                // Get cache location for fileset; if nil then don't download the fileset.
                NSString *cacheLocation = [_fileDB cacheLocationForFileset:category];
                if (cacheLocation) {
                    NSMutableArray *args = [NSMutableArray new];
                    [args addObject:category];
                    [args addObject:cacheLocation]; // Where to put the downloaded files.
                    if (since != [NSNull null]) {
                        [args addObject:since];
                    }
                    [commands addObject:@{ @"name": command, @"args": args }];
                }
            }

            // Commit the transaction.
            [_fileDB commitTransaction];
            
            // QUESTIONS ABOUT THE CODE ABOVE
            // 1. How does the code perform if the procedure above is interrupted before completion?
            // 2. How is app performance affected if the procedure above is continually interrupted?
            //    (e.g. due to repeated short-duration app starts).
            // 3. Are there ways (on iOS and Android) to run tasks like this with completion guarantees?
            //    e.g. the scheduler could register as a background task when app is put into the background;
            //    the task compeletes when the currently executing command completes.
            //    See https://developer.apple.com/library/content/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/BackgroundExecution/BackgroundExecution.html
            
        /* -- end of else after db version check
        }
        */
        [_promise resolve:commands];
        return nil;
    })
    .fail(^(id error) {
        NSString *msg = [NSString stringWithFormat:@"Updates download from %@ failed: %@", refreshURL, error];
        [_promise reject:msg];
    });
    
    // Return deferred promise.
    return _promise;
}

/*
- (QPromise *)updateSchema:(NSArray *)args {
    
    _promise = [[QPromise alloc] init];
    
    // Request the schema.
    id params = @{};
    if ([args count] > 0) {
        params = @{ @"version": args[0] };
    }
    NSString *schemaURL = [self feedURLWithRoot:@"schema" trailingPath:nil];
    [_httpClient get:schemaURL data:params]
    .then((id)^(IFHTTPClientResponse *response) {
        id schema = [response parseData];
        
        // TODO Migrate database to new schema version.
        // TODO Store new fileset schema
        
        // Queue content refresh.
        id name = [self qualifyName:@"refresh"];
        [_promise resolve:@[ @{ @"name": name, @"args": @[] }]];
        return nil;
    })
    .fail(^(id error) {
        NSString *msg = [NSString stringWithFormat:@"Schema download from %@ failed: %@", schemaURL, error];
        [_promise reject:msg];
    });
    
    // Return deferred promise.
    return _promise;
}
*/

- (QPromise *)downloadFileset:(NSArray *)args {
    
    _promise = [QPromise new];
    
    id category = args[0];
    id cachePath = args[1];
    
    // Build the fileset URL and query parameters.
    NSString *filesetURL = [_cms urlForFileset:category];
    NSMutableDictionary *data = [NSMutableDictionary new];
    data[@"secure"] = IsSecure;
    if ([args count] > 2) {
        data[@"since"] = args[2];
    }
    
    // Download the fileset.
    [_httpClient getFile:filesetURL data:data]
    .then((id)^(IFHTTPClientResponse *response) {
        // Unzip downloaded file to content location.
        NSString *downloadPath = [response.downloadLocation path];
        [IFFileIO unzipFileAtPath:downloadPath toPath:cachePath overwrite:YES];
        // Update the fileset's fingerprint.
        [_fileDB performUpdate:@"UPDATE fingerprints SET previous=current WHERE category=?" withParams:@[ category ]];
        // Resolve empty list - no follow-on commands.
        [_promise resolve:@[]];
        return nil;
    })
    .fail(^(id error) {
        NSString *msg = [NSString stringWithFormat:@"Fileset download from %@ failed: %@", filesetURL, error];
        [_promise reject:msg];
    });

    // Return deferred promise.
    return _promise;
}

@end
