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
//  Created by Julian Goacher on 07/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "Pushover.h"
#import "IFDBHelper.h"
#import "IFLogger.h"

static IFLogger *Logger;

@implementation IFDBHelper

+ (void)initialize {
    Logger = [[IFLogger alloc] initWithTag:@"IFDBHelper"];
}

- (id)initWithName:(NSString *)name version:(int)version {
    self = [super init];
    if (self) {
        _databaseName = name;
        _databaseVersion = version;
        // See http://stackoverflow.com/questions/11252173/ios-open-sqlite-database
        // Need to review whether this is the best/correct location for the db.
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        _databasePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", _databaseName]];
    }
    return self;
}

- (BOOL)deleteDatabase {
    BOOL ok = YES;
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:_databasePath]) {
        [fileManager removeItemAtPath:_databasePath error:&error];
        if (error) {
            [Logger warn:@"Error deleting database at %@: %@", _databasePath, error];
            ok = NO;
        }
    }
    return ok;
}

- (id<PLDatabase>)getDatabase {
    // First check whether to deploy the initial database copy.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:_databasePath] && _initialCopyPath) {
        [Logger debug:@"Copying initial database from %@", _initialCopyPath];
        NSError *error = nil;
        [fileManager copyItemAtPath:_initialCopyPath toPath:_databasePath error:&error];
        if (error) {
            [Logger warn:@"Error copying initial database: %@", error];
        }
    }
    // Check that a connection provider is initialized.
    if (!_connectionProvider) {
        [Logger debug:@"Connecting to database %@...", _databasePath];
        _connectionProvider = [[PLSqliteConnectionProvider alloc] initWithPath:_databasePath];
    }
    // Connect to database.
    id<PLDatabase> result;
    if (_database && [_database goodConnection]) {
        result = _database;
    }
    else {
        // TODO: Is this the correct way to instantiate this class?
        PLSqliteMigrationVersionManager *migrationVersionManager = [[PLSqliteMigrationVersionManager alloc] init];
        // TODO: Is this the correct way to instantiate & invoke this class? Will it work correctly if no migration is necessary?
        PLDatabaseMigrationManager *migrationManager
        = [[PLDatabaseMigrationManager alloc] initWithConnectionProvider:_connectionProvider
                                                      transactionManager:migrationVersionManager
                                                          versionManager:migrationVersionManager
                                                                delegate:self];
        NSError *error = nil;
        if ([migrationManager migrateAndReturnError:&error]) {
            // TODO: Will previous method close its db connection on exit?
            result = [_connectionProvider getConnectionAndReturnError:&error];
            if (error) {
                [Logger error:@"getDatabase failed to open connection %@", [error localizedDescription]];
            }
        }
        else {
            if (error) {
                // TODO
                [Logger error:@"getDatabase failed to migrate connection %@", [error localizedDescription]];
            }
        }
    }
    _database = result;
    return result;
}

- (void)close {
    [_database close];
    _database = nil;
}

- (BOOL)migrateDatabase:(id<PLDatabase>)db currentVersion:(int)currentVersion newVersion:(int *)newVersion error:(NSError *__autoreleasing *)outError {
    if (currentVersion == 0) {
        [self.delegate onCreate:db];
    }
    else if (currentVersion < _databaseVersion) {
        [self.delegate onUpgrade:db from:currentVersion to:_databaseVersion];
    }
    *newVersion = _databaseVersion;
    return YES;
}

@end
