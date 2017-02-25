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
//  Created by Julian Goacher on 12/03/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import "IFStandardURIHandler.h"
#import "IFStringSchemeHandler.h"
#import "IFFileBasedSchemeHandler.h"
#import "IFLocalSchemeHandler.h"
#import "IFReprSchemeHandler.h"
#import "IFResource.h"
#import "IFURIValueFormatter.h"
#import "NSDictionary+IF.h"

#define MainBundlePath  ([[NSBundle mainBundle] resourcePath])

@interface IFStandardURIHandler()

- (id)initWithMainBundlePath:(NSString *)mainBundlePath schemeHandlers:(NSMutableDictionary *)schemeHandlers schemeContexts:(NSDictionary *)schemeContexts;
- (IFCompoundURI *)promoteToCompoundURI:(id)uri;

@end

// Internal URI resolver. The resolver is configured with a set of mappings between
// URI scheme names and scheme handlers, which it then uses to resolve compound URIs
// to URI resources.
@implementation IFStandardURIHandler

- (id)init {
    return [self initWithMainBundlePath:MainBundlePath schemeContexts:[NSDictionary dictionary]];
}

- (id)initWithSchemeContexts:(NSDictionary *)schemeContexts {
    return [self initWithMainBundlePath:MainBundlePath schemeContexts:schemeContexts];
}

- (id)initWithMainBundlePath:(NSString *)mainBundlePath schemeContexts:(NSDictionary *)schemeContexts {
    return [self initWithMainBundlePath:mainBundlePath schemeHandlers:[[NSMutableDictionary alloc] init] schemeContexts:schemeContexts];
}

- (id)initWithMainBundlePath:(NSString *)mainBundlePath schemeHandlers:(NSMutableDictionary *)schemeHandlers schemeContexts:(NSDictionary *)schemeContexts {
    self = [super init];
    if (self) {
        _schemeHandlers = schemeHandlers;
        _schemeContexts = schemeContexts;
        // Add standard schemes.
        _schemeHandlers[@"s"] = [IFStringSchemeHandler new];
        // See following for info on iOS file system dirs.
        // https://developer.apple.com/library/mac/#documentation/Cocoa/Reference/Foundation/Miscellaneous/Foundation_Constants/Reference/reference.html
        // http://developer.apple.com/library/ios/#documentation/FileManagement/Conceptual/FileSystemProgrammingGUide/FileSystemOverview/FileSystemOverview.html
        // TODO: app: scheme handler not resolving (in simulator anyway):
        // Resolved path: /Users/juliangoacher/Library/Application\ Support/iPhone\ Simulator/5.0/Applications/F578A85D-A358-4897-A0BE-9BE8714B50D4/Applications/
        // Actual path:   /Users/juliangoacher/Library/Application\ Support/iPhone\ Simulator/5.0/Applications/F578A85D-A358-4897-A0BE-9BE8714B50D4/EventPacComponents.app/
        _schemeHandlers[@"app"] = [[IFFileBasedSchemeHandler alloc] initWithPath:mainBundlePath];
        _schemeHandlers[@"cache"] = [[IFFileBasedSchemeHandler alloc] initWithDirectory:NSCachesDirectory];
        _schemeHandlers[@"local"] = [IFLocalSchemeHandler new];
        _schemeHandlers[@"repr"] = [IFReprSchemeHandler new];
    }
    return self;
}

// Test whether this resolver has a handler for a URI's scheme.
- (BOOL)hasHandlerForURIScheme:(NSString *)scheme {
    return [_schemeHandlers valueForKey:scheme] != nil;
}

// Register a new scheme handler.
- (void)addHandler:(id<IFSchemeHandler>)handler forScheme:(NSString *)scheme {
    [_schemeHandlers setValue:handler forKey:scheme];
}

// Return a list of registered URI scheme names.
- (NSArray *)getURISchemeNames {
    return [_schemeHandlers allKeys];
}

// Return the URI handler for the named scheme.
- (id<IFSchemeHandler>)getHandlerForURIScheme:(NSString *)scheme {
    return [_schemeHandlers valueForKey:scheme];
}

