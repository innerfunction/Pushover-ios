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
//  Created by Julian Goacher on 22/04/2015.
//  Copyright (c) 2015 InnerFunction. All rights reserved.
//

#import "IFLocals.h"

@interface IFLocals ()

- (NSString *)getKeyForName:(NSString *)name;
- (BOOL)hasKey:(NSString *)key;

@end

@implementation IFLocals

- (id)init {
    return [self initWithPrefix:@""];
}

- (id)initWithPrefix:(NSString *)prefix {
    self = [super init];
    if (self) {
        namespacePrefix = [prefix stringByAppendingString:@"."];
        preferences = [NSUserDefaults standardUserDefaults];
    }
    return self;
}

- (void)setValues:(NSDictionary *)values forceReset:(BOOL)forceReset {
    for (NSString *name in [values keyEnumerator]) {
        NSString *key = [self getKeyForName:name];
        if (![preferences objectForKey:key] || forceReset) {
            id value = [values valueForKey:name];
            [preferences setObject:value forKey:key];
        }
    }
}

- (NSString *)getStringForName:(NSString *)name {
    return [self getStringForName:name defaultValue:nil];
}

- (NSString *)getStringForName:(NSString *)name defaultValue:(NSString *)defaultValue {
    NSString *value = [preferences stringForKey:[self getKeyForName:name]];
    return value ? value : defaultValue;
}

- (NSString *)setStringForName:(NSString *)name value:(NSString *)value {
    [preferences setObject:value forKey:[self getKeyForName:name]];
    return value;
}

- (NSInteger)getIntegerForName:(NSString *)name {
    return [self getIntegerForName:name defaultValue:-1];
}

- (NSInteger)getIntegerForName:(NSString *)name defaultValue:(NSInteger)defaultValue {
    NSString *key = [self getKeyForName:name];
    return [self hasKey:key] ? [preferences integerForKey:key] : defaultValue;
}

- (NSInteger)setIntegerForName:(NSString *)name value:(NSInteger)value {
    [preferences setInteger:value forKey:[self getKeyForName:name]];
    return value;
}

- (BOOL)getBooleanForName:(NSString *)name {
    return [self getBooleanForName:name defaultValue:NO];
}

- (BOOL)getBooleanForName:(NSString *)name defaultValue:(BOOL)defaultValue {
    NSString *key = [self getKeyForName:name];
    return [self hasKey:key] ? [preferences boolForKey:key] : defaultValue;
}

- (BOOL)setBooleanForName:(NSString *)name value:(BOOL)value {
    [preferences setBool:value forKey:[self getKeyForName:name]];
    return value;
}

- (void)removeName:(NSString *)name {
    [preferences removeObjectForKey:[self getKeyForName:name]];
}

- (void)removeNames:(NSArray *)names {
    for (NSString *name in names) {
        [self removeName:name];
    }
}

- (NSString *)getKeyForName:(NSString *)name {
    return [namespacePrefix stringByAppendingString:name];
}

- (BOOL)hasKey:(NSString *)key {
    return [preferences objectForKey:key] != nil;
}

@end
