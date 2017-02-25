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
//  Created by Julian Goacher on 13/03/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFCompoundURI.h"

@protocol IFSchemeHandler;

/** A protocol for handling URIs by dereferencing them to resources or values. */
@protocol IFURIHandler <NSObject>

/**
 * Dereference a URI to a resource.
 * @param uri A compound URI, either as a non-parsed string or a parsed URI @see <IFCompoundURI>.
 * @return The deferenced value. Can be _nil_.
 */
- (id)dereference:(id)uriRef;
/**
 * Deferefence all of a URI's parameters.
 * @param uri   A parsed compound URI.
 * @return A dictionary mapping parameter names to the dereferenced parameter value.
 */
- (NSDictionary *)dereferenceParameters:(IFCompoundURI *)uri;
/**
 * Return a new URI handler with a modified scheme context (used to dereference relative URIs).
 */
- (id<IFURIHandler>)modifySchemeContext:(IFCompoundURI *)uri;
/**
 * Return a copy of this URI handler with a replacement scheme handler.
 */
- (id<IFURIHandler>)replaceURIScheme:(NSString *)scheme withHandler:(id<IFSchemeHandler>)handler;
/**
 * Test if the resolver has a registered handler for the named scheme.
 * @param scheme A scheme name.
 * @return Returns _true_ if scheme name is recognized.
 */
- (BOOL)hasHandlerForURIScheme:(NSString *)scheme;
/**
 * Add a scheme handler.
 * @param handler The new scheme handler.
 * @param scheme The name the scheme handler will be bound to.
 */
- (void)addHandler:(id<IFSchemeHandler>)handler forScheme:(NSString *)scheme;
/**
 * Return a list of all registered scheme names.
 */
- (NSArray *)getURISchemeNames;
/**
 * Get the handler for a named scheme.
 */
- (id<IFSchemeHandler>)getHandlerForURIScheme:(NSString *)scheme;

@end

/** A protocol for handling all URIs in a specific scheme. */
@protocol IFSchemeHandler <NSObject>

/**
 * Dereference a URI.
 * @param uri The parsed URI to be dereferenced.
 * @param params A dictionary of the URI's parameter name and values. All parameters have their
 * URI values dereferenced to their actual values.
 * @return The value referenced by the URI.
 */
- (id)dereference:(IFCompoundURI *)uri parameters:(NSDictionary *)params;

@optional

/**
 * Resolve a possibly relative URI against a reference URI.
 * Not all URI schemes support relative URIs, but e.g. file based URIs (@see <IFFileBasedSchemeHandler)
 * do allow relative path references in their URIs.
 * Each URI handler maintains a map of reference URIs, keyed by scheme name. When asked to resolve a
 * relative URI, the handler checks for a reference URI in the same scheme, and if one is found then
 * asks the scheme handler to resolve the relative URI against the reference URI.
 */
- (IFCompoundURI *)resolve:(IFCompoundURI *)uri against:(IFCompoundURI *)reference;

@end
