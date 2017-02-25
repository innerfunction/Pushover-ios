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
//  Created by Julian Goacher on 16/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * A protocol for providing access to different representations of an underlaying value.
 * Values are referenced by key path.
 * @see <IFTypeConversions> for details of how values are converted to different types.
 */
@protocol IFValues <NSObject>

/// Return the bare value without any type conversion.
- (id)getValue:(NSString *)keyPath;
/// Test if a value exists at the specified key path.
- (BOOL)hasValue:(NSString *)keyPath;
/// Return a list of the top-level names in the values object.
- (NSArray *)getValueNames;
/// Return a value as a string.
- (NSString *)getValueAsString:(NSString *)keyPath;
/// Return a value as a string. Return the default value if no value exists at the specified path.
- (NSString *)getValueAsString:(NSString *)keyPath defaultValue:(NSString *)defaultValue;
/**
 * Get a value as a localized string. The underlying string value should correspond to a resource ID
 * in strings.xml, and the result is returned for the current platform locale.
 * Returns the _keyPath_ argument if the value can't be found.
 */
- (NSString *)getValueAsLocalizedString:(NSString *)keyPath;
/// Return a value as a number.
- (NSNumber *)getValueAsNumber:(NSString *)keyPath;
/// Return a value as a number. Return the default value if no value exists at the specified path.
- (NSNumber *)getValueAsNumber:(NSString *)keyPath defaultValue:(NSNumber *)defaultValue;
/// Return a value as a boolean.
- (BOOL)getValueAsBoolean:(NSString *)keyPath;
/// Return a value as a boolean. Return the default value if no value exists at the specified path.
- (BOOL)getValueAsBoolean:(NSString *)keyPath defaultValue:(BOOL)defaultValue;
/// Return a value as a date.
- (NSDate *)getValueAsDate:(NSString *)keyPath;
/// Return a value as a date. Return the default value if no value exists at the specified path.
- (NSDate *)getValueAsDate:(NSString *)keyPath defaultValue:(NSDate *)defaultValue;
/// Return a value as a color.
- (UIColor *)getValueAsColor:(NSString *)keyPath;
/// Return a value as a color. Return the default value if no value exists at the specified path.
- (UIColor *)getValueAsColor:(NSString *)keyPath defaultValue:(UIColor *)defaultValue;
/// Return a value as a URL.
- (NSURL *)getValueAsURL:(NSString *)keyPath;
/// Return a value as a data.
- (NSData *)getValueAsData:(NSString *)keyPath;
/// Return a value as an image.
- (UIImage *)getValueAsImage:(NSString *)keyPath;

@end
