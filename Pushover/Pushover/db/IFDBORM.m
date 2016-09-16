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
//  Created by Julian Goacher on 15/09/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFDBORM.h"

@interface IFDBORM()

- (NSString *)columnNamesForTable:(NSString *)table withPrefix:(NSString *)prefix;

@end

@implementation IFDBORM

- (NSDictionary *)selectKey:(NSString *)key {
    NSString *where = [NSString stringWithFormat:@"%@.%@=?", _source.name, _source.key];
    NSArray *result = [self selectWhere:where values:@[ key ]];
    return [result count] ? result[0] : nil;
}

- (NSArray *)selectWhere:(NSString *)where values:(NSArray *)values {
    // Generate SQL to describe each join for each relation.
    NSMutableArray *columns = [NSMutableArray new];     // Array of column name lists for source table and all joins.
    NSMutableArray *joins = [NSMutableArray new];       // Array of join SQL.
    NSMutableArray *outerJoins = [NSMutableArray new];  // Array of outer join relation names.
    [columns addObject:[self columnNamesForTable:_source.name withPrefix:_source.name]];
    for (NSString *rname in [_relations keyEnumerator]) {
        IFDBORMRelation *relation = _relations[rname];
        if ([@"one-one" isEqualToString:relation.relation] || [@"many-one" isEqualToString:relation.relation]) {
            [columns addObject:[self columnNamesForTable:relation.table withPrefix:rname]];
            NSString *join = [NSString stringWithFormat:@"LEFT JOIN %@ %@ ON %@.%@=%@.%@",
                              relation.table,
                              rname,
                              _source.name,
                              rname,
                              rname,
                              relation.foreignKey];
            [joins addObject:join];
        }
        else if ([@"one-many" isEqualToString:relation.relation]) {
            [columns addObject:[self columnNamesForTable:relation.table withPrefix:rname]];
            NSString *join = [NSString stringWithFormat:@"LEFT OUTER JOIN %@ %@ ON %@.%@=%@.%@",
                              relation.table,
                              rname,
                              _source.name,
                              _source.key,
                              rname,
                              relation.key];
            [joins addObject:join];
            [outerJoins addObject:rname];
        }
    }
    // Generate select SQL.
    NSString *sql = [NSString stringWithFormat:@"SELECT %@ FROM %@ %@ %@ WHERE %@",
                     [columns componentsJoinedByString:@","],
                     _source.name,
                     _source.name,
                     [joins componentsJoinedByString:@""],
                     where];
    // Execute the query and generate the result.
    NSArray *rs = [_db performQuery:sql withParams:values];
    NSMutableArray *result = [NSMutableArray new];
    // The fully qualified name of the source object key column in the result set.
    NSString *keyColumn = [NSString stringWithFormat:@"%@.%@", _source.name, _source.key];
    // The object currently being processed.
    NSMutableDictionary *obj = nil;
    for (NSDictionary *row in rs) {
        id key = row[keyColumn]; // Read the key value from the current result set row.
        // Convert flat result set row into groups of properties sharing the same column name prefix.
        NSMutableDictionary *groups = [NSMutableDictionary new];
        for (NSString *cname in [row keyEnumerator]) {
            id value = row[cname];
            // Only map columns with values.
            if (value != nil) {
                // Split column name into prefix/suffix parts.
                NSRange range = [cname rangeOfString:@"."];
                NSString *prefix = [cname substringToIndex:range.location];
                NSString *suffix = [cname substringFromIndex:range.location + 1];
                // Ensure that we have a dictionary for the prefix group.
                NSMutableDictionary *group = groups[prefix];
                if (!group) {
                    group = [NSMutableDictionary new];
                    groups[prefix] = group;
                }
                // Map the value to the suffix name within the group.
                group[suffix] = value;
            }
        }
        // Check if dealing with a new object.
        if (obj == nil || ![obj[_source.key] isEqualToString:key]) {
            // Convert groups into object + properties.
            obj = groups[_source.name];
            for (NSString *rname in [groups keyEnumerator]) {
                id value = groups[rname];
                if (![rname isEqualToString:_source.name]) {
                    // If relation name is for an outer join - i.e. a one to many - then init
                    // the object property as an array of values.
                    if ([outerJoins containsObject:rname]) {
                        obj[rname] = [[NSMutableArray alloc] initWithObjects:value, nil];
                    }
                    else {
                        // Else map the object property name to the value.
                        obj[rname] = rname;
                    }
                }
            }
            [result addObject:obj];
        }
        else for (NSString *rname in outerJoins) {
            // Processing subsequent rows for the same object - indicates outer join results.
            NSMutableArray *values = obj[rname];
            if (!values) {
                // Ensure that we have a list to hold the additional values.
                values = [NSMutableArray new];
                obj[rname] = values;
            }
            // If we have a value for the current relation group then add to the property value list.
            id value = groups[rname];
            if (value) {
                [values addObject:value];
            }
        }
    }
    return result;
}

- (BOOL)deleteKey:(NSString *)key {
    BOOL ok = YES;
    [_db beginTransaction];
    NSString *sql;
    for (NSString *rname in [_relations keyEnumerator]) {
        IFDBORMRelation *relation = _relations[rname];
        if ([@"one-one" isEqualToString:relation.relation] || [@"one-many" isEqualToString:relation.relation]) {
            sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@=?", relation.table, relation.foreignKey];
            ok &= [_db performUpdate:sql withParams:@[ key ]];
        }
    }
    // TODO Support deletion of many-one relations by deleting records from relation table where no foreign key value in source table.
    sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@=?", _source.name, _source.key];
    ok &= [_db performUpdate:sql withParams:@[ key ]];
    if (ok) {
        [_db commitTransaction];
    }
    else {
        [_db rollbackTransaction];
    }
    return ok;
}

#pragma mark - Private methods and functions

- (NSString *)columnNamesForTable:(NSString *)table withPrefix:(NSString *)prefix {
    NSString *columnNames = nil;
    NSDictionary *tableDef = _db.tables[table];
    if (tableDef) {
        NSDictionary *columnDefs = tableDef[@"columns"];
        NSMutableArray *columns = [NSMutableArray new];
        for (NSString *name in [columnDefs keyEnumerator]) {
            [columns addObject:[NSString stringWithFormat:@"%@.%@", prefix, name]];
        }
        columnNames = [columns componentsJoinedByString:@","];
    }
    return columnNames;
}

#pragma mark - IFIOCTypeInspectable

- (__unsafe_unretained Class)memberClassForCollection:(NSString *)propertyName {
    if ([@"relations" isEqualToString:propertyName]) {
        return [IFDBORMRelation class];
    }
    return nil;
}

@end
