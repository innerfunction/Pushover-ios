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

#import <Foundation/Foundation.h>
#import "IFIOCTypeInspectable.h"
#import "IFIOCObjectAware.h"

@class IFDB;

/**
 * A class providing simple object-relational mapping capability.
 * The class maps objects, represented as dictionary instances, to a source table in
 * a local SQLite database. Compound properties of each object can be defined as joins
 * between the source table and other related tables, with 1:1, 1:Many and Many:1 relations
 * supported.
 *
 * TODO Options to control which relations are included, according to fileset category.
 */
@interface IFDBORM : NSObject <IFIOCTypeInspectable, IFIOCObjectAware>

/// The name of the relation source table.
@property (nonatomic, strong) NSString *source;
/// A dictionary of relation mappings from the source table, keyed by name.
@property (nonatomic, strong) NSDictionary *mappings;
/// The database.
@property (nonatomic, weak) IFDB *db;

/**
 * Select the object with the specified key value.
 * Returns the object record from the source table, with all related properties
 * named in the mappings argument joined from the related tables.
 */
- (NSDictionary *)selectKey:(NSString *)key mappings:(NSArray *)mappings;
/**
 * Select the objects matching the specified where condition.
 * Returns an array of object records from the source table, with all related properties
 * named in the mappings argument joined from the related tables.
 */
- (NSArray *)selectWhere:(NSString *)where values:(NSArray *)values mappings:(NSArray *)mappings;
/**
 * Delete the object with the specified key value.
 * Deletes any related records unique to the deleted object.
 */
- (BOOL)deleteKey:(NSString *)key;
/// Return a column name, or if not specified, the name of the column on a table with the specified tag.
- (NSString *)columnWithName:(NSString *)name orWithTag:(NSString *)tag onTable:(NSString *)table;

@end

/// A class describing a relation mapping between a source and property value table.
@interface IFDBORMMapping : NSObject

/**
 * The relation type; values are 'object'/'property', 'shared-object'/'shared-property',
 * 'map'/'dictionary', 'array'/'list'.
 */
@property (nonatomic, strong) NSString *relation;
/// The name of the table holding the related values.
@property (nonatomic, strong) NSString *table;
/// The name of the ID column on the joined table.
@property (nonatomic, strong) NSString *idColumn;
/// The name of the key column for map/dictionary items.
@property (nonatomic, strong) NSString *keyColumn;
/// The name of the index column for list/array items.
@property (nonatomic, strong) NSString *indexColumn;
/// The name of the owner ID column for map/dictionary/array/list items.
@property (nonatomic, strong) NSString *owneridColumn;
/// The name of the version column.
@property (nonatomic, strong) NSString *verColumn;

/// Test whether the mapping represents a (non-shared) object or property mapping.
- (BOOL)isObjectMapping;
/// Test whether the mapping represents a shared object or property mapping.
- (BOOL)isSharedObjectMapping;

@end
