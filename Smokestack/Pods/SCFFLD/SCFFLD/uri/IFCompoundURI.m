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

#import "IFCompoundURI.h"
#import "IFRegExp.h"
#import "NSDictionary+IF.h"

#define URIEncode(string) ([string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]])

@interface IFCompoundURI()

- (id)initWithAST:(NSDictionary *)ast error:(NSError **)error;
- (id)initWithString:(NSString *)input error:(NSError **)error;

@end

@implementation IFCompoundURI

- (id)initWithAST:(NSDictionary *)ast error:(NSError *__autoreleasing *)error {
    self = [super init];
    NSString *ast_error = ast[@"__error"];
    if (ast_error) {
        *error = [NSError errorWithDomain:@"IFCompoundURI"
                                     code:IFCompoundURIParseError
                                 userInfo:@{ @"message": ast_error }];
    }
    else {
        self.scheme = ast[@"scheme"];
        self.name = ast[@"name"];
        self.fragment = ast[@"fragment"];
        NSMutableDictionary *parameters = [NSMutableDictionary new];
        NSError *paramError;
        for (NSDictionary *param_ast in ast[@"parameters"]) {
            id name = param_ast[@"param_name"];
            id value = [[IFCompoundURI alloc] initWithAST:param_ast error:&paramError];
            if (paramError) {
                *error = paramError;
                break;
            }
            parameters[name] = value;
        }
        self.parameters = parameters;
        self.format = ast[@"format"];
    }
    return self;
}

- (id)initWithString:(NSString *)input error:(NSError *__autoreleasing *)error {
    self = [super init];
    NSMutableDictionary *ast = [NSMutableDictionary new];
    if (parseCompoundURI( input, ast )) {
        NSString *trailing = ast[@"__trailing"];
        if ([trailing length] > 0) {
            NSString *message = [NSString stringWithFormat:@"Trailing characters after URI: %@", trailing];
            *error = [NSError errorWithDomain:@"IFCompoundURI"
                                         code:IFCompoundURITrailingCharacters
                                     userInfo:@{ @"message": message }];
        }
        else {
            self = [self initWithAST:ast error:error];
        }
    }
    else {
        NSString *ast_error = ast[@"__error"];
        if (ast_error) {
            *error = [NSError errorWithDomain:@"IFCompoundURI"
                                         code:IFCompoundURIParseError
                                     userInfo:@{ @"message": ast_error }];
        }
        else {
            NSString *message = [NSString stringWithFormat:@"Unable to parse URI: %@", input];
            *error = [NSError errorWithDomain:@"IFCompoundURI"
                                         code:IFCompoundURIParseError
                                     userInfo:@{ @"message": message }];
        }
    }
    return self;
}

- (id)initWithScheme:(NSString *)scheme name:(NSString *)name {
    self = [super init];
    self.scheme = scheme;
    self.name = name;
    self.parameters = [NSDictionary dictionary];
    return self;
}

- (id)initWithScheme:(NSString *)scheme uri:(IFCompoundURI *)uri {
    self = [super init];
    self.scheme = scheme;
    self.name = uri.name;
    self.fragment = uri.fragment;
    self.parameters = uri.parameters;
    self.format = uri.format;
    return self;
}

- (void)addURIParameters:(NSDictionary *)params {
    self.parameters = [self.parameters extendWith:params];
}

- (NSString*)canonicalForm {
    // Alphabetically sort parameter keys.
    NSArray *keys = [[self.parameters allKeys] sortedArrayUsingComparator:^NSComparisonResult(id k1, id k2) {
        return [k1 compare:k2];
    }];
    // Generate a string containing the serialized form of all parameters.
    NSMutableString *serializedParams = [[NSMutableString alloc] init];
    for (NSString *key in keys) {
        IFCompoundURI *uri = [self.parameters valueForKey:key];
        [serializedParams appendString:@"+"];
        [serializedParams appendString:URIEncode(key)];
        [serializedParams appendString:@"@["];
        [serializedParams appendString:[uri canonicalForm]];
        [serializedParams appendString:@"]"];
    }
    NSString *frag = self.fragment ? [NSString stringWithFormat:@"#%@", URIEncode(self.fragment)] : @"";
    NSString *format = self.format ? [NSString stringWithFormat:@"|%@", URIEncode(self.format)] : @"";
    return [NSString stringWithFormat:@"%@:%@%@%@%@", URIEncode(self.scheme), URIEncode(self.name), frag, serializedParams, format];
}

