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

#import <Foundation/Foundation.h>

@interface IFLocals : NSObject {
    NSString *namespacePrefix;
    NSUserDefaults *preferences;
}

- (id)init;
- (id)initWithPrefix:(NSString *)prefix;

- (void)setValues:(NSDictionary *)values forceReset:(BOOL)forceReset;

- (NSString *)getStringForName:(NSString *)name;
- (NSString *)getStringForName:(NSString *)name defaultValue:(NSString *)defaultValue;
- (NSString *)setStringForName:(NSString *)name value:(NSString *)value;

- (NSInteger)getIntegerForName:(NSString *)name;
- (NSInteger)getIntegerForName:(NSString *)name defaultValue:(NSInteger)defaultValue;
- (NSInteger)setIntegerForName:(NSString *)name value:(NSInteger)value;

- (BOOL)getBooleanForName:(NSString *)name;
- (BOOL)getBooleanForName:(NSString *)name defaultValue:(BOOL)defaultValue;
- (BOOL)setBooleanForName:(NSString *)name value:(BOOL)value;

- (void)removeName:(NSString *)name;
- (void)removeNames:(NSArray *)names;

@end
