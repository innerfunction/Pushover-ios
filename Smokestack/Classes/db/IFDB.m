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

#import "Smokestack.h"
#import "IFDB.h"
#import "IFLogger.h"
#import "NSDictionary+IFValues.h"
#import "NSDictionary+IF.h"
#import "NSArray+IF.h"

static IFLogger *Logger;

@interface IFDB ()

/** Read a record from the specified table. */
- (NSDictionary *)readRecordWithID:(NSString *)identifier fromTable:(NSString *)table db:(IFSqliteDB *)db;
/** Read a record from the specified table. */
- (NSDictionary *)readRecordWithID:(NSString *)identifier idColumn:(NSString *)idColumn fromTable:(NSString *)table db:(IFSqliteDB *)db;
/** Read a single row from a query result set. */
- (NSDictionary *)readRowFromResultSet:(IFSqliteResultSet *)rs;
/** Update multiple record with the specified values in a table. */
- (BOOL)updateValues:(NSDictionary *)values inTable:(NSString *)table db:(IFSqliteDB *)db;
/** Update multiple record with the specified values in a table. */
- (BOOL)updateValues:(NSDictionary *)values idColumn:(NSString *)idColumn inTable:(NSString *)table db:(IFSqliteDB *)db;
/** Delete records with the specified IDs from the a table. */
- (BOOL)deleteIDs:(NSArray *)identifiers idColumn:(NSString *)idColumn fromTable:(NSString *)table;

@end

@interface IFDB (IFDBHelperDelegate)

- (NSString *)getCreateTableSQLForTable:(NSString *)tableName schema:(NSDictionary *)tableSchema;
- (NSArray *)getAlterTableSQLForTable:(NSString *)tableName schema:(NSDictionary *)tableSchema from:(NSInteger)oldVersion to:(NSInteger)newVersion;
- (void)dbInitialize:(IFSqliteDB *)db error:(NSError **)error;
- (void)addInitialDataForTable:(NSString *)tableName schema:(NSDictionary *)tableSchema;

@end

@implementation IFDB

+ (void)initialize {
    Logger = [[IFLogger alloc] initWithTag:@"IFDB"];
}

- (id)init {
    self = [super init];
    if (self) {
        self.name = @"semo";
        self.version = @1;
        self.tables = @{};
        self.resetDatabase = NO;
        _initialData = [NSMutableDictionary new];
    }
    return self;
}

- (id)initWithDB:(IFDB *)db {
    self = [super init];
    self.name = db.name;
    self.version = db.version;
    self.tables = db.tables;
    self.orm = db.orm;
    return self;
}

#pragma mark - IFService

- (void)startService {
    _dbHelper = [[IFDBHelper alloc] initWithName:_name version:[_version intValue]];
    _dbHelper.delegate = self;
    _dbHelper.initialCopyPath = _initialCopyPath;
    if (_resetDatabase) {
        [Logger warn:@"Resetting database %@", _name];
        [_dbHelper deleteDatabase];
    }
    [_dbHelper getDatabase];
}

#pragma mark - properties

- (void)setTables:(NSDictionary *)tables {
    _tables = tables;
    // Build lookup of table column tags.
    NSMutableDictionary *taggedTableColumns = [NSMutableDictionary new];
    // Build lookup of table column names.
    NSMutableDictionary *tableColumnNames = [NSMutableDictionary new];
    for (id tableName in [tables allKeys]) {
        NSDictionary *tableSchema = tables[tableName];
        NSMutableDictionary *columnTags = [NSMutableDictionary new];
        NSMutableSet *columnNames = [NSMutableSet new];
        NSDictionary *columns = tableSchema[@"columns"];
        for (id columnName in [columns allKeys]) {
            NSDictionary *columnSchema = columns[columnName];
            NSString *tag = [columnSchema getValueAsString:@"tag"];
            if (tag) {
                columnTags[tag] = columnName;
            }
            [columnNames addObject:columnName];
        }
        taggedTableColumns[tableName] = columnTags;
        tableColumnNames[tableName] = columnNames;
    }
    _taggedTableColumns = taggedTableColumns;
    _tableColumnNames = tableColumnNames;
}

#pragma mark - Public/private methods

- (BOOL)beginTransaction {
    BOOL ok = YES;
    NSError *error = nil;
    IFSqliteDB *db = [_dbHelper getDatabase];
    [db beginTransaction:&error];
    if (error) {
        [Logger error:@"Transaction open failed %@", error];
        ok = NO;
    }
    return ok;
}