- (IFCompoundURI*)copyOf {
    IFCompoundURI* copy = [[IFCompoundURI alloc] init];
    copy.scheme = self.scheme;
    copy.name = self.name;
    copy.fragment = self.fragment;
    copy.parameters = [self.parameters copy];
    copy.format = self.format;
    return copy;
}

- (IFCompoundURI *)copyOfWithFragment:(NSString *)fragment {
    IFCompoundURI *uri = [self copyOf];
    if (uri.fragment) {
        uri.fragment = [NSString stringWithFormat:@"%@.%@", uri.fragment, fragment];
    }
    else {
        uri.fragment = fragment;
    }
    return uri;
}

+ (IFCompoundURI*)parse:(NSString *)input error:(NSError *__autoreleasing *)error {
    return [[IFCompoundURI alloc] initWithString:input error:error];
}

+ (IFCompoundURI*)parse:(NSString *)input {
    NSError *error;
    IFCompoundURI *uri = [[IFCompoundURI alloc] initWithString:input error:&error];
    if (!error) {
        return uri;
    }
    return nil;
}

- (NSString*)description {
    return [self canonicalForm];
}

- (NSUInteger)hash {
    return [[self description] hash];
}

- (BOOL)isEqual:(id)object {
    return [object isKindOfClass:[IFCompoundURI class]] && [[self description] isEqualToString:[object description]];
}

// COMPOUND_URI ::= ( BRACKETED_URI | ALIAS_OR_URI )
BOOL parseCompoundURI(NSString *input, NSMutableDictionary *ast) {
    return parseBracketedURI( input, ast ) || parseAliasOrURI( input, ast );
}

// BRACKETED_URI ::= '[' PLAIN_URI ']'
BOOL parseBracketedURI(NSString *input, NSMutableDictionary *ast) {
    if ([input hasPrefix:@"["]) {
        input = [input substringFromIndex:1];
        if (parseURI( input, ast )) {
            input = ast[@"__trailing"];
            if ([input hasPrefix:@"]"]) {
                ast[@"__trailing"] = [input substringFromIndex:1];
                return YES;
            }
        }
    }
    return NO;
}

// ALIAS_OR_URI ::= ( '~' ALIAS | URI )
BOOL parseAliasOrURI(NSString *input, NSMutableDictionary *ast) {
    return parseAlias( input, ast ) || parseURI( input, ast );
}

// ALIAS ::= '~' NAME ( '|' FORMAT )?
BOOL parseAlias(NSString *input, NSMutableDictionary *ast) {
    if ([input hasPrefix:@"~"]) {
        input = [input substringFromIndex:1];
        if (parseName( input, ast )) {
            input = ast[@"__trailing"];
            // e.g. convert ~name => a:name
            ast[@"scheme"] = @"a";
            if (parseFormat( input, ast )) {
                input = ast[@"__trailing"];
            }
            return YES;
        }
    }
    return NO;
}

// URI ::= SCHEME ':' NAME? ( '#' FRAGMENT )? PARAMETERS? ( '|' FORMAT )?
BOOL parseURI(NSString *input, NSMutableDictionary *ast) {
    if (parseScheme( input, ast )) {
        input = ast[@"__trailing"];
        if ([input hasPrefix:@":"]) {
            input = [input substringFromIndex:1];
            if (parseName( input, ast )) {
                input = ast[@"__trailing"];
            }
            if ([input hasPrefix:@"#"]) {
                input = [input substringFromIndex:1];
                if (parseFragment( input, ast )) {
                    input = ast[@"__trailing"];
                }
            }
            NSMutableArray *parameters = [NSMutableArray new];
            NSMutableDictionary *param_ast = [NSMutableDictionary new];
            while (parseParameters( input, param_ast )) {
                [parameters addObject:param_ast];
                input = param_ast[@"__trailing"];
                param_ast = [NSMutableDictionary new];
            }
            ast[@"parameters"] = parameters;
            if (parseFormat( input, ast)) {
                input = ast[@"__trailing"];
            }
            ast[@"__trailing"] = input;
            return YES;
        }
    }
    return NO;
}

