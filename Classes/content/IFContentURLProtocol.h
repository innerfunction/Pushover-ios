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
#import "IFContentAuthority.h"

/**
 * A content URL protocol handler.
 * Content URLs follow closely the pattern used for Android content URIs
 * (@see https://developer.android.com/reference/android/content/ContentUris.html)
 * The basic format of a content URL is:
 * 
 *      content://{authority}/{path}
 *
 * Where 'authority' corresponds to a content authority name, and 'path' is interpreted
 * by the authority as a reference to the required data.
 */
@interface IFContentURLProtocol : NSURLProtocol

/**
 * Find a content authority instance for the specified authority name.
 * Forwards the request to the IFContentProvider singleton instance.
 */
+ (id<IFContentAuthority>)findContentAuthorityForName:(NSString *)name;

@end