- (BOOL)commitTransaction {
    BOOL ok = YES;
    NSError *error = nil;
    IFSqliteDB *db = [_dbHelper getDatabase];
    [db commitTransaction:&error];
    if (error) {
        [Logger error:@"Transaction commit failed %@", error];
        ok = NO;
    }
    return ok;
}

- (BOOL)rollbackTransaction {
    BOOL ok = YES;
    NSError *error = nil;
    IFSqliteDB *db = [_dbHelper getDatabase];
    [db rollbackTransaction:&error];
    if (error) {
        [Logger error:@"Transaction rollback failed %@", error];
        ok = NO;
    }
    return ok;
}

- (NSString *)getColumnWithTag:(NSString *)tag fromTable:(NSString *)table {
    NSDictionary *columns = _taggedTableColumns[table];
    return columns[tag];
}

- (NSDictionary *)readRecordWithID:(NSString *)identifier fromTable:(NSString *)table {
    IFSqliteDB *db = [_dbHelper getDatabase];
    return [self readRecordWithID:identifier fromTable:table db:db];
}

- (NSDictionary *)readRecordWithID:(NSString *)identifier fromTable:(NSString *)table db:(IFSqliteDB *)db {
    NSDictionary *result = nil;
    NSString *idColumn = [self getColumnWithTag:@"id" fromTable:table];
    if (idColumn) {
        result = [self readRecordWithID:identifier idColumn:idColumn fromTable:table db:db];
    }
    else {
        [Logger warn:@"No ID column found for table %@", table];
    }
    return result;
}

- (NSDictionary *)readRecordWithID:(NSString *)identifier idColumn:(NSString *)idColumn fromTable:(NSString *)table db:(IFSqliteDB *)db {
    NSDictionary *result = nil;
    if (identifier) {
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@=?", table, idColumn];
        NSArray *params = @[ identifier ];
        NSError *error = nil;
        IFSqliteResultSet *rs = [db executeQuery:sql parameters:params error:&error];
        if (error) {
            [Logger error:@"Error reading record: %@", [error localizedDescription]];
        }
        else if ([rs next]) {
            result = [self readRowFromResultSet:rs];
        }
        [rs close];
    }
    else {
        [Logger warn:@"No identifier passed to readRecordWithID:"];
    }
    return result;
}

- (NSArray *)performQuery:(NSString *)sql withParams:(NSArray *)params {
    NSMutableArray *result = [NSMutableArray new];
    IFSqliteDB *db = [_dbHelper getDatabase];
    NSError *error = nil;
    IFSqliteResultSet *rs = [db executeQuery:sql parameters:params error:&error];
    if (error) {
        [Logger error:@"Error performing query: %@", [error localizedDescription]];
    }
    else while ([rs next]) {
        [result addObject:[self readRowFromResultSet:rs]];
    }
    [rs close];
    return result;
}

- (BOOL)performUpdate:(NSString *)sql withParams:(NSArray *)params {
    IFSqliteDB *db = [_dbHelper getDatabase];
    NSError *error = nil;
    [db executeUpdate:sql parameters:params error:&error];
    if (!error) {
        return YES;
    }
    [Logger error:@"Executing update: %@", [error localizedDescription]];
    return NO;
}

- (NSInteger)countInTable:(NSString *)table where:(NSString *)where {
    return [self countInTable:table where:where withParams:@[]];
}

- (NSInteger)countInTable:(NSString *)table where:(NSString *)where withParams:(NSArray *)params {
    NSInteger count = 0;
    NSString *sql = [NSString stringWithFormat:@"SELECT count(*) AS count FROM %@ WHERE %@", table, where];
    NSArray *result = [self performQuery:sql withParams:params];
    if ([result count] > 0) {
        NSDictionary *record = [result objectAtIndex:0];
        count = [(NSNumber *)[record objectForKey:@"count"] integerValue];
    }
    return count;
}

- (NSDictionary *)readRowFromResultSet:(IFSqliteResultSet *)rs {
    NSMutableDictionary *result = [NSMutableDictionary new];
    NSInteger colCount = rs.columnCount;
    for (NSInteger idx = 0; idx < colCount; idx++) {
        if (![rs isColumnValueNull:idx]) {
            NSString *name = [rs columnName:idx];
            id value = [rs columnValue:idx];
            [result setObject:value forKey:name];
        }
    }
    return result;
}

- (BOOL)insertValueList:(NSArray *)valueList intoTable:(NSString *)table {
    IFSqliteDB *db = [_dbHelper getDatabase];
    BOOL result = YES;
    [self willChangeValueForKey:table];
    for (NSDictionary *values in valueList) {
        result &= [self insertValues:values intoTable:table db:db];
    }
    [self didChangeValueForKey:table];
    return result;
}

