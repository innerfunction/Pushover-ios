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
//  Created by Julian Goacher on 07/09/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFContentContainer.h"

// TODO:
// 1. Need a container for content containers; the primary purpose of this is to instantiate the command scheduler,
//    which can then be made available (by name? or auto-injection?) to child content containers.
// 2. The name the content-container container is bound to then affects the name format currently defined below;
//    this name can be discovered if the outer container implements the IFIOCObjectAware protocol.
// 3. Possibly then, the name the outer container is bound to should be made discoverable via a class method, so
//    that the overall discovery mechanism continues to work; this means that the outer container is effectively
//    a singleton.

/// The format used for content container names in the app container namespace.
#define IFContentContainerNameFormat (@"*content*.%@")

/**
 * A content URL protocol handler.
 * Content URLs follow closely the pattern used for Android content URIs
 * (@see https://developer.android.com/reference/android/content/ContentUris.html)
 * The basic format of a content URL is:
 * 
 *      content://{authority}/{path}
 *
 * Where 'authority' corresponds to a content container name, and 'path' is interpreted
 * by the container as a reference to the required data.
 */
@interface IFContentURLProtocol : NSURLProtocol

/**
 * Find a content container for the specified authority name.
 * Performs a lookup of named objects within the app container.
 */
+ (id<IFContentContainer>)findContentContainerForAuthority:(NSString *)authority;

@end
