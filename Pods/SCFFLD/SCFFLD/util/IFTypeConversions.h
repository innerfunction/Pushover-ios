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
// limitations under the License
//
//  Created by Julian Goacher on 06/02/2014.
//  Copyright (c) 2014 InnerFunction. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 * Standard type conversions.
 */
@interface IFTypeConversions : NSObject

/**
 * Convert a value to a string.
 * @param value The value to convert.
 * @result The converted value:
 *
 *     NSString => NSString
 *     NSNumber => [value stringValue]
 *     NSData   => [NSString initWithData:]
 *     NSObject => [value description]
 */
+ (NSString *)asString:(id)value;

/**
 * Convert a value to a number.
 * @param value The value to convert.
 * @result The converted value:
 *
 *     NSNumber => NSNumber
 *     NSObject => nil
 */
+ (NSNumber *)asNumber:(id)value;

/**
 * Convert a value to a boolean.
 * @param value The value to convert.
 * @result The converted value:
 *
 *     NSNumber => BOOL
 *     NSObject => NO
 */
+ (BOOL)asBoolean:(id)value;

/**
 * Convert a value to a date.
 * @param value The value to convert.
 * @result The converted value:
 *
 *     NSDate   => NSDate
 *     NSNumber -> millisecond value => NSDate
 *     NSObject => NSString -> parse as ISO-8601 date string => NSDate
 */
+ (NSDate *)asDate:(id)value;

/**
 * Convert a value to a URL.
 * @param value The value to convert.
 * @result The converted value:
 *
 *     NSObject => NSString => NSURL
 */
+ (NSURL *)asURL:(id)value;

/**
 * Convert a value to NSData.
 * @param value The value to convert.
 * @result The converted value:
 *
 *     NSObject => NSString => NSData
 */
+ (NSData *)asData:(id)value;

/**
 * Convert a value to an image.
 * Coerces the value to a string, then uses that string as an image name.
 * Will attempt loading the image name with _-r4_ appended for 4-inch retina displays (obsolete functionality).
 */
+ (UIImage *)asImage:(id)value;

/**
 * Convert the value to parsed JSON data.
 * The method first coerces the value to a string, then examines the start of the string to see if it
 * looks like JSON data. If so, then it attempts parsing the string and returning the result.
 * If the JSON parse fails, or if the string doesn't look like JSON, then the initial value is returned
 * as it.
 */
+ (id)asJSONData:(id)value;
   
/**
 * Convert a value to the named representation.
 * @param name The representation name. Recognized names are:
 * - string
 * - number
 * - boolean (returned as a number, to conform with the return type).
 * - date
 * - url
 * - data
 * - image
 * - json
 * - default (returns the unchanged value).
 * @return Returns the value with the type conversion for the specified representation applied.
 * Returns _nil_ if the representation name isn't recognized.
 */
+ (id)value:(id)value asRepresentation:(NSString *)name;

@end
