// Copyright 2017 InnerFunction Ltd.
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
//  Created by Julian Goacher on 23/02/2017.
//  Copyright © 2017 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sqlite3.h"

@class IFSqliteResultSet;
@class IFSqlitePreparedStatement;

/// A wrapper for an SQLite database.
@interface IFSqliteDB : NSObject {
    /// The path to the database file.
    NSString *_dbPath;
    /// The database handle.
    sqlite3 *_db;
}

/// A flag indicating that the database is open and available.
@property (nonatomic, assign) BOOL open;

/// Connect to the database at the specified path.
- (id)initWithDBPath:(NSString *)dbPath error:(NSError **)error;
/// Prepare a SQL statement.
- (IFSqlitePreparedStatement *)prepareStatement;
/**
 * Prepare a SQL statement.
 * @param sql           The statement SQL.
 * @param parameters    The statement's parameter values.
 */
- (IFSqlitePreparedStatement *)prepareStatement:(NSString *)sql parameters:(NSArray *)parameters;
/// Execute a query and return the result.
- (IFSqliteResultSet *)executeQuery:(NSString *)sql error:(NSError **)error;
/// Execute a query and return the result.
- (IFSqliteResultSet *)executeQuery:(NSString *)sql parameters:(NSArray *)parameters error:(NSError **)error;
/// Execute an update.
- (void)executeUpdate:(NSString *)sql error:(NSError **)error;
/// Execute an update.
- (void)executeUpdate:(NSString *)sql parameters:(NSArray *)parameters error:(NSError **)error;
/// Begin a database transaction.
- (void)beginTransaction:(NSError **)error;
/// Commit a database transaction.
- (void)commitTransaction:(NSError **)error;
/// Rollback the current database transaction.
- (void)rollbackTransaction:(NSError **)error;
/// Close the database connection.
- (void)close;

@end

/// A query result set.
@interface IFSqliteResultSet : NSObject {
    /// The result set's parent statement.
    IFSqlitePreparedStatement *_parent;
    /// The statement that generated this result set.
    sqlite3_stmt *_statement;
}

/// The number of columns in the result set.
@property (nonatomic, assign) NSInteger columnCount;

/// Initialize the result set with the source statement.
- (id)initWithParent:(IFSqlitePreparedStatement *)parent statement:(sqlite3_stmt *)statement;
/// Step to the next result set row.
- (BOOL)next;
/// Get a column name.
- (NSString *)columnName:(NSInteger)columnIndex;
/// Get a column value.
- (id)columnValue:(NSInteger)columnIndex;
/// Get a column value as an integer.
- (NSInteger)columnValueAsInteger:(NSInteger)columnIndex;
/// Test whether a column has a null value.
- (BOOL)isColumnValueNull:(NSInteger)columnIndex;
/// Close the result set.
- (void)close;

@end

/// A prepared SQL statement.
@interface IFSqlitePreparedStatement : NSObject {
    /// The database.
    sqlite3 *_db;
    /// The statement.
    sqlite3_stmt *_statement;
    /// A statement compilation error.
    NSError *_compilationError;
}

/// The number of parameters the statement accepts.
@property (nonatomic, assign) NSInteger parameterCount;
/// The statement's SQL.
@property (nonatomic, strong) NSString *sql;
/// The statement's parameter values.
@property (nonatomic, strong) NSArray *parameters;

/// Initialize the statement.
- (id)initWithDB:(sqlite3 *)db;
/// Initialize the statement with the provided SQL and parameter values.
- (id)initWithDB:(sqlite3 *)db sql:(NSString *)sql parameters:(NSArray *)parameters;
/// Execute a quert and return the result.
- (IFSqliteResultSet *)executeQuery;
/// Execute a quert and return the result.
- (IFSqliteResultSet *)executeQuery:(NSError **)error;
/// Execute an update.
- (BOOL)executeUpdate;
/// Execute an update.
- (BOOL)executeUpdate:(NSError **)error;
/// Reset the statement after use.
- (void)reset;
/// Close the statement.
- (void)close;

@end
