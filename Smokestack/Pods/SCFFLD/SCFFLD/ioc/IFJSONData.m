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
//  Created by Julian Goacher on 06/04/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//
//
//  IFJSONData.m
//  SemoCore
//
//  Created by Julian Goacher on 30/07/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFJSONData.h"

@implementation IFJSONObject

- (id)initWithDictionary:(NSDictionary *)otherDictionary {
    self = [super init];
    if (self) {
        _properties = [[NSDictionary alloc] initWithDictionary:otherDictionary];
    }
    return self;
}

- (id)objectForKey:(id)aKey {
    return _properties[aKey];
}

- (NSUInteger)count {
    return [_properties count];
}

- (NSEnumerator *)keyEnumerator {
    return [_properties keyEnumerator];
}

- (NSEnumerator *)objectEnumerator {
    return [_properties objectEnumerator];
}

- (NSArray *)allValues {
    return [_properties allValues];
}

- (NSArray *)allKeys {
    return [_properties allKeys];
}

@end

@implementation IFJSONArray

- (id)initWithArray:(NSArray *)array {
    self = [super init];
    if (self) {
        _items = [[NSArray alloc] initWithArray:array];
    }
    return self;
}

- (id)objectAtIndex:(NSUInteger)index {
    return _items[index];
}

- (NSUInteger)count {
    return [_items count];
}

@end