- (BOOL)insertValues:(NSDictionary *)values intoTable:(NSString *)table {
    IFSqliteDB *db = [_dbHelper getDatabase];
    [self willChangeValueForKey:table];
    BOOL result = [self insertValues:values intoTable:table db:db];
    [self didChangeValueForKey:table];
    return result;
}

- (BOOL)insertValues:(NSDictionary *)values intoTable:(NSString *)table db:(IFSqliteDB *)db {
    BOOL ok = YES;
    values = [self filterValues:values forTable:table];
    NSArray *keys = [NSArray arrayWithDictionaryKeys:values];
    if ([keys count] > 0) {
        NSString *fields = [keys componentsJoinedByString:@","];
        NSString *placeholders = [[NSArray arrayWithItem:@"?" repeated:[keys count]] componentsJoinedByString:@","];
        NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)", table, fields, placeholders];
        NSArray *params = [NSArray arrayWithDictionaryValues:values forKeys:keys];
        NSError *error = nil;
        [db executeUpdate:sql parameters:params error:&error];
        if (error) {
            [Logger error:@"Error inserting values: %@", [error localizedDescription]];
            ok = NO;
        }
    }
    return ok;
}

- (BOOL)upsertValueList:(NSArray *)valueList intoTable:(NSString *)table {
    IFSqliteDB *db = [_dbHelper getDatabase];
    BOOL result = YES;
    [self willChangeValueForKey:table];
    for (NSDictionary *values in valueList) {
        result &= [self upsertValues:values intoTable:table db:db];
    }
    [self didChangeValueForKey:table];
    return result;
}

- (BOOL)upsertValues:(NSDictionary *)values intoTable:(NSString *)table {
    IFSqliteDB *db = [_dbHelper getDatabase];
    [self willChangeValueForKey:table];
    BOOL result = [self upsertValues:values intoTable:table db:db];
    [self didChangeValueForKey:table];
    return result;
}

- (BOOL)upsertValues:(NSDictionary *)values intoTable:(NSString *)table db:(IFSqliteDB *)db {
    BOOL update = NO;
    NSString *idColumn = [self getColumnWithTag:@"id" fromTable:table];
    if (idColumn) {
        id idValue = [values objectForKey:idColumn];
        if (idValue) {
            NSString *where = [NSString stringWithFormat:@"%@=?", idColumn];
            NSArray *params = @[ idValue ];
            NSInteger count = [self countInTable:table where:where withParams:params];
            update = (count == 1);
        }
    }
    if (update) {
        return [self updateValues:values idColumn:idColumn inTable:table db:db];
    }
    else {
        return [self insertValues:values intoTable:table db:db];
    }
}

- (BOOL)updateValues:(NSDictionary *)values inTable:(NSString *)table {
    IFSqliteDB *db = [_dbHelper getDatabase];
    [self willChangeValueForKey:table];
    BOOL result = [self updateValues:values inTable:table db:db];
    if (result) {
        [self didChangeValueForKey:table];
    }
    else {
        NSString *idColumn = [self getColumnWithTag:@"id" fromTable:table];
        id identifier = [values valueForKey:idColumn];
        [Logger warn:@"Update failed %@ %@", table, identifier];
    }
    return result;
}

- (BOOL)updateValues:(NSDictionary *)values inTable:(NSString *)table db:(IFSqliteDB *)db {
    BOOL result = NO;
    NSString *idColumn = [self getColumnWithTag:@"id" fromTable:table];
    if (idColumn) {
        result = [self updateValues:values idColumn:idColumn inTable:table db:db];
    }
    else {
        [Logger warn:@"No ID column found for table %@", table];
    }
    return result;
}

- (BOOL)updateValues:(NSDictionary *)values idColumn:(NSString *)idColumn inTable:(NSString *)table db:(IFSqliteDB *)db {
    values = [self filterValues:values forTable:table];
    NSArray *keys = [NSArray arrayWithDictionaryKeys:values];
    NSMutableArray *fields = [[NSMutableArray alloc] initWithCapacity:[keys count]];
    NSMutableArray *params = [[NSMutableArray alloc] initWithCapacity:[keys count] + 1];
    for (id key in keys) {
        if ([idColumn isEqualToString:key]) {
            continue; // Don't update the ID column.
        }
        [fields addObject:[NSString stringWithFormat:@"%@=?", key]];
        [params addObject:[values valueForKey:key]];
    }
    id identifier = [values valueForKey:idColumn];
    [params addObject:identifier];
    NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE %@=?", table, [fields componentsJoinedByString:@","], idColumn ];
    NSError *error = nil;
    BOOL ok = YES;
    [db executeUpdate:sql parameters:params error:&error];
    if (error) {
        [Logger error:@"Error updating values: %@", [error localizedDescription]];
        ok = NO;
    }
    return ok;
}

