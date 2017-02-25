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
//  Created by Julian Goacher on 07/03/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import "IFConfiguration.h"
#import "IFRegExp.h"
#import "IFStringTemplate.h"
#import "IFTypeConversions.h"
#import "NSDictionary+IF.h"
#import "UIColor+IF.h"
#import "IFJSONData.h"

#define ValueOrDefault(v,dv) (v == nil ? dv : v)

// Normalize the reference to _root for a new configuration object derived from the current.
// The _root reference is a weak reference and so needs special handling when normalizing or
// extending a configuration, as the configuration the result is derived from might be an
// intermediate result itself, and so can be lost at a later point. The solution is to
// check whether the source configuration's root is a reference to self - if it is, then
// use a reference to the new configuration in its place.
#define NormalizedRootRef(cfg)  ((self == _root) ? cfg : _root)

@interface IFArrayBackedDictionary : NSDictionary {
    NSNumberFormatter *_numParser;
}

@property (nonatomic, strong) NSArray *array;

- (id)initWithArray:(NSArray *)array;

@end

@interface IFConfiguration()

- (id)initWithConfiguration:(IFConfiguration *)config mixin:(IFConfiguration *)mixin parent:(IFConfiguration *)parent;
- (void)initializeContext;

@end

@implementation IFConfiguration

- (id)init {
    // Initialize with an empty dictionary.
    self = [super init];
    self.data = [NSDictionary dictionary];
    self.root = self;
    [self initializeContext];
    return self;
}

- (id)initWithData:(id)data {
    self = [self initWithData:data parent:[IFConfiguration emptyConfiguration]];
    self.root = self;
    return self;
}

- (id)initWithData:(id)data parent:(IFConfiguration *)parent {
    self = [super init];
    if (self) {
        if ([data isKindOfClass:[NSString class]]) {
            self.data = [IFTypeConversions asJSONData:data];
        }
        else {
            self.data = data;
        }
        self.root = parent.root;
        self.context = parent.context;
        self.uriHandler = parent.uriHandler;
        [self initializeContext];
    }
    return self;
}

- (id)initWithConfiguration:(IFConfiguration *)config mixin:(IFConfiguration *)mixin parent:(IFConfiguration *)parent {
    self = [super init];
    if (self) {
        self.data = [config.data extendWith:mixin.data];
        self.context = [config.context extendWith:mixin.context];
        self.root = parent.root;
        self.sourceData = parent.sourceData;
        self.uriHandler = parent.uriHandler;
        [self initializeContext];
    }
    return self;
}

- (id)initWithData:(id)data uriHandler:(id<IFURIHandler>)uriHandler {
    self = [self initWithData:data];
    if (self) {
        self.uriHandler = uriHandler;
        [self initializeContext];
    }
    return self;
}

- (void)setData:(id)data {
    _sourceData = data;
    if ([data isKindOfClass:[NSArray class]]) {
        _data = [[IFArrayBackedDictionary alloc] initWithArray:(NSArray *)data];
    }
    else if([data isKindOfClass:[NSDictionary class]]) {
        _data = (NSDictionary *)data;
    }
}

- (void)initializeContext {
    NSMutableDictionary *params = [NSMutableDictionary new];
    NSMutableDictionary *values = [NSMutableDictionary new];
    // Search the configuration data for any parameter values, filter parameter values out of main data values.
    for (NSString *name in [_data allKeys]) {
        if ([name hasPrefix:@"$"]) {
            params[name] = _data[name];
        }
        else {
            values[name] = _data[name];
        }
    }
    // Initialize/modify the context with parameter values, if any.
    if ([params count]) {
        if (self.context) {
            self.context = [self.context extendWith:params];
        }
        else {
            self.context = params;
        }
        self.data = values;
    }
    else if (!self.context) {
        self.context = [NSDictionary dictionary];
    }
}

- (IFConfiguration *)asConfiguration:(id)value {
    // If value is already a configuration then return as is.
    if ([value isKindOfClass:[IFConfiguration class]]) {
        return (IFConfiguration *)value;
    }
    // Try to resolve configuration data from the argument.
    id dataValue = value;
    IFResource *valueRsc = nil;
    // If value is a resource then try converting to JSON data.
    if ([value isKindOfClass:[IFResource class]]) {
        valueRsc = (IFResource *)value;
        dataValue = [valueRsc asJSONData];
    }
    // If value isn't a configuration by this point then promote to a new config,
    // providing data is one of the supported types.
    BOOL isConfigDataType = [dataValue isKindOfClass:[NSDictionary class]]
                         || [dataValue isKindOfClass:[NSArray class]];
    if (isConfigDataType) {
        IFConfiguration *configValue = [[IFConfiguration alloc] initWithData:dataValue parent:self];
        // NOTE When the configuration data is sourced from a resource, then the
        // following properties need to be different from when the data is found
        // directly in the configuration:
        // * root: The resource defines a new context for # refs, so root needs to
        //   point to the new config.
        // * uriHandler: The resource's handler needs to be used, so that any
        //   relative URIs within the resource data resolve correctly.
        if (valueRsc != nil) {
            configValue.root = configValue;
            configValue.uriHandler = valueRsc.uriHandler;
        }
        return [configValue normalize];
    }
    // Can't resolve a configuration so return nil.
    return nil;
}

