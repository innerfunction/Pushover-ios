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
//  Created by Julian Goacher on 12/04/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//
#import <Foundation/Foundation.h>

/**
 * A simple string template supporting just variable placeholder substitution.
 * Variable placeholders are specified in template strings using curly braces, e.g.
 * _{variable}_. Variable values are taken from a key-value encoding compliant data
 * context. Missing values are replaced with an empty string. Placeholders can be
 * escaped by nesting within additional braces, so e.g. _{{variable}}_ evaluates to
 * the output _{variable}_. A % symbol at the start of a placeholder (e.g. _{%name}_)
 * indicates that the variable value should be URI escaped.
 */
@interface IFStringTemplate : NSObject {
    // A list of the blocks in the compiled template, representing alternatively
    // static text blocks and variable references.
    NSMutableArray* blocks;
}

/**
 * A list of the unique variable names referenced by the compiled template.
 */
@property (nonatomic, strong) NSArray *refs;

/** Initialize the template with the specified string. */
- (id)initWithString:(NSString *)string;
/**
 * Render the template by evaluating it against the provided data context.
 * @param context   The key-value encoding compliant object to use as the data context.
 * @return The template string with all placeholder values replaced with values.
 */
- (NSString *)render:(id)context;
/**
 * Render the template by evaluating it against the provided data context.
 * @param context   The key-value encoding compliant object to use as the data context.
 * @param uriEncode If _true_ then all variable values are URI encoded before being inserted
 * into the result.
 * @return The template string with all placeholder values replaced with values.
 */
- (NSString *)render:(id)context uriEncode:(BOOL)uriEncode;
/** Utility method for instantiating a template with a string. */
+ (IFStringTemplate *)templateWithString:(NSString *)string;
/**
 * Utility method for instantiating a template and evaluating it against a data context.
 * @param template The template definition.
 * @param context   The key-value encoding compliant object to use as the data context.
 * @return The template string with all placeholder values replaced with values.
 */
+ (NSString *)render:(NSString *)template context:(id)context;
/**
 * Utility method for instantiating a template and evaluating it against a data context.
 * @param template The template definition.
 * @param context   The key-value encoding compliant object to use as the data context.
 * @param uriEncode If _true_ then all variable values are URI encoded before being inserted
 * into the result.
 * @return The template string with all placeholder values replaced with values.
 */
+ (NSString *)render:(NSString *)template context:(id)context uriEncode:(BOOL)uriEncode;

@end