// Match any word characters
BOOL parseScheme(NSString *input, NSMutableDictionary *ast) {
    IFRegExp *schemeRegex = [[IFRegExp alloc] initWithPattern:@"^(\\w+)(.*)$"];
    NSArray *groups = [schemeRegex match:input];
    if (groups) {
        ast[@"scheme"] = groups[1];
        ast[@"__trailing"] = groups[2];
        return YES;
    }
    return NO;
}

// Match any word characters or . , / % _ ~ { } -
BOOL parseName(NSString *input, NSMutableDictionary *ast) {
    IFRegExp *nameRegex = [[IFRegExp alloc] initWithPattern:@"^([\\w.,/%_~{}-]*)(.*)$"];
    NSArray *groups = [nameRegex match:input];
    if (groups) {
        ast[@"name"] = groups[1];
        ast[@"__trailing"] = groups[2];
        return YES;
    }
    return NO;
}

// Match any word characters or . / % _ ~ -
BOOL parseFragment(NSString *input, NSMutableDictionary *ast) {
    IFRegExp *nameRegex = [[IFRegExp alloc] initWithPattern:@"^([\\w./%_~-]*)(.*)$"];
    NSArray *groups = [nameRegex match:input];
    if (groups) {
        ast[@"fragment"] = groups[1];
        ast[@"__trailing"] = groups[2];
        return YES;
    }
    return NO;
}

// PARAMETERS ::= '+' PARAM_NAME ( '@' URI | '=' LITERAL ) PARAMETERS*
BOOL parseParameters(NSString *input, NSMutableDictionary *ast) {
    if ([input hasPrefix:@"+"]) {
        input = [input substringFromIndex:1];
        if (parseParamName( input, ast )) {
            input = ast[@"__trailing"];
            if ([input hasPrefix:@"@"]) {
                input = [input substringFromIndex:1];
                return parseCompoundURI( input, ast );
            }
            else if ([input hasPrefix:@"="]) {
                input = [input substringFromIndex:1];
                if (parseParamLiteral( input, ast )) {
                    // Convert the literal value to the AST for a string scheme URI.
                    ast[@"scheme"] = @"s";
                    ast[@"name"] = ast[@"param_literal"];
                    return YES;
                }
            }
            else {
                ast[@"__error"] = [NSString stringWithFormat:@"Expected @ or = at %@", input];
            }
        }
    }
    return NO;
}

// Match an optional * prefix followed by any word characters or . _ ~ -
BOOL parseParamName(NSString *input, NSMutableDictionary *ast) {
    IFRegExp *paramNameRegex = [[IFRegExp alloc] initWithPattern:@"^(\\*?[\\w\\._~-]+)(.*)$"];
    NSArray *groups = [paramNameRegex match:input];
    if (groups) {
        ast[@"param_name"] = groups[1];
        ast[@"__trailing"] = groups[2];
        return YES;
    }
    return NO;

}

// Match any characters which aren't + ] or |
BOOL parseParamLiteral(NSString *input, NSMutableDictionary *ast) {
    IFRegExp *paramNameRegex = [[IFRegExp alloc] initWithPattern:@"^([^+|\\]]*)(.*)$"];
    NSArray *groups = [paramNameRegex match:input];
    if (groups) {
        ast[@"param_literal"] = groups[1];
        ast[@"__trailing"] = groups[2];
        return YES;
    }
    return NO;
}

// Match | followed by any format characters or _ ~ -
BOOL parseFormat(NSString *input, NSMutableDictionary *ast) {
    if ([input hasPrefix:@"|"]) {
        input = [input substringFromIndex:1];
        IFRegExp *nameRegex = [[IFRegExp alloc] initWithPattern:@"^([\\w_~-]*)(.*)$"];
        NSArray *groups = [nameRegex match:input];
        if (groups) {
            ast[@"format"] = groups[1];
            ast[@"__trailing"] = groups[2];
            return YES;
        }
    }
    return NO;
}

@end
