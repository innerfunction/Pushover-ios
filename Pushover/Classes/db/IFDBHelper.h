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

#import <Foundation/Foundation.h>
#import "PlausibleDatabase.h"

/// A protocol used to delegate certain database lifecyle events.
@protocol IFDBHelperDelegate <NSObject>

/// Handle database creation; used to setup the initial database schema.
- (void)onCreate:(id<PLDatabase>)database;
/// Handle a database schema upgrade.
- (void)onUpgrade:(id<PLDatabase>)database from:(int)oldVersion to:(int)newVersion;

@optional

/// Handle a database open.
- (void)onOpen:(id<PLDatabase>)database;

@end

@interface IFDBHelper : NSObject <PLDatabaseMigrationDelegate> {
    /// The database name.
    NSString *_databaseName;
    /// The database schema version.
    int _databaseVersion;
    /// The path to the database file.
    NSString *_databasePath;
    /// A connection provider.
    id<PLDatabaseConnectionProvider> _connectionProvider;
    /// The database.
    id<PLDatabase> _database;
}

/// Delegate for handling database creation / upgrade.
@property (nonatomic, strong) id<IFDBHelperDelegate> delegate;
/**
 * The path to an initial copy of the database. Used to provide an initial version of the database
 * schema and content; if specified, then the file at this location is copied to the database path
 * before a database connection is opened.
 */
@property (nonatomic, strong) NSString *initialCopyPath;

/// Initialize the helper with a database name and version.
- (id)initWithName:(NSString *)name version:(int)version;
/// Delete the database.
- (BOOL)deleteDatabase;
/// Get a connection to the database.
- (id<PLDatabase>)getDatabase;
/// Close the database.
- (void)close;

@end
