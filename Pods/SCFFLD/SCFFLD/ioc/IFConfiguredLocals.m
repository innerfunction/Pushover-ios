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

#import "IFConfiguredLocals.h"

@implementation IFConfiguredLocals

- (id)initWithPrefix:(NSString *)_prefix configuration:(IFConfiguration *)_configuration {
    self = [super initWithPrefix:_prefix];
    if (self) {
        configuration = _configuration;
    }
    return self;
}

- (NSString *)getStringForName:(NSString *)name defaultValue:(NSString *)defaultValue {
    NSString *configValue = [configuration getValueAsString:name];
    return [super getStringForName:name defaultValue:configValue];
}

- (NSInteger)getIntegerForName:(NSString *)name defaultValue:(NSInteger)defaultValue {
    NSInteger configValue = [[configuration getValueAsNumber:name] integerValue];
    return [super getIntegerForName:name defaultValue:configValue];
}

- (BOOL)getBooleanForName:(NSString *)name defaultValue:(BOOL)defaultValue {
    BOOL configValue = [configuration getValueAsBoolean:name];
    return [super getBooleanForName:name defaultValue:configValue];
}

@end