- (BOOL)mergeValueList:(NSArray *)valueList intoTable:(NSString *)table {
    BOOL result = YES;
    NSString *idColumn = [self getColumnWithTag:@"id" fromTable:table];
    if (idColumn) {
        IFSqliteDB *db = [_dbHelper getDatabase];
        [self willChangeValueForKey:table];
        for (NSDictionary *values in valueList) {
            id identifier = [values valueForKey:idColumn];
            NSDictionary *record = [self readRecordWithID:identifier fromTable:table];
            if (record) {
                record = [record extendWith:values];
                result &= [self updateValues:record idColumn:idColumn inTable:table db:db];
            }
            else {
                result &= [self insertValues:values intoTable:table db:db];
            }
        }
        [self didChangeValueForKey:table];
    }
    else {
        [Logger warn:@"No ID column found for table", table];
    }
    return result;
}

- (BOOL)deleteIDs:(NSArray *)identifiers fromTable:(NSString *)table {
    BOOL result = NO;
    NSString *idColumn = [self getColumnWithTag:@"id" fromTable:table];
    if (idColumn) {
        result = [self deleteIDs:identifiers idColumn:idColumn fromTable:table];
    }
    else {
        [Logger warn:@"No ID column found for table %@", table];
    }
    return result;
}

- (BOOL)deleteIDs:(NSArray *)identifiers idColumn:(NSString *)idColumn fromTable:(NSString *)table {
    BOOL result = YES;
    if ([identifiers count]) {
        IFSqliteDB *db = [_dbHelper getDatabase];
        [self willChangeValueForKey:table];
        NSArray *params = [NSArray arrayWithItem:@"?" repeated:[identifiers count]];
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@ IN (%@)", table, idColumn, [params componentsJoinedByString:@","]];
        NSError *error = nil;
        [db executeUpdate:sql parameters:params error:&error];
        if (error) {
            [Logger error:@"Error deleting records: %@", [error localizedDescription]];
            result = NO;
        }
        [self didChangeValueForKey:table];
    }
    return result;
}

- (BOOL)deleteID:(NSString *)recordID fromTable:(NSString *)table {
    BOOL result = YES;
    NSString *idColumn = [self getColumnWithTag:@"id" fromTable:table];
    if (idColumn) {
        IFSqliteDB *db = [_dbHelper getDatabase];
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@=?", table, idColumn];
        NSArray *params = @[ recordID ];
        NSError *error = nil;
        [db executeUpdate:sql parameters:params error:&error];
        if (error) {
            [Logger error:@"Error deleting records: %@", [error localizedDescription]];
            result = NO;
        }
    }
    return result;
}

- (BOOL)deleteFromTable:(NSString *)table where:(NSString *)where {
    IFSqliteDB *db = [_dbHelper getDatabase];
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@", table, where];
    BOOL ok = YES;
    NSError *error = nil;
    [db executeUpdate:sql parameters:nil error:&error];
    if (error) {
        [Logger error:@"Error deleting from table: %@", [error localizedDescription]];
        ok = NO;
    }
    return ok;
}

- (NSDictionary *)filterValues:(NSDictionary *)values forTable:(NSString *)table {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    NSSet *columnNames = [_tableColumnNames objectForKey:table];
    if (columnNames) {
        for (id name in [values keyEnumerator]) {
            if ([columnNames containsObject:name]) {
                [result setObject:[values objectForKey:name] forKey:name];
            }
        }
    }
    return result;
}

- (IFDB *)newInstance {
    IFDB *newDB = [[IFDB alloc] initWithDB:self];
    [newDB startService];
    return newDB;
}

#pragma mark - IFDBHelperDelegate

- (void)onCreate:(IFSqliteDB *)db error:(NSError *__autoreleasing *)error {
    for (NSString *tableName in [_tables allKeys]) {
        NSDictionary *tableSchema = [_tables objectForKey:tableName];
        NSString *sql = [self getCreateTableSQLForTable:tableName schema:tableSchema];
        [db executeUpdate:sql parameters:nil error:error];
        if (*error) {
            return;
        }
        [self addInitialDataForTable:tableName schema:tableSchema];
    }
    [self dbInitialize:db error:error];
}