- (id)getValue:(NSString*)keyPath asRepresentation:(NSString *)representation {
    id value = _data;
    NSArray *components = [keyPath componentsSeparatedByString:@"."];
    for (NSString *key in components) {
        // Unpack any resource value.
        if ([value isKindOfClass:[IFResource class]]) {
            value = [(IFResource *)value asJSONData];
        }
        // Lookup the key value on the current object.
        if ([value isKindOfClass:[NSArray class]]) {
            NSInteger idx = [key integerValue];
            value = value[idx];
        }
        else if ([value respondsToSelector:@selector(objectForKey:)]) {
            value = value[key];
        }
        else {
            value = nil;
        }
        // Continue if we have a value, else break out of the loop.
        if (value != nil) {
            // Modify the value by accounting for any value prefixes.
            if ([value isKindOfClass:[NSString class]]) {
                // Interpret the string value.
                NSString* valueStr = (NSString *)value;
                // First, attempt resolving any context references. If these in turn resolve to a
                // $ or # prefixed value, then they will be resolved in the following code.
                if ([valueStr hasPrefix:@"$"]) {
                    value = _context[valueStr];
                    // If context value is also a string then continue to following modifiers...
                    if ([value isKindOfClass:[NSString class]]) {
                        valueStr = (NSString *)value;
                    }
                    else {
                        // ...else continue to next key.
                        continue;
                    }
                }
                // Evaluate any string beginning with ? as a string template.
                if ([valueStr hasPrefix:@"?"]) {
                    valueStr = [valueStr substringFromIndex:1];
                    valueStr = [IFStringTemplate render:valueStr context:_context];
                }
                // String values beginning with @ are internal URI references, so dereference the URI.
                if ([valueStr hasPrefix:@"@"]) {
                    NSString *uri = [valueStr substringFromIndex:1];
                    value = [_uriHandler dereference:uri];
                }
                // Any string values starting with a '#' are potential path references to other
                // properties in the same configuration. Attempt to resolve them against the configuration
                // root; if they don't resolve then return the original value.
                else if ([valueStr hasPrefix:@"#"]) {
                    value = [_root getValue:[valueStr substringFromIndex:1] asRepresentation:representation];
                    if (value == nil) {
                        // If no value resolved then reset value to the #string
                        value = valueStr;
                    }
                }
                else if ([valueStr hasPrefix:@"`"]) {
                    value = [valueStr substringFromIndex:1];
                }
                else if (valueStr) {
                    value = valueStr;
                }
            }
        }
        else {
            break;
        }
    }
    
    // If something other than the raw representation is required then try to convert:
    // * configuration: See the asConfiguration: method;
    // * all other representations are passed to TypeConversions.
    if (![@"raw" isEqualToString:representation]) {
        if ([@"configuration" isEqualToString:representation]) {
            value = [self asConfiguration:value];
        }
        else if ([value isKindOfClass:[IFResource class]]) {
            value = [(IFResource *)value asRepresentation:representation];
        }
        else {
            value = [IFTypeConversions value:value asRepresentation:representation];
        }
    }
    return value;
}

- (BOOL)hasValue:(NSString *)keyPath {
    return [self getValue:keyPath asRepresentation:@"raw"] != nil;
}

- (NSString *)getValueAsString:(NSString *)keyPath {
    return [self getValueAsString:keyPath defaultValue:nil];
}

- (NSString *)getValueAsString:(NSString*)keyPath defaultValue:(NSString*)defaultValue {
    NSString* value = [self getValue:keyPath asRepresentation:@"string"];
    return value == nil || ![value isKindOfClass:[NSString class]] ? defaultValue : value;
}

- (NSString *)getValueAsLocalizedString:(NSString *)keyPath {
    NSString *value = [self getValueAsString:keyPath];
    return value == nil ? nil : NSLocalizedString(value, @"");
}

- (NSNumber *)getValueAsNumber:(NSString *)keyPath {
    return [self getValueAsNumber:keyPath defaultValue:nil];
}

