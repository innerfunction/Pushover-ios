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
#import "IFDB.h"

@interface IFDBORM()

- (NSString *)columnNamesForTable:(NSString *)table withPrefix:(NSString *)prefix;
- (NSString *)idColumnForTable:(NSString *)table;

@end

@implementation IFDBORM

- (NSDictionary *)selectKey:(NSString *)key mappings:(NSArray *)mappings {
    NSString *idColumn = [self idColumnForTable:_source];
    NSString *where = [NSString stringWithFormat:@"%@.%@=?", _source, idColumn];
    NSArray *result = [self selectWhere:where values:@[ key ] mappings:mappings];
    return [result count] ? result[0] : nil;
}

- (NSArray *)selectWhere:(NSString *)where values:(NSArray *)values mappings:(NSArray *)mappings {
    // The name of the ID column on the source table.
    NSString *sidColumn = [self idColumnForTable:_source];
    // Generate SQL to describe each join for each relation.
    NSMutableArray *columns = [NSMutableArray new];     // Array of column name lists for source table and all joins.
    NSMutableArray *joins = [NSMutableArray new];       // Array of join SQL.
    NSMutableArray *orderBys = [NSMutableArray new];    // Array of order by column names.
    NSMutableArray *collectionJoins = [NSMutableArray new];  // Array of collection relation names.
    [columns addObject:[self columnNamesForTable:_source withPrefix:_source]];
    for (NSString *mname in [_mappings keyEnumerator]) {
        
        // Skip the mapping if its name isn't in the list of mappings to include.
        if (![mappings containsObject:mname]) {
            continue;
        }
        
        IFDBORMMapping *mapping = _mappings[mname];
        NSString *mtable = mapping.table;

        if ([@"object" isEqualToString:mapping.relation] ||
            [@"property" isEqualToString:mapping.relation] ||
            [@"shared-object" isEqualToString:mapping.relation] ||
            [@"shared-property" isEqualToString:mapping.relation]) {

            [columns addObject:[self columnNamesForTable:mapping.table withPrefix:mname]];
            NSString *midColumn = [self columnWithName:mapping.idColumn orWithTag:@"id" onTable:mtable];
            NSString *join = [NSString stringWithFormat:@"LEFT OUTER JOIN %@ %@ ON %@.%@=%@.%@",
                              mtable,
                              mname,
                              _source,
                              mname,
                              mname,
                              midColumn];
            [joins addObject:join];
        }
        else if ([@"map" isEqualToString:mapping.relation] ||
                 [@"dictionary" isEqualToString:mapping.relation] ||
                 [@"array" isEqualToString:mapping.relation] ||
                 [@"list" isEqualToString:mapping.relation]) {

            [columns addObject:[self columnNamesForTable:mapping.table withPrefix:mname]];
            NSString *oidColumn = [self columnWithName:mapping.owneridColumn orWithTag:@"ownerid" onTable:mtable];
            NSString *join = [NSString stringWithFormat:@"LEFT OUTER JOIN %@ %@ ON %@.%@=%@.%@",
                              mtable,
                              mname,
                              _source,
                              sidColumn,
                              mname,
                              oidColumn];
            [joins addObject:join];
            [collectionJoins addObject:mname];
            // Order the result by the index column; note that this will be empty for map/dictionary sets (i.e.
            // unordered collections), but will have values for array/list items.
            NSString *idxColumn = [self columnWithName:mapping.indexColumn orWithTag:@"index" onTable:mtable];
            [orderBys addObject:[NSString stringWithFormat:@"%@.%@", mname, idxColumn]];
        }
    }
    // Generate select SQL.
    NSString *sql = [NSString stringWithFormat:@"SELECT %@ FROM %@ %@ %@ WHERE %@",
                     [columns componentsJoinedByString:@","],
                     _source,
                     _source,
                     [joins componentsJoinedByString:@""],
                     where];
    
    if ([orderBys count]) {
        sql = [sql stringByAppendingString:@"ORDER BY "];
        sql = [sql stringByAppendingString:[orderBys componentsJoinedByString:@","]];
    }
    
    // Execute the query and generate the result.
    NSArray *rs = [_db performQuery:sql withParams:values];
    NSMutableArray *result = [NSMutableArray new];
    // The fully qualified name of the source object key column in the result set.
    NSString *keyColumn = [NSString stringWithFormat:@"%@.%@", _source, sidColumn];
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
        if (obj == nil || ![obj[sidColumn] isEqualToString:key]) {
            // Convert groups into object + properties.
            obj = groups[_source];
            for (NSString *rname in [groups keyEnumerator]) {
                id value = groups[rname];
                if (![rname isEqualToString:_source]) {
                    // If relation name is for an outer join - i.e. a one to many - then init
                    // the object property as an array of values.
                    if ([collectionJoins containsObject:rname]) {
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
        else for (NSString *rname in collectionJoins) {
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
    for (NSString *mname in [_mappings keyEnumerator]) {
        IFDBORMMapping *mapping = _mappings[mname];
        if ([@"map" isEqualToString:mapping.relation] ||
            [@"dictionary" isEqualToString:mapping.relation] ||
            [@"array" isEqualToString:mapping.relation] ||
            [@"list" isEqualToString:mapping.relation]) {
            
            NSString *oidColumn = [self columnWithName:mapping.owneridColumn orWithTag:@"ownerid" onTable:mapping.table];
            sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@=?", mapping.table, oidColumn];
            ok &= [_db performUpdate:sql withParams:@[ key ]];
        }
    }
    // The name of the ID column on the source table.
    NSString *sidColumn = [self idColumnForTable:_source];
    // TODO Support deletion of many-one relations by deleting records from relation table where no foreign key value in source table.
    sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@=?", _source, sidColumn];
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

- (NSString *)idColumnForTable:(NSString *)table {
    return [_db getColumnWithTag:@"id" fromTable:table];
}

- (NSString *)columnWithName:(NSString *)name orWithTag:(NSString *)tag onTable:(NSString *)table {
    if (!name) {
        name = [_db getColumnWithTag:tag fromTable:table];
        if (!name) {
            name = tag;
        }
    }
    return name;
}

#pragma mark - IFIOCTypeInspectable

- (__unsafe_unretained Class)memberClassForCollection:(NSString *)propertyName {
    if ([@"mappings" isEqualToString:propertyName]) {
        return [IFDBORMMapping class];
    }
    return nil;
}

#pragma mark - IFIOCObjectAware


/**
 * Notify a value that it is about to be injected into an object using the specified property.
 * @param object        The object which the current object is about to be attached to.
 * @param propertyName  The name of the property on _object_ that the current object is being
 * attached to.
 */
- (void)notifyIOCObject:(id)object propertyName:(NSString *)propertyName {
    if ([object isKindOfClass:[IFDB class]]) {
        self.db = object;
    }
}

@end


@implementation IFDBORMMapping

@end
