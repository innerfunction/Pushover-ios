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
//  Created by Julian Goacher on 24/10/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFTableData.h"
#import "IFTypeConversions.h"
#import "objc/runtime.h"

@implementation IFTableData

- (id)init {
    self = [super init];
    if (self) {
        // Initialize the object with an empty data array.
        self.data = [NSArray array];
        self.searchFieldNames = [NSArray arrayWithObjects:@"title", @"description", nil];
        //dateParser = [[ISO8601DateFormatter alloc] init];
    }
    return self;
}

+ (IFTableData *)withData:(NSArray *)data {
    IFTableData *tableData = [[IFTableData alloc] init];
    tableData.data = data;
    return tableData;
}

// Set the table data.
- (void)setData:(NSArray *)data {
    // Test whether the data is grouped or non-grouped. If grouped, then extract section header titles from the data.
    // This method allows grouped data to be presented in one of two ways, and assumes that the data is grouped
    // consistently throughout.
    // * The first grouping format is as an array of arrays. The section header title is extracted as the first character
    // of the title of the first item in each group.
    // * The second grouping format is as an array of dictionaries. Each dictionary represents a section object with
    // 'title' and 'rows' properties.
    // Data can also be presented as an array of strings, in which case each string is used as a row title.
    id firstItem = [data count] > 0 ? [data objectAtIndex:0] : nil;
    if ([firstItem isKindOfClass:[NSArray class]]) {
        isGrouped = YES;
        NSMutableArray *titles = [[NSMutableArray alloc] initWithCapacity:[data count]];
        for (NSArray *section in data) {
            NSDictionary *row = section[0];
            if (row) {
                [titles addObject:[(NSString*)row[@"title"] substringToIndex:1]];
            }
            else {
                [titles addObject:@""];
            }
        }
        _data = data;
        sectionHeaderTitles = titles;
    }
    else if([firstItem isKindOfClass:[NSDictionary class]]) {
        // A 'rows' property on the row indicates a table section.
        if (firstItem[@"rows"]) {
            isGrouped = YES;
            NSMutableArray *titles = [[NSMutableArray alloc] initWithCapacity:[data count]];
            NSMutableArray *sections = [[NSMutableArray alloc] initWithCapacity:[data count]];
            for (NSDictionary *section in data) {
                NSString *sectionTitle = [_delegate getTableDataSectionTitle:section tableData:self];
                if (sectionTitle == nil) {
                    sectionTitle = section[@"title"];
                }
                [titles addObject:(sectionTitle ? sectionTitle : @"")];
                NSArray *sectionRows = section[@"rows"];
                [sections addObject:(sectionRows ? sectionRows : @[])];
            }
            _data = sections;
            sectionHeaderTitles = titles;
        }
        else {
            isGrouped = NO;
            _data = data;
        }
    }
    else if([firstItem isKindOfClass:[NSString class]]) {
        isGrouped = NO;
        NSMutableArray *rows = [[NSMutableArray alloc] initWithCapacity:[data count]];
        for (NSString *title in data) {
            [rows addObject:@{ @"title": title }];
        }
        _data = rows;
    }
    else {
        isGrouped = NO;
        _data = @[];
    }
    visibleData = _data;
}

// Get cell data for the specified path.
- (NSDictionary *)rowDataForIndexPath:(NSIndexPath *)path {
    // Resolve the cell data. First check the type of the first data item.
    // - If data is empty then result will be nil.
    // - If first data item is an NSArray then we're dealing with a grouped list (i.e. with sections).
    // - Else we are dealing with non-grouped data.
    NSDictionary *cellData = nil;
    if ([visibleData count] > 0) {
        if (isGrouped) {
            if ([visibleData count] > path.section) {
                NSArray *sectionData = [visibleData objectAtIndex:path.section];
                if ([sectionData count] > path.row) {
                    cellData = [sectionData objectAtIndex:path.row];
                }
            }
        }
        else if ([visibleData count] > path.row) {
            cellData = [visibleData objectAtIndex:path.row];
        }
    }
    return cellData;
}

- (BOOL)isEmpty {
    // TODO: A more complete implementation would take accout of grouped data with multiple empty sections.
    return [_data count] == 0;
}

- (BOOL)isGrouped {
    return isGrouped;
}

// Return the number of sections in the table data.
- (NSInteger)sectionCount {
    if ([visibleData count] > 0) {
        return isGrouped ? [visibleData count] : 1;
    }
    return 0;
}

- (NSString *)sectionTitle:(NSInteger)section {
    return [sectionHeaderTitles objectAtIndex:section];
}

// Return the number of rows in the specified section.
- (NSInteger)sectionSize:(NSInteger)section {
    NSInteger size = 0;
    if ([visibleData count] > 0) {
        if (isGrouped) {
            // If first item is an array then we have grouped data, return the size of the section
            // array if it exists, else 0.
            if ([visibleData count] > section) {
                NSArray *sectionArray = [visibleData objectAtIndex:section];
                size = [sectionArray count];
            }
            else {
                size = 0;
            }
        }
        else if (section == 0) {
            // We don't have grouped data, but if the required section is 0 then this corresponds to the
            // data array in a non-grouped data set.
            size = [visibleData count];
        }
    }
    return size;
}

- (void)filterBy:(NSString *)searchTerm scope:(NSString *)scope {
    NSArray *searchNames = scope ? [NSArray arrayWithObject:scope] : self.searchFieldNames;
    IFTableDataFilterBlock filterTest = ^(NSDictionary *row) {
        for (NSString *name in searchNames) {
            NSString *value = [row valueForKey:name];
            if (value && [value rangeOfString:searchTerm options:NSCaseInsensitiveSearch].location != NSNotFound) {
                return YES;
            }
        }
        return NO;
    };
    [self filterWithBlock:filterTest];
}

- (void)filterWithBlock:(IFTableDataFilterBlock)filterTest {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    if (isGrouped) {
        for (NSArray *section in _data) {
            NSMutableArray *filteredSection = [[NSMutableArray alloc] init];
            for (NSDictionary *row in section) {
                if (filterTest(row)) {
                    [filteredSection addObject:row];
                }
            }
            [result addObject:filteredSection];
        }
    }
    else {
        for (NSDictionary *row in _data) {
            if (filterTest(row)) {
                [result addObject:row];
            }
        }
    }
    visibleData = result;
}

- (void)clearFilter {
    visibleData = _data;
}

- (NSIndexPath *)pathForRowWithValue:(NSString *)value forField:(NSString *)name {
    if (isGrouped) {
        for (NSUInteger s = 0; s < [_data count]; s++) {
            NSArray *section = [_data objectAtIndex:s];
            for (NSUInteger r = 0; r < [section count]; r++) {
                NSDictionary *row = [section objectAtIndex:r];
                if ([value isEqualToString:[[row objectForKey:name] description]]) {
                    return [NSIndexPath indexPathForRow:r inSection:s];
                }
            }
        }
    }
    else {
        for (NSUInteger r = 0; r < [_data count]; r++) {
            NSDictionary *row = [_data objectAtIndex:r];
            // NOTE: Compare using the string value of the target field, so that numeric values specified
            // as a string will match.
            if ([value isEqualToString:[[row objectForKey:name] description]]) {
                return [NSIndexPath indexPathForRow:r inSection:0];
            }
        }
    }
    return nil;
}

@end