- (void)onUpgrade:(IFSqliteDB *)database from:(NSInteger)oldVersion to:(NSInteger)newVersion error:(NSError *__autoreleasing *)error {
    [Logger info:@"Migrating DB from version %d to version %d", oldVersion, newVersion];
    NSNumber *_newVersion = [NSNumber numberWithInteger:newVersion];
    for (NSString *tableName in [_tables allKeys]) {
        NSDictionary *tableSchema = [_tables objectForKey:tableName];
        NSInteger since = [[tableSchema getValueAsNumber:@"since" defaultValue:@0] integerValue];
        NSInteger until = [[tableSchema getValueAsNumber:@"until" defaultValue:_newVersion] integerValue];
        NSArray *sqls = nil;
        if (since < (NSInteger)oldVersion) {
            // Table exists since before the current DB version, so should exist in the current DB.
            if (until < (NSInteger)newVersion) {
                // Table not required in DB version being migrated to, so drop from database.
                NSString *sql = [NSString stringWithFormat:@"DROP TABLE %@ IF EXISTS", tableName];
                sqls = [NSArray arrayWithObject:sql];
            }
            else {
                // Modify table.
                sqls = [self getAlterTableSQLForTable:tableName schema:tableSchema from:oldVersion to:newVersion];
            }
        }
        else {
            // => since > oldVersion
            // Table shouldn't exist in the current database.
            if (until < newVersion) {
                // Table not required in version being migrated to, so no action required.
                continue;
            }
            else {
                // Create table.
                sqls = [NSArray arrayWithObject:[self getCreateTableSQLForTable:tableName schema:tableSchema]];
                [self addInitialDataForTable:tableName schema:tableSchema];
            }
        }
        for (NSString *sql in sqls) {
            [database executeUpdate:sql parameters:nil error:error];
            if (*error) {
                return;
            }
        }
    }
    [self dbInitialize:database error:error];
}

#pragma mark - IFDB (IFDBHelperDelegate)

- (void)dbInitialize:(IFSqliteDB *)db error:(NSError *__autoreleasing *)error {
    [Logger info:@"Initializing database..."];
    for (NSString *tableName in [_initialData allKeys]) {
        NSArray *data = [_initialData objectForKey:tableName];
        for (NSDictionary *values in data) {
            [self insertValues:values intoTable:tableName db:db];
        }
        NSString *sql = [NSString stringWithFormat:@"select count() from %@", tableName];
        IFSqliteResultSet *rs = [db executeQuery:sql error:error];
        if (*error) {
            return;
        }
        if ([rs next]) {
            NSInteger count = [rs columnValueAsInteger:0];
            [Logger info:@"Initializing %@, inserted %d rows", tableName, count];
        }
        [rs close];
    }
    // Remove initial data from memory.
    _initialData = nil;
}

- (void)addInitialDataForTable:(NSString *)tableName schema:(NSDictionary *)tableSchema {
    id data = tableSchema[@"data"];
    if ([data isKindOfClass:[NSArray class]]) {
        [_initialData setObject:data forKey:tableName];
    }
}

- (NSString *)getCreateTableSQLForTable:(NSString *)tableName schema:(NSDictionary *)tableSchema {
    NSMutableString *cols = [[NSMutableString alloc] init];
    NSDictionary *columns = [tableSchema valueForKey:@"columns"];
    for (NSString *colName in [columns allKeys]) {
        NSDictionary *colSchema = [columns objectForKey:colName];
        if ([cols length] > 0) {
            [cols appendString:@","];
        }
        [cols appendString:colName];
        [cols appendString:@" "];
        [cols appendString:[colSchema getValueAsString:@"type"]];
    }
    NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@)", tableName, cols ];
    return sql;
}

- (NSArray *)getAlterTableSQLForTable:(NSString *)tableName schema:(NSDictionary *)tableSchema from:(NSInteger)oldVersion to:(NSInteger)newVersion {
    NSNumber *_newVersion = [NSNumber numberWithInteger:newVersion];
    NSMutableArray *sqls = [[NSMutableArray alloc] init];
    NSDictionary *columns = [tableSchema valueForKey:@"columns"];
    for (NSString *colName in [columns allKeys]) {
        NSDictionary *colSchema = [columns objectForKey:colName];
        NSInteger since = [[colSchema getValueAsNumber:@"since" defaultValue:@0] integerValue];
        NSInteger until = [[colSchema getValueAsNumber:@"until" defaultValue:_newVersion] integerValue];
        // If a column has been added since the current db version, and not disabled before the
        // version being migrated to, then alter the table schema to include the table.
        if (since > oldVersion && !(until < newVersion)) {
            NSString *type = [colSchema getValueAsString:@"type"];
            NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ %@", tableName, colName, type ];
            [sqls addObject:sql];
        }
    }
    return sqls;
}

@end
