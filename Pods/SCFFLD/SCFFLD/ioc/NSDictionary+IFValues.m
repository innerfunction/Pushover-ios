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
//  Created by Julian Goacher on 26/10/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "NSDictionary+IFValues.h"
#import "IFTypeConversions.h"
#import "UIColor+IF.h"

@implementation NSDictionary (IFValues)

- (id)getValue:(NSString *)name {
    return [self valueForKeyPath:name];
}

- (BOOL)hasValue:(NSString *)name {
    return [self getValue:name] != nil;
}

// Return a list of the top-level names in the values object.
- (NSArray *)getValueNames {
    return [self allKeys];
}
/*
// Return the type of the specified value.
- (IFValueType)getValueType:(NSString *)name {
    id value = [self getValue:name];
    if (value == nil)                           return IFValueTypeUndefined;
    // NOTE: Can't reliably detect boolean here, as boolean values are represented using NSNumber.
    if ([value isKindOfClass:[NSNumber class]]) return IFValueTypeNumber;
    if ([value isKindOfClass:[NSString class]]) return IFValueTypeString;
    if ([value isKindOfClass:[NSArray class]])  return IFValueTypeList;
    return IFValueTypeObject;
}
*/
// Resolve a string value on the row data.
- (NSString *)getValueAsString:(NSString *)name {
    return [self getValueAsString:name defaultValue:nil];
}

// Resolve a string value on the row data, return the default value if not set.
- (NSString *)getValueAsString:(NSString *)name defaultValue:(NSString *)defaultValue {
    NSString *value = [IFTypeConversions asString:[self getValue:name]];
    return value == nil ? defaultValue : value;
}

- (NSString *)getValueAsLocalizedString:(NSString *)name {
    NSString *value = [self getValueAsString:name];
    return value == nil ? @"" : NSLocalizedString(value, @"");
}

// Resolve a number value on the row data.
- (NSNumber *)getValueAsNumber:(NSString *)name {
    return [self getValueAsNumber:name defaultValue:nil];
}

// Resolve a number value on the row data, return the default value if not set.
- (NSNumber *)getValueAsNumber:(NSString *)name defaultValue:(NSNumber *)defaultValue {
    NSNumber *value = [IFTypeConversions asNumber:[self getValue:name]];
    return value == nil ? defaultValue : value;
}

// Resolve a boolean value on the row data.
- (BOOL)getValueAsBoolean:(NSString *)name {
    return [self getValueAsBoolean:name defaultValue:NO];
}

// Resolve a boolean value on the row data, return the default value if not set.
- (BOOL)getValueAsBoolean:(NSString *)name defaultValue:(BOOL)defaultValue {
    return [self hasValue:name] ? [IFTypeConversions asBoolean:[self getValue:name]] : defaultValue;
}

// Return the named property as a date value.
- (NSDate *)getValueAsDate:(NSString *)name {
    return [self getValueAsDate:name defaultValue:nil];
}

- (NSDate *)getValueAsDate:(NSString *)name defaultValue:(NSDate *)defaultValue {
    NSDate *value = [IFTypeConversions asDate:[self getValue:name]];
    return value == nil ? defaultValue : value;
}

// Return the named property as a colour value.
- (UIColor *)getValueAsColor:(NSString *)name {
    NSString *hexValue = [self getValueAsString:name];
    return hexValue != nil ? [UIColor colorForHex:hexValue] : nil;
}

- (UIColor *)getValueAsColor:(NSString *)name defaultValue:(UIColor *)defaultValue {
    UIColor *color = [self getValueAsColor:name];
    return color ? color : defaultValue;
}

// Return the named property as a URL.
- (NSURL *)getValueAsURL:(NSString *)name {
    return [IFTypeConversions asURL:[self getValue:name]];
}

// Return the named property as data.
- (NSData *)getValueAsData:(NSString *)name {
    return [IFTypeConversions asData:[self getValue:name]];
}

// Return the named property as an image.
- (UIImage *)getValueAsImage:(NSString *)name {
    return [IFTypeConversions asImage:[self getValue:name]];
}

@end
