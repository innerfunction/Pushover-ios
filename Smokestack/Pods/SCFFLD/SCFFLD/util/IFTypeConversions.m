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
//  Created by Julian Goacher on 06/02/2014.
//  Copyright (c) 2014 InnerFunction. All rights reserved.
//

#import "IFTypeConversions.h"
#import "IFRegExp.h"
#import "ISO8601DateFormatter.h"
#import "IFLogger.h"
#import "objc/runtime.h"

#define Retina4DisplayHeight    568
#define IsIPhone                ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
#define IsRetina4               ([[UIScreen mainScreen] bounds].size.height == Retina4DisplayHeight)
#define IsString(v)             ([v isKindOfClass:[NSString class]])
#define IsNumber(v)             ([v isKindOfClass:[NSNumber class]])

@implementation IFTypeConversions

+ (NSString *)asString:(id)value {
    NSString *result;
    if (IsString(value)) {
        result = value;
    }
    else if (IsNumber(value)) {
        result = [(NSNumber *)value stringValue];
    }
    else if ([value isKindOfClass:[NSData class]]) {
        result = [[NSString alloc] initWithData:(NSData *)value
                                       encoding:NSUTF8StringEncoding];
    }
    else {
        result = [value description];
    }
    return result;
}

+ (NSNumber *)asNumber:(id)value {
    NSNumber *result = nil;
    if (IsNumber(value)) {
        result = value;
    }
    else if([value isKindOfClass:[NSString class]]) {
        // Convert boolean true/false strings to 0/1.
        if ([@"true" isEqualToString:value]) {
            result = [NSNumber numberWithBool:YES];
        }
        else if ([@"false" isEqualToString:value]) {
            result = [NSNumber numberWithBool:NO];
        }
        else {
            // Try parsing the string as a number.
            NSNumberFormatter *parser = [NSNumberFormatter new];
            parser.numberStyle = NSNumberFormatterDecimalStyle;
            result = [parser numberFromString:value];
        }
    }
    return result;
}

+ (BOOL)asBoolean:(id)value {
    BOOL result = NO;
    NSNumber *nvalue = [IFTypeConversions asNumber:value];
    if( nvalue ) {
        result = [nvalue boolValue];
    }
    return result;
}

// Key for the date formatter associated object for the current thread.
static void *IFTypeConversions_threadDateFormatter;

+ (NSDate *)asDate:(id)value {
    NSDate *result = nil;
    if ([value isKindOfClass:[NSDate class]]) {
        result = value;
    }
    else if (IsNumber(value)) {
        result = [[NSDate alloc] initWithTimeIntervalSince1970:(NSTimeInterval)[(NSNumber *)value doubleValue]];
    }
    else {
        // A date formatter instance is stored as an associated object of the current thread to allow
        // efficient and thread-safe reuse of formatter objects.
        // (This is basically equivalent to a ThreadLocal in Java).
        NSThread *thread = [NSThread currentThread];
        // Attempt to read a formatter for the current thread.
        ISO8601DateFormatter *dateFormatter = objc_getAssociatedObject(thread, &IFTypeConversions_threadDateFormatter);
        if (!dateFormatter) {
            // No formatter found, so create a new one.
            dateFormatter = [[ISO8601DateFormatter alloc] init];
            objc_setAssociatedObject(thread, &IFTypeConversions_threadDateFormatter, dateFormatter, OBJC_ASSOCIATION_RETAIN);
        }
        // Parse the string representation of the current value.
        NSString *svalue = [IFTypeConversions asString:value];
        // TODO: Is error handling - try/catch - required here?
        result = [dateFormatter dateFromString:svalue];
    }
    return result;
}

+ (NSURL *)asURL:(id)value {
    return [NSURL URLWithString:[IFTypeConversions asString:value]];
}

+ (NSData *)asData:(id)value {
    if ([value isKindOfClass:[NSData class]]) {
        return value;
    }
    NSString *svalue = [IFTypeConversions asString:value];
    return [svalue dataUsingEncoding:NSUTF8StringEncoding];
}

+ (UIImage *)asImage:(id)value {
    UIImage *result = nil;
    NSString *baseName = [IFTypeConversions asString:value];
    if (baseName) {
        if (IsRetina4) {
            NSString *name = [NSString stringWithFormat:@"%@-r4", [baseName stringByDeletingPathExtension]];
            result = [UIImage imageNamed:name];
        }
        if (!result) {
            result = [UIImage imageNamed:baseName];
        }
    }
    return result;
}

+ (id)asJSONData:(id)value {
    id jsonData;
    if ([value isKindOfClass:[NSData class]]) {
        value = [[NSString alloc] initWithData:(NSData *)value encoding:NSUTF8StringEncoding];
    }
    if ([value isKindOfClass:[NSString class]]) {
        if ([IFRegExp pattern:@"^\\s*([{\\[\"\\d]|true|false)" matches:value]) {
            NSError *error = nil;
            NSData *data = [IFTypeConversions asData:value];
            jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error) {
                [IFLogger withTag:@"IFTypeConversions" error:@"Parsing JSON %@\n%@", value, error];
                jsonData = value;
            }
        }
        else {
            jsonData = value;
        }
    }
    else {
        jsonData = value;
    }
    return jsonData;
}

+ (id)value:(id)value asRepresentation:(NSString *)name {
    if ([@"string" isEqualToString:name]) {
        return [IFTypeConversions asString:value];
    }
    if ([@"number" isEqualToString:name] || [@"boolean" isEqualToString:name]) {
        return [IFTypeConversions asNumber:value];
    }
    if ([@"date" isEqualToString:name]) {
        return [IFTypeConversions asDate:value];
    }
    if ([@"url" isEqualToString:name]) {
        return [IFTypeConversions asURL:value];
    }
    if ([@"data" isEqualToString:name]) {
        return [IFTypeConversions asData:value];
    }
    if ([@"image" isEqualToString:name]) {
        return [IFTypeConversions asImage:value];
    }
    if ([@"json" isEqualToString:name]) {
        return [IFTypeConversions asJSONData:value];
    }
    if ([@"default" isEqualToString:name]) {
        return value;
    }
    // Representation name not recognized, so return nil.
    return nil;
}

@end
