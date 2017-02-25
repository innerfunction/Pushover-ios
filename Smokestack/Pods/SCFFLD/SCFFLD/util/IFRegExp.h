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
//  Created by Julian Goacher on 10/03/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//
#import <Foundation/Foundation.h>

/**
 * A class providing a simplified interface to the standard NSRegularExpression class.
 */
@interface IFRegExp : NSObject {
    NSRegularExpression *regex;
}

/** Initialize a regex with the specified pattern. */
- (id)initWithPattern:(NSString *)pattern;
/** Initialize a regex with the specified pattern and matching options. */
- (id)initWithPattern:(NSString *)pattern options:(NSRegularExpressionOptions)options;
/**
 * Execute the regex on a string and return a list of the matching groups.
 * @param string    The string to test.
 * @return Returns an array of the strings within _string_ which are matched by the groups defined
 * in the regex.
 */
- (NSArray *)match:(NSString *)string;
/**
 * Return the range of the first match for the regex pattern in the argument.
 * @param string    The string to test.
 * @return Returns an NSRange object with the length and location of the first substring within _string_
 * that matches the regex pattern.
 */
- (NSRange)rangeOfFirstMatch:(NSString *)string;
/**
 * Test whether a string matches the regex pattern.
 * @param string    The string to test.
 * @return Returns boolean _true_ if the string matches the regex.
 */
- (BOOL)matches:(NSString *)string;
/**
 * Static utility method for executing a regex on a string.
 * @param pattern   A regex pattern.
 * @param string    The string to test.
 * @return Returns boolean _true_ if the string matches the regex.
 */
+ (BOOL)pattern:(NSString *)pattern matches:(NSString *)string;

@end
