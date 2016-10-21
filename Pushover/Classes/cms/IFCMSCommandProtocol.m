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

#define URLEncode(s) ([s stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]])

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
        self.fileDB = authority.fileDB;
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
    
    _promise = [[QPromise alloc] init];
    
    NSString *refreshURL = [_cms urlForUpdates];
    
    // Query the file DB for the latest commit ID.
    NSString *commit = nil;
    NSDictionary *params = @{};
    NSArray *rs = [_fileDB performQuery:@"SELECT commit, max(date) FROM commits GROUP BY commit" withParams:@[]];
    if ([rs count] > 0) {
        // File DB contains previous commits, read latest commit ID and add as request parameter.
        NSDictionary *record = rs[0];
        commit = record[@"commit"];
        params = @{ @"since": URLEncode(commit) };
    }
    // Otherwise simply omit the 'since' parameter; the feed will return all records in the file DB.

    // Fetch updates from the server.
    [_httpClient get:refreshURL data:params]
    .then((id)^(IFHTTPClientResponse *response) {
        // Create list of follow up commands.
        NSMutableArray *commands = [NSMutableArray new];
        // Read the updates data.
        id updateData = [response parseData];
        // Check file DB schema version.
        id version = [updateData valueForKeyPath:@"db.version"];
        if (![version isEqual:_fileDB.version]) {
            /*
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
            */
            NSLog(@"Database version mismatch error");
        }
        else {
            // Write updates to database.
            NSDictionary *updates = [updateData valueForKeyPath:@"updates"];
            NSMutableSet *updatedCategories = [NSMutableSet new];
            [_fileDB beginTransaction];
            for (NSString *tableName in updates) {
                NSArray *table = updates[tableName];
                for (NSDictionary *values in table) {
                    [_fileDB upsertValues:values intoTable:tableName];
                    // Record the updated category name.
                    [updatedCategories addObject:[values valueForKey:@"category"]];
                }
            }
            // Check for trashed files.
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSArray *trashed = [_fileDB performQuery:@"SELECT id, path FROM files WHERE status='trashed'" withParams:@[]];
            NSMutableArray *trashedIDs = [NSMutableArray new];
            for (NSDictionary *record in trashed) {
                [trashedIDs addObject:record[@"id"]];
                // Delete cached file, if exists.
                NSString *path = [_fileDB cacheLocationForFile:record];
                if (path && [fileManager fileExistsAtPath:path]) {
                    [fileManager removeItemAtPath:path error:nil];
                }
            }
            // Delete trashed records.
            if ([trashedIDs count]) {
                [_fileDB deleteIDs:trashedIDs fromTable:@"files"];
            }
            // Prune related records.
            [_fileDB pruneRelatedValues];
            // Commit the transaction.
            [_fileDB commitTransaction];
            
            // QUESTIONS ABOUT THE CODE ABOVE
            // 1. How does the code perform if the procedure above is interrupted before completion?
            // 2. How is app performance affected if the procedure above is continually interrupted?
            //    (e.g. due to repeated short-duration app starts).
            // 3. How does the code perform if the procedure above completes, but the following code is interrupted?
            // 4. Are there ways (on iOS and Android) to run tasks like this with completion guarantees?
            //    e.g. the scheduler could register as a background task when app is put into the background;
            //    the task compeletes when the currently executing command completes.
            //    See https://developer.apple.com/library/content/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/BackgroundExecution/BackgroundExecution.html
            
            // Queue downloads of updated category filesets.
            NSString *name = [self qualifyName:@"download-fileset"];
            for (id category in updatedCategories) {
                // Get cache location for fileset; if nil then don't download the fileset.
                NSString *cacheLocation = [_fileDB cacheLocationForFileset:category];
                if (cacheLocation) {
                    NSMutableArray *args = [NSMutableArray new];
                    [args addObject:category];
                    [args addObject:cacheLocation]; // Where to put the downloaded files.
                    if (commit) {
                        [args addObject:commit];
                    }
                    [commands addObject:@{ @"name": name, @"args": args }];
                }
            }
        }
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
    
    _promise = [[QPromise alloc] init];
    
    id category = args[0];
    id cachePath = args[1];
    
    // Build the fileset URL.
    NSString *filesetURL = [_cms urlForFileset:category];
    NSDictionary *data = nil;
    if ([args count] > 2) {
        id commit = args[2];
        data = @{ @"since": commit };
    }
    
    // Download the fileset.
    [_httpClient getFile:filesetURL data:data]
    .then((id)^(IFHTTPClientResponse *response) {
        // Unzip downloaded file to content location.
        NSString *downloadPath = [response.downloadLocation path];
        [IFFileIO unzipFileAtPath:downloadPath toPath:cachePath overwrite:YES];
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
