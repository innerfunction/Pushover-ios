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
//  Created by Julian Goacher on 26/09/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFCMSFileDB.h"
#import "IFCMSFileset.h"

@implementation IFCMSFileDB

- (BOOL)pruneRelatedValues {
    BOOL ok = YES;
    // Read column names on source table.
    NSString *source = self.orm.source;
    NSString *idColumn = [self getColumnWithTag:@"id" fromTable:source];
    NSString *verColumn = [self getColumnWithTag:@"version" fromTable:source];
    if (verColumn) {
        // Iterate over mappings.
        NSDictionary *mappings = self.orm.mappings;
        for (NSString *mappingName in [mappings keyEnumerator]) {
            // Read column names on mapped table.
            IFDBORMMapping *mapping = mappings[mappingName];
            NSString *midColumn = [self getColumnWithTag:@"id" fromTable:mapping.table];
            NSString *mverColumn = [self.orm columnWithName:mapping.verColumn orWithTag:@"version" onTable:mapping.table];
            if (midColumn && mverColumn) {
                // Construct where clause of delete query - select all records on mapped table where
                // the version value doesn't match the version value on the source table.
                NSString *where = [NSString stringWithFormat:@"%@ IN (SELECT %@.%@ FROM %@ OUTER JOIN %@ ON %@.%@ = %@.%@ AND %@.%@ != %@.%@)",
                    midColumn,
                    mapping.table, midColumn,
                    source, mapping.table,
                    source, idColumn, mapping.table, midColumn,
                    source, verColumn, mapping.table, mverColumn ];
                // Execute the delete and continue if ok.
                ok = [self deleteFromTable:mapping.table where:where];
                if (!ok) {
                    break;
                }
            }
        }
    }
    return ok;
}

#pragma mark - IFIOCTypeInspectable

- (__unsafe_unretained Class)memberClassForCollection:(NSString *)propertyName {
    if ([@"filesets" isEqualToString:propertyName]) {
        return [IFCMSFileset class];
    }
    return nil;
}

@end