- (NSNumber *)getValueAsNumber:(NSString*)keyPath defaultValue:(NSNumber*)defaultValue {
    NSNumber* value = [self getValue:keyPath asRepresentation:@"number"];
    return value == nil || ![value isKindOfClass:[NSNumber class]] ? defaultValue : value;
}

- (BOOL)getValueAsBoolean:(NSString *)keyPath {
    return [self getValueAsBoolean:keyPath defaultValue:NO];
}

- (BOOL)getValueAsBoolean:(NSString*)keyPath defaultValue:(BOOL)defaultValue {
    NSNumber* value = [self getValue:keyPath asRepresentation:@"number"];
    return value == nil ? defaultValue : [value boolValue];
}

// Resolve a date value on the cell data at the specified path.
- (NSDate *)getValueAsDate:(NSString *)keyPath {
    return [self getValueAsDate:keyPath defaultValue:nil];
}

// Resolve a date value on the cell data at the specified path, return the default value if not set.
- (NSDate *)getValueAsDate:(NSString *)keyPath defaultValue:(NSDate *)defaultValue {
    NSDate *value = [self getValue:keyPath asRepresentation:@"date"];
    return value == nil || ![value isKindOfClass:[NSDate class]] ? defaultValue : value;
}

- (UIColor *)getValueAsColor:(NSString *)keyPath {
    NSString *hexValue = [self getValueAsString:keyPath];
    return hexValue ? [UIColor colorForHex:hexValue] : nil;
}

- (UIColor *)getValueAsColor:(NSString *)keyPath defaultValue:(UIColor *)defaultValue {
    return ValueOrDefault([self getValueAsColor:keyPath], defaultValue);
}

- (NSURL *)getValueAsURL:(NSString *)keyPath {
    NSURL *value = [self getValue:keyPath asRepresentation:@"url"];
    return [value isKindOfClass:[NSURL class]] ? value : nil;
}

- (NSData *)getValueAsData:(NSString *)keyPath {
    NSData *value = [self getValue:keyPath asRepresentation:@"data"];
    return [value isKindOfClass:[NSData class]] ? value : nil;
}

- (UIImage *)getValueAsImage:(NSString *)keyPath {
    UIImage *value = [self getValue:keyPath asRepresentation:@"image"];
    return [value isKindOfClass:[UIImage class]] ? value : nil;
}

- (id)getValue:(NSString *)keyPath {
    return [self getValue:keyPath asRepresentation:@"raw"];
}

- (id)getValueAsJSONData:(NSString *)keyPath {
    id value = [self getValue:keyPath asRepresentation:@"raw"];
    if ([value isKindOfClass:[IFResource class]]) {
        value = [(IFResource *)value asJSONData];
    }
    if ([value isKindOfClass:[NSDictionary class]]) {
        value = [[IFJSONObject alloc] initWithDictionary:(NSDictionary *)value];
    }
    else if ([value isKindOfClass:[NSArray class]]) {
        value = [[IFJSONArray alloc] initWithArray:(NSArray *)value];
    }
    return value;
}

- (NSArray *)getValueNames {
    return [_data allKeys];
}

- (IFConfiguration *)getValueAsConfiguration:(NSString *)keyPath {
    return [[self getValue:keyPath asRepresentation:@"configuration"] normalize];
}

- (IFConfiguration *)getValueAsConfiguration:(NSString *)keyPath defaultValue:(IFConfiguration *)defaultValue {
    return ValueOrDefault([self getValueAsConfiguration:keyPath], defaultValue);
}

- (NSArray *)getValueAsConfigurationList:(NSString *)keyPath {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    id value = [self getValue:keyPath];
    if ([value isKindOfClass:[NSArray class]]) {
        NSArray *valuesArray = (NSArray *)value;
        if (![valuesArray isKindOfClass:[NSArray class]]) {
            valuesArray = [self getValue:keyPath asRepresentation:@"json"];
        }
        if ([valuesArray isKindOfClass:[NSArray class]]) {
            for (NSInteger i = 0; i < [valuesArray count]; i++) {
                NSString *itemKeyPath = [NSString stringWithFormat:@"%@.%ld", keyPath, (long)i];
                IFConfiguration *item = [self getValueAsConfiguration:itemKeyPath];
                [result addObject:item];
            }
        }
    }
    return result;
}

- (NSDictionary *)getValueAsConfigurationMap:(NSString *)keyPath {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    id values = [self getValue:keyPath];
    if ([values isKindOfClass:[NSDictionary class]]) {
        NSDictionary *valuesDictionary = (NSDictionary *)values;
        for (id key in [valuesDictionary allKeys]) {
            NSString *itemKeyPath = [NSString stringWithFormat:@"%@.%@", keyPath, key];
            IFConfiguration *item = [self getValueAsConfiguration:itemKeyPath];
            [result setObject:item forKey:key];
        }
    }
    return result;
}

