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
//  Created by Julian Goacher on 10/03/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>

#define IFCompoundURIParseError                     1
#define IFCompoundURITrailingCharacters             2

/**
 * A class representing a parsed compound URI string.
 * The URI syntax conforms to the following (partial) BNF:
 *
 *    COMPOUND_URI ::= ( BRACKETED_URI | ALIAS_OR_URI )
 *   BRACKETED_URI ::= '[' ALIAS_OR_URI ']'
 *    ALIAS_OR_URI ::= ( '~' ALIAS | URI )
 *             URI ::= SCHEME ':' NAME? ( '#' FRAGMENT )? PARAMETERS? ( '|' FORMAT )?
 *      PARAMETERS ::= '+' PARAM_NAME PARAM_VALUE PARAMETERS*
 *     PARAM_VALUE ::= ( '=' LITERAL | '@' COMPOUND_URI )
 *           ALIAS ::= '~' NAME ( '|' FORMAT )?
 *          SCHEME ::= (name characters)+
 *            NAME ::= (path characters)+
 *        FRAGMENT ::= (name characters)+
 *         LITERAL ::= (name characters)+
 *          FORMAT ::= (name characters)+
 *
 * TODO: Add an alias: scheme, and ~ as shorthand for accessing it (p@~name => p@alias:name)
 */
@interface IFCompoundURI : NSObject

/** The URI scheme name. */
@property (nonatomic, strong) NSString *scheme;
/** The URI _name_ part. */
@property (nonatomic, strong) NSString *name;
/** The URI _fragment_ part. */
@property (nonatomic, strong) NSString *fragment;
/**
 * A dictionary of the parameters defined in the URI parameter list. Each dictionary entry
 * maps the parameter name to a URI representing the value. (Note that all parameter values
 * can be represented as URIs; literal values are represented using the _s:_ scheme.
 */
@property (nonatomic, strong) NSDictionary *parameters;
/** The URI _format_ part. */
@property (nonatomic, strong) NSString *format;

/**
 * Create a new URI with a scheme and name.
 * @param scheme The URI's scheme name.
 * @param name The name part of the URI.
 */
- (id)initWithScheme:(NSString *)scheme name:(NSString *)name;
/**
 * Create a copy of a URI but in a new scheme.
 * @param scheme The name of the new URI's scheme.
 * @param uri The URI to copy.
 * @return A copy of _uri_ but with its scheme name changed to _scheme_.
 */
- (id)initWithScheme:(NSString *)scheme uri:(IFCompoundURI *)uri;
/**
 * Add additional parameters to the URI.
 */
- (void)addURIParameters:(NSDictionary *)params;
/**
 * Generate a canonical representation of the URI.
 * @return The string representation of the URI. URI parameters are:
 * - Shown in alphabetic name order;
 * - With literal values represented using the _s:_ scheme;
 * - All nested URIs are demarcated with square brackets.
 */
- (NSString *)canonicalForm;
/** Create a copy of the current URI. */
- (IFCompoundURI *)copyOf;
/**
 * Create a copy of the current URI but with the specified fragment.
 * @param fragment A fragment identifier to add use in place of the URIs current fragment.
 */
- (IFCompoundURI *)copyOfWithFragment:(NSString *)fragment;
/** Static utility method for parsing a URI string. */
+ (IFCompoundURI *)parse:(NSString *)uri error:(NSError **)error;
/**
 * Static utility method for parsing a URI string.
 * Swallows any error and instead returns _nil_ for invalid URIs.
 */
+ (IFCompoundURI *)parse:(NSString *)uri;

@end
