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

#import "IFSqlite.h"

#define IFSqliteBusyTimeout (30 * 1000)
#define IFSqliteException   (@"IFSqliteException")
#define IFSqliteError       (@"IFSqliteError")

@implementation IFSqliteDB

- (id)initWithDBPath:(NSString *)dbPath {
    self = [super init];
    if (self) {
        _dbPath = dbPath;
        BOOL ok = YES;
        if (![[NSFileManager defaultManager] fileExistsAtPath:_dbPath]) {
            _openError = [NSString stringWithFormat:@"Database file not found: %@", _dbPath];
            ok = NO;
        }
        int error;
        if (ok) {
            error = sqlite3_open([_dbPath fileSystemRepresentation], &_db);
            if (error != SQLITE_OK) {
                _openError = [NSString stringWithFormat:@"Error opening database: %s", sqlite3_errmsg(_db)];
                ok = NO;
            }
        }
        if (ok) {
            error = sqlite3_busy_timeout(_db, IFSqliteBusyTimeout);
            if (error != SQLITE_OK) {
                _openError = [NSString stringWithFormat:@"Error connecting to database: %s", sqlite3_errmsg(_db)];
                ok = NO;
            }
        }
        self.open = ok;
    }
    return self;
}

- (void)validate {
    if (!_open) {
        if (_openError) {
            [NSException raise:IFSqliteException format:@"%@", _openError];
        }
        else {
            [NSException raise:IFSqliteException format:@"Sqlite database is not open"];
        }
    }
}

- (IFSqlitePreparedStatement *)prepareStatement {
    return [[IFSqlitePreparedStatement alloc] initWithDB:_db];
}

- (IFSqlitePreparedStatement *)prepareStatement:(NSString *)sql parameters:(NSArray *)parameters {
    return [[IFSqlitePreparedStatement alloc] initWithDB:_db sql:sql parameters:parameters];
}

- (IFSqliteResultSet *)executeQuery:(NSString *)sql error:(NSError **)error {
    return [self executeQuery:sql parameters:nil error:error];
}

- (IFSqliteResultSet *)executeQuery:(NSString *)sql parameters:(NSArray *)parameters error:(NSError **)error {
    IFSqlitePreparedStatement *statement = [self prepareStatement:sql parameters:parameters];
    return [statement executeQuery:error];
}

- (void)executeUpdate:(NSString *)sql error:(NSError **)error {
    [self executeUpdate:sql parameters:nil error:error];
}

- (void)executeUpdate:(NSString *)sql parameters:(NSArray *)parameters error:(NSError **)error {
    IFSqlitePreparedStatement *statement = [self prepareStatement:sql parameters:parameters];
    [statement executeUpdate:error];
}

- (void)beginTransaction:(NSError **)error {
    [self executeUpdate:@"BEGIN DEFERRED" error:error];
}

- (void)commitTransaction:(NSError **)error {
    [self executeUpdate:@"COMMIT" error:error];
}

- (void)rollbackTransaction:(NSError **)error {
    [self executeUpdate:@"ROLLBACK" error:error];
}

- (void)close {
    if (_open) {
        int error = sqlite3_close(_db);
        if (error == SQLITE_BUSY) {
            [NSException raise:IFSqliteException
                        format:@"Sqlite database at %@ has unclosed prepared statements", _dbPath];
        }
        if (error != SQLITE_OK) {
            NSLog(@"Error closing database at '%@': %s", _dbPath, sqlite3_errmsg(_db));
        }
        _db = NULL;
        _open = NO;
    }
}

@end

@implementation IFSqliteResultSet

- (id)initWithStatement:(sqlite3_stmt *)statement {
    self = [super init];
    if (self) {
        _statement = statement;
        self.columnCount = sqlite3_column_count(_statement);
    }
    return self;
}

- (BOOL)next {
    int result = sqlite3_step(_statement);
    return (result == SQLITE_ROW);
}

- (NSString *)columnName:(NSInteger)columnIndex {
    if (columnIndex < _columnCount) {
        return [NSString stringWithUTF8String:sqlite3_column_name(_statement, (int)columnIndex)];
    }
    return nil;
}

- (id)columnValue:(NSInteger)columnIndex {
    id value = nil;
    int _columnIdx = (int)columnIndex;
    int columnType = sqlite3_column_type(_statement, _columnIdx);
    switch (columnType) {
    case SQLITE_TEXT:
        value = [NSString stringWithCharacters:sqlite3_column_text16(_statement, _columnIdx)
                                        length:sqlite3_column_bytes16(_statement, _columnIdx) / 2];
        break;
    case SQLITE_INTEGER:
        value = [NSNumber numberWithLong:sqlite3_column_int64(_statement, _columnIdx)];
        break;
    case SQLITE_FLOAT:
        value = [NSNumber numberWithDouble:sqlite3_column_double(_statement, _columnIdx)];
        break;
    case SQLITE_NULL:
        value = [NSNull null];
    }
    return value;
}

