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
#import "IFDB.h"
#import "IFIOCTypeInspectable.h"

@class IFDBORMSource;

/// A class describing multiple relations between DB tables.
@interface IFDBORM : NSObject <IFIOCTypeInspectable>

/// The relation source table.
@property (nonatomic, strong) IFDBORMSource *source;
/// A dictionary of relations from the source table, keyed by name.
@property (nonatomic, strong) NSDictionary *relations;
/// The database.
@property (nonatomic, strong) IFDB *db;

@end

/**
 * A class providing simple object-relational mapping capability.
 * The class maps objects, represented as dictionary instances, to a source table in
 * a local SQLite database. Compound properties of each object can be defined as joins
 * between the source table and other related tables, with 1:1, 1:Many and Many:1 relations
 * supported.
 */
@interface IFDBORMSource : NSObject

/// The name of the source table.
@property (nonatomic, strong) NSString *name;
/// The name of the key column.
@property (nonatomic, strong) NSString *key;

/**
 * Select the object with the specified key value.
 * Returns the object record from the source table, with all related properties
 * joined from the related tables.
 */
- (NSDictionary *)selectKey:(NSString *)key;
/**
 * Select the objects matching the specified where condition.
 * Returns an array of object records from the source table, with all related properties
 * joined from the related tables.
 */
- (NSArray *)selectWhere:(NSString *)where values:(NSArray *)values;
/**
 * Delete the object with the specified key value.
 * Deletes any related records unique to the deleted object.
 */
- (BOOL)deleteKey:(NSString *)key;

@end

/// A class describing a relation between a source and join table.
@interface IFDBORMRelation : NSObject

/// The relation type; values are 'one-one', 'one-many', 'many-one'.
@property (nonatomic, strong) NSString *relation;
/// The name of the table being joined to.
@property (nonatomic, strong) NSString *table;
/// The name of the key column on the joined table.
@property (nonatomic, strong) NSString *key;
/// The value to use for the key column, expressed as a value template.
@property (nonatomic, strong) NSString *keyValue;
/// The name of the foreign key on the source table.
@property (nonatomic, strong) NSString *foreignKey;

@end
