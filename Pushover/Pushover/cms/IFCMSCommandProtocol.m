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

#define URLEncode(s) ([s stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]])

@interface IFCMSCommandProtocol ()

/// Start a content refresh.
- (QPromise *)refresh:(NSArray *)args;
/// Update the file db schema.
- (QPromise *)updateFileDBSchema:(NSArray *)args;
/// Download a fileset.
- (QPromise *)downloadFileset:(NSArray *)args;
/// Unpack content packaged with the app.
- (QPromise *)unpack:(NSArray *)args;

@end

@implementation IFCMSCommandProtocol

- (id)init {
    self = [super init];
    if (self) {
        // Register command handlers.
        __block id this = self;
        [self addCommand:@"refresh" withBlock:^QPromise *(NSArray *args) {
            return [this refresh:args];
        }];
        [self addCommand:@"update-file-db-schema" withBlock:^QPromise *(NSArray *args) {
            return [this updateFileDBSchema:args];
        }];
        [self addCommand:@"download-fileset" withBlock:^QPromise *(NSArray *args) {
            return [this downloadFileset:args];
        }];
        [self addCommand:@"unpack" withBlock:^QPromise *(NSArray *args) {
            return [this unpack:args];
        }];
        // TODO Replace this with just a single, live promise instance - only one command will be executed at any time?
        _promises = [NSMutableSet new];
    }
    return self;
}

- (QPromise *)refresh:(NSArray *)args {
    
    QPromise *promise = [[QPromise alloc] init];
    [_promises addObject:promise];
    
    NSString *refreshURL = [_feedURL stringByAppendingString:@"/updates"];
    
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
        if (![version isEqualToString:_fileDBSchemaVersion]) {
            // Update the file DB schema and then schedule a new refresh.
            id updateSchema = @{
                @"name": [self qualifiedCommandName:@"update-file-db-schema"],
                @"args": @[ version ]
            };
            id refresh = @{
                @"name": [self qualifiedCommandName:@"refresh"],
                @"args": @[]
            };
            [commands addObject:updateSchema];
            [commands addObject:refresh];
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
            [_fileDB commitTransaction];
            // Queue downloads of updated category filesets.
            for (id category in updatedCategories) {
                NSString *name = [self qualifiedCommandName:@"download-fileset"];
                NSMutableArray *args = [NSMutableArray new];
                [args addObject:category];
                if (commit) {
                    [args addObject:commit];
                }
                [commands addObject:@{ @"name": name, @"args": args }];
            }
        }
        [promise resolve:commands];
        [_promises removeObject:promise];
        return nil;
    })
    .fail(^(id error) {
        NSString *msg = [NSString stringWithFormat:@"Download from %@ failed: %@", refreshURL, error];
        [promise reject:msg];
        [_promises removeObject:promise];
    });
    
    // Return deferred promise.
    return promise;
}

- (QPromise *)updateFileDBSchema:(NSArray *)args {
    
    QPromise *promise = [[QPromise alloc] init];
    [_promises addObject:promise];
    
    // Request the schema.
    id params = @{};
    if ([args count] > 0) {
        params = @{ @"version": args[0] };
    }
    NSString *schemaURL = [_feedURL stringByAppendingString:@"/schema"];
    [_httpClient get:schemaURL data:params]
    .then((id)^(IFHTTPClientResponse *response) {
        id schema = [response parseData];
        // TODO Migrate database to new schema version.
        // Queue content refresh.
        id name = [self qualifiedCommandName:@"refresh"];
        [promise resolve:@[ @{ @"name": name, @"args": @[] }]];
        [_promises removeObject:promise];
        return nil;
    })
    .fail(^(id error) {
        NSString *msg = [NSString stringWithFormat:@"Download from %@ failed: %@", schemaURL, error];
        [promise reject:msg];
        [_promises removeObject:promise];
    });
    
    // Return deferred promise.
    return promise;
}

- (QPromise *)downloadFileset:(NSArray *)args {
    
    QPromise *promise = [[QPromise alloc] init];
    [_promises addObject:promise];
    
    // Build the fileset URL.
    id category = args[0];
    NSString *filesetPath;
    if ([args count] > 1) {
        id commit = args[1];
        filesetPath = [NSString stringWithFormat:@"/fileset/%@?since=%@", category, commit];
    }
    else {
        filesetPath = [NSString stringWithFormat:@"/fileset/%@", category];
    }
    NSString *filesetURL = [_feedURL stringByAppendingString:filesetPath];
    
    // Download the fileset.
    [_httpClient getFile:filesetURL]
    .then((id)^(IFHTTPClientResponse *response) {
        
        // Unzip downloaded file to content location.
        NSString *downloadPath = [response.downloadLocation path];
        [IFFileIO unzipFileAtPath:downloadPath toPath:_contentPath overwrite:YES];
        // Resolve empty list - no follow-on commands.
        [promise resolve:@[]];
        [_promises removeObject:promise];
        return nil;
    })
    .fail(^(id error) {
        NSString *msg = [NSString stringWithFormat:@"Download from %@ failed: %@", filesetURL, error];
        [promise reject:msg];
        [_promises removeObject:promise];
    });

    // Return deferred promise.
    return promise;
}

- (QPromise *)unpack:(NSArray *)args {
    // TODO Copy packaged file db from app to installed location.
    return nil;
}

@end
