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

#import <Foundation/Foundation.h>
#import "IFCompoundURI.h"
#import "IFURIHandling.h"

/**
 * A default implementation of the @see <IFURIHandler> protocol.
 * This implementation provides a number of default scheme handlers as-is, but additional handlers can be
 * mapped as needed.
 * The default supported schemes are:
 * - *s*: The string scheme, @see <IFStringSchemeHandler>;
 * - *a*: The alias scheme. This is a pseudo scheme without a specific handler, instead it is
 *        dereferenced by the URI handler.
 * - *app*: A file based scheme, mapped to the app's main bundle path;
 * - *cache*: A file based scheme, mapped to the app's _NSCachesDirectory_ path;
 * - *local*: Providing access to the app's local storage, @see <IFLocalSchemeHander>;
 * - *repr*: Allowing access to alternative resource representations, @see <IFLocalSchemeHandler>.
 */
@interface IFStandardURIHandler : NSObject <IFURIHandler> {
    NSMutableDictionary *_schemeHandlers;
    NSDictionary *_schemeContexts;
}

/** A map of named URI formatters. Members must implement the IFURIValueFormatter protocol. */
@property (nonatomic, strong) NSDictionary *formats;
/** A map of URI aliases. */
@property (nonatomic, strong) NSDictionary *aliases;

- (id)initWithSchemeContexts:(NSDictionary *)schemeContexts;
- (id)initWithMainBundlePath:(NSString *)mainBundlePath schemeContexts:(NSDictionary *)schemeContexts;

@end