- (id)dereference:(id)uriRef {
    IFCompoundURI *uri = [self promoteToCompoundURI:uriRef];
    id value = nil;
    if (uri) {
        // Resolve a handler for the URI scheme.
        id<IFSchemeHandler> schemeHandler = [_schemeHandlers valueForKey:uri.scheme];
        if (schemeHandler) {
            NSDictionary *params = [self dereferenceParameters:uri];
            // Resolve the current URI to an absolute form (potentially).
            if ([schemeHandler respondsToSelector:@selector(resolve:against:)]) {
                IFCompoundURI *reference = [_schemeContexts valueForKey:uri.scheme];
                if (reference) {
                    uri = [schemeHandler resolve:uri against:reference];
                }
            }
            // Dereference the current URI.
            value = [schemeHandler dereference:uri parameters:params];
        }
        else if ([@"a" isEqualToString:uri.scheme]) {
            // The a: scheme is a pseudo-scheme which is handled by the URI handler rather than a specific
            // scheme handler. Lookup a URI alias and dereference that.
            NSString *aliasedURI = _aliases[uri.name];
            value = [self dereference:aliasedURI];
        }
        else {
            NSString *reason = [NSString stringWithFormat:@"Handler not found for scheme %@:", uri.scheme];
            @throw [[NSException alloc] initWithName:@"IFURIResolver" reason:reason userInfo:nil];
        }
        // If the value is a resource then set its URI, and its URI handler as a copy of this handler,
        // with the scheme context modified with the resource's URI.
        if ([value isKindOfClass:[IFResource class]]) {
            IFResource *resource = (IFResource *)value;
            resource.uri = uri;
            resource.uriHandler = [self modifySchemeContext:uri];
        }
        // If the URI specifies a formatter then apply it to the URI result.
        if (uri.format) {
            id<IFURIValueFormatter> formatter = _formats[uri.format];
            if (formatter) {
                value = [formatter formatValue:value fromURI:uri];
            }
            else {
                NSString *reason = [NSString stringWithFormat:@"Formatter not found for name %@:", uri.format];
                @throw [[NSException alloc] initWithName:@"IFURIResolver" reason:reason userInfo:nil];
            }
        }
    }
    return value;
}

- (NSDictionary *)dereferenceParameters:(IFCompoundURI *)uri {
    // Dictionary of resolved URI parameters.
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:[uri.parameters count]];
    // Iterate over the URIs parameter values (which are also URIs) and dereference each
    // of them.
    for (NSString *name in [uri.parameters allKeys]) {
        IFCompoundURI *valueURI = uri.parameters[name];
        id value = [self dereference:valueURI];
        if (value) {
            params[name] = value;
        }
    }
    return params;
}

- (id<IFURIHandler>)modifySchemeContext:(IFCompoundURI *)uri {
    IFStandardURIHandler *handler = [IFStandardURIHandler new];
    handler->_schemeHandlers = _schemeHandlers;
    handler->_schemeContexts = [_schemeContexts extendWith:@{ uri.scheme: uri }];
    handler.formats = self.formats;
    handler.aliases = self.aliases;
    return handler;
}

- (id<IFURIHandler>)replaceURIScheme:(NSString *)scheme withHandler:(id<IFSchemeHandler>)handler {
    _schemeHandlers[scheme] = handler;
    return self;
}

#pragma mark - private

- (IFCompoundURI *)promoteToCompoundURI:(id)uri {
    if (!uri) {
        return nil;
    }
    if ([uri isKindOfClass:[IFCompoundURI class]]) {
        return (IFCompoundURI *)uri;
    }
    // Attempt to promote the argument to a compound URI by first converting to a string, followed
    // by parsing the string.
    NSError *error;
    NSString *uriString;
    if ([uri isKindOfClass:[NSString class]]) {
        uriString = (NSString *)uri;
    }
    else {
        uriString = [uri description];
    }
    IFCompoundURI *result = [IFCompoundURI parse:uriString error:&error];
    if (error) {
        NSString *reason = [NSString stringWithFormat:@"Error parsing URI %@ code: %ld message: %@", uriString, (long)error.code, [error.userInfo valueForKey:@"message"]];
        @throw [[NSException alloc] initWithName:@"IFURIResolver" reason:reason userInfo:nil];
    }
    return result;
}

@end
