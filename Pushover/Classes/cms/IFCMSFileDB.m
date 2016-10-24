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

- (id)initWithContentAuthority:(IFCMSContentAuthority *)authority {
    self = [super init];
    if (self) {
        _authority = authority;
        _filesTable = @"files";
    }
    return self;
}

- (id)initWithCMSFileDB:(IFCMSFileDB *)cmsFileDB {
    self = [super initWithDB:cmsFileDB];
    if (self) {
        _authority = cmsFileDB.authority;
        _filesTable = cmsFileDB.filesTable;
        _filesets= cmsFileDB.filesets;
    }
    return self;
}

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
                NSString *where = [NSString stringWithFormat:@"%@ IN (SELECT %@.%@ FROM %@ INNER JOIN %@ ON %@.%@ = %@.%@ AND %@.%@ != %@.%@)",
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

- (NSString *)cacheLocationForFileset:(NSString *)category {
    NSString *path = nil;
    IFCMSFileset *fileset = _filesets[category];
    if (fileset != nil && fileset.cachable) {
        path = [fileset cachePath:_authority];
    }
    return path;
}

// TODO: Consider breaking the following method into two; strictly speaking, the cache location
// should be writeable, but if content is packaged then its cache location isn't writeable.
- (NSString *)cacheLocationForFile:(NSDictionary *)fileRecord {
    NSString *path = nil;
    NSString *status = fileRecord[@"status"];
    NSString *category = fileRecord[@"category"];
    if ([@"packaged" isEqualToString:status]) {
        // Packaged content is distributed with the app, under a folder with the content authority name.
        path = _authority.packagedContentPath;
        path = [path stringByAppendingPathComponent:fileRecord[@"path"]];
    }
    else {
        IFCMSFileset *fileset = _filesets[category];
        if (fileset != nil && fileset.cachable) {
            NSString *cachePath = [fileset cachePath:_authority];
            path = [cachePath stringByAppendingPathComponent:fileRecord[@"path"]];
        }
    }
    return path;
}

- (NSString *)cacheLocationForFileWithPath:(NSString *)path {
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE path=?", _filesTable];
    NSArray *rs = [self performQuery:sql withParams:@[ path ]];
    return [rs count] > 0 ? [self cacheLocationForFile:rs[0]] : nil;
}

- (IFCMSFileDB *)newInstance {
    IFCMSFileDB *db = [[IFCMSFileDB alloc] initWithCMSFileDB:self];
    [db startService];
    return db;
}

#pragma mark - IFIOCTypeInspectable

- (__unsafe_unretained Class)memberClassForCollection:(NSString *)propertyName {
    if ([@"filesets" isEqualToString:propertyName]) {
        return [IFCMSFileset class];
    }
    return nil;
}

@end
