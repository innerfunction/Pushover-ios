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
//  Created by Julian Goacher on 25/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "NSArray+IF.h"

@implementation NSArray (IF)

+ (NSArray *)arrayWithDictionaryKeys:(NSDictionary *)dictionary {
    NSMutableArray *keys = [[NSMutableArray alloc] init];
    if ([dictionary respondsToSelector:@selector(keyEnumerator)]) {
        for (id key in [dictionary keyEnumerator]) {
            [keys addObject:key];
        }
    }
    return keys;
}

+ (NSArray *)arrayWithDictionaryValues:(NSDictionary *)dictionary forKeys:(NSArray *)keys {
    NSMutableArray *values = [[NSMutableArray alloc] initWithCapacity:[keys count]];
    for (id key in keys) {
        [values addObject:[dictionary valueForKey:key]];
    }
    return values;
}

+ (NSArray *)arrayWithItem:(id)item repeated:(NSInteger)repeats {
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:repeats];
    for (NSInteger i = 0; i < repeats; i++) {
        [result addObject:item];
    }
    return result;
}

- (NSArray *)arrayWithoutItem:(id)item {
    NSPredicate *filter = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return ![item isEqual:evaluatedObject];
    }];
    return [self filteredArrayUsingPredicate:filter];
}

- (NSArray *)arrayWithoutHeadItem {
    NSInteger length = [self count];
    if (length > 1) {
        NSRange range = NSMakeRange(1, length - 2);
        return [self subarrayWithRange:range];
    }
    return @[];
}

@end