- (NSInteger)columnValueAsInteger:(NSInteger)columnIndex {
    id value = [self columnValue:columnIndex];
    return [value isKindOfClass:[NSNumber class]] ? [(NSNumber *)value integerValue] : 0;
}

- (BOOL)isColumnValueNull:(NSInteger)columnIndex {
    return sqlite3_column_type(_statement, (int)columnIndex) == SQLITE_NULL;
}

- (void)close {
    _statement = NULL;
}

@end

@interface IFSqlitePreparedStatement ()

- (void)bindParameters;

@end

@implementation IFSqlitePreparedStatement

- (id)initWithDB:(sqlite3 *)db {
    return [self initWithDB:db sql:nil parameters:nil];
}

- (id)initWithDB:(sqlite3 *)db sql:(NSString *)sql parameters:(NSArray *)parameters {
    self = [super init];
    if (self) {
        _db = db;
        self.sql = sql;
        self.parameters = parameters;
    }
    return self;
}

- (void)setSql:(NSString *)sql {
    _sql = sql;
    [self close];
    if (sql) {
        _parameterCount = 0;
        _compilationError = nil;
        const char *trailing;
        int error = sqlite3_prepare_v2(_db, [sql UTF8String], -1, &_statement, &trailing);
        if (error != SQLITE_OK) {
            NSDictionary *userInfo = @{
                NSLocalizedDescriptionKey:  @"Sqlite statement compilation error",
                @"SQL":                     _sql,
                @"SQLiteError":             [NSString stringWithUTF8String: sqlite3_errmsg(_db)]

            };
            _compilationError = [NSError errorWithDomain:IFSqliteError code:error userInfo:userInfo];
        }
        if (trailing != '\0') {
            NSDictionary *userInfo = @{
                NSLocalizedDescriptionKey:  @"Sqlite statement compilation error",
                @"SQL":                     _sql,
                @"SQLiteError":             @"Multiple statements provided"

            };
            _compilationError = [NSError errorWithDomain:IFSqliteError code:error userInfo:userInfo];
        }
        if (!_compilationError) {
            _parameterCount = sqlite3_bind_parameter_count(_statement);
            [self bindParameters];
        }
    }
}

- (void)setParameters:(NSArray *)parameters {
    _parameters = parameters;
    self.parameterCount = (_parameters) ? [_parameters count] : 0;
    [self bindParameters];
}

- (IFSqliteResultSet *)executeQuery {
    return [self executeQuery:nil];
}

- (IFSqliteResultSet *)executeQuery:(NSError **)error {
    IFSqliteResultSet *rs = nil;
    if (_compilationError) {
        *error = _compilationError;
    }
    else if (_statement != NULL) {
        rs = [[IFSqliteResultSet alloc] initWithStatement:_statement];
    }
    return rs;
}

- (BOOL)executeUpdate {
    return [self executeUpdate:nil];
}

- (BOOL)executeUpdate:(NSError **)error {
    BOOL ok = NO;
    IFSqliteResultSet *rs = [self executeQuery:error];
    if (rs && !error) {
        if ([rs next]) {
            ok = YES;
        }
        [rs close];
    }
    return ok;
}

- (void)close {
    if (_statement != NULL) {
        sqlite3_finalize(_statement);
        _statement = NULL;
    }
}

#pragma mark - private

- (void)bindParameters {
    if (_statement != NULL && _parameters) {
        NSInteger count = MIN([_parameters count], _parameterCount);
        for (int idx = 0; idx < count; idx++) {
            id value = _parameters[idx];
            if (value == nil || value == [NSNull null]) {
                sqlite3_bind_null(_statement, idx);
            }
            else if ([value isKindOfClass: [NSString class]]) {
                sqlite3_bind_text(_statement, idx, [value UTF8String], -1, SQLITE_TRANSIENT);
            }
            else if ([value isKindOfClass: [NSNumber class]]) {
                const char *objcType = [value objCType];
                int64_t number = [value longLongValue];
                if (strcmp(objcType, @encode(float)) == 0 || strcmp(objcType, @encode(double)) == 0) {
                    sqlite3_bind_double(_statement, idx, [value doubleValue]);
                }
                else if (number <= INT32_MAX) {
                    sqlite3_bind_int(_statement, idx, (int)number);
                }
                else {
                    sqlite3_bind_int64(_statement, idx, number);
                }
            }
            else if ([value isKindOfClass: [NSDate class]]) {
                sqlite3_bind_double(_statement, idx, [value timeIntervalSince1970]);
            }
            else {
                // Bind null to non-convertable values.
                sqlite3_bind_null(_statement, idx);
            }
        }
    }
}

@end