- (IFConfiguration *)mixinConfiguration:(IFConfiguration *)otherConfig {
    return [[IFConfiguration alloc] initWithConfiguration:self mixin:otherConfig parent:self];
}

- (IFConfiguration *)mixoverConfiguration:(IFConfiguration *)otherConfig {
    return [[IFConfiguration alloc] initWithConfiguration:otherConfig mixin:self parent:self];
}

- (IFConfiguration *)extendWithParameters:(NSDictionary *)params {
    IFConfiguration *result = self;
    if ([params count] > 0) {
        NSMutableDictionary *$params = [NSMutableDictionary new];
        for (NSString *key in [params allKeys]) {
            NSString *$key = [NSString stringWithFormat:@"$%@", key];
            $params[$key] = params[key];
        }
        result = [[IFConfiguration alloc] initWithData:_data parent:self];
        result.context = [result.context extendWith:$params];
    }
    return result;
}

- (IFConfiguration *)flatten {
    IFConfiguration *result = self;
    IFConfiguration *mixin = [self getValueAsConfiguration:@"@config"];
    if (mixin) {
        result = [self mixinConfiguration:mixin];
    }
    mixin = [self getValueAsConfiguration:@"@mixin"];
    if (mixin) {
        result = [self mixinConfiguration:mixin];
    }
    NSArray *mixins = [self getValueAsConfigurationList:@"@mixins"];
    if (mixins) {
        for (IFConfiguration *mixin in mixins) {
            result = [self mixinConfiguration:mixin];
        }
    }
    return result;
}

- (IFConfiguration *)normalize {
    // Build a hierarchy of configurations extended by other configs.
    NSMutableArray *hierarchy = [NSMutableArray new];
    IFConfiguration *current = [self flatten];
    [hierarchy addObject:current];
    while ((current = [current getValueAsConfiguration:@"@extends"]) != nil) {
        current = [current flatten];
        if ([hierarchy containsObject:current]) {
            // Extension loop detected, stop extending the config.
            break;
        }
        [hierarchy addObject:current];
    }
    // Build a single unified configuration from the hierarchy of configs.
    IFConfiguration *result = [IFConfiguration emptyConfiguration];
    // Process the hierarchy in reverse order (i.e. from most distant ancestor to current config).
    for (IFConfiguration *config in [hierarchy reverseObjectEnumerator]) {
        result = [[IFConfiguration alloc] initWithConfiguration:result mixin:config parent:result];
    }
    result.sourceData = _sourceData;
    result.root = NormalizedRootRef(result);
    result.uriHandler = _uriHandler;
    return result;
}

- (IFConfiguration *)configurationWithKeysExcluded:(NSArray *)excludedKeys {
    NSDictionary *data = [_data dictionaryWithKeysExcluded:excludedKeys];
    IFConfiguration *result = [[IFConfiguration alloc] initWithData:data];
    result.sourceData = _sourceData;
    result.root = NormalizedRootRef(result);
    result.context = _context;
    result.uriHandler = _uriHandler;
    return result;
}

- (BOOL)isEqual:(id)object {
    // Two configurations are equal if the have the same source resource.
    return [object isKindOfClass:[IFConfiguration class]] && [_data isEqual:((IFConfiguration *)object).data];
}

static IFConfiguration *emptyConfiguaration;

+ (void)initialize {
    emptyConfiguaration = [[IFConfiguration alloc] init];
}

+ (IFConfiguration *)emptyConfiguration {
    return emptyConfiguaration;
}

@end

// NSDictionary interface backed by an NSArray
@implementation IFArrayBackedDictionary

- (id)initWithArray:(NSArray *)array {
    self = [super init];
    if (self) {
        _array = array;
        _numParser = [NSNumberFormatter new];
    }
    return self;
}

- (NSUInteger)count {
    return [_array count];
}

- (id)objectForKey:(id)aKey {
    // TODO: Need to test whether [_array valueForKey:aKey] will return the same result.
    NSNumber *num = [_numParser numberFromString:[aKey description]];
    NSInteger idx = num != nil ? num.integerValue : -1;
    return idx > -1 && idx < [_array count] ? [_array objectAtIndex:idx] : nil;
}

- (NSEnumerator *)keyEnumerator {
    NSMutableArray *keys = [[NSMutableArray alloc] initWithCapacity:[_array count]];
    for (NSInteger idx = 0; idx < [_array count]; idx++) {
        NSString *key = [[NSNumber numberWithInteger:idx] description];
        [keys addObject:key];
    }
    return [keys objectEnumerator];
}

@end
