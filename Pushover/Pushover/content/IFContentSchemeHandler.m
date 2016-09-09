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

#import "IFContentSchemeHandler.h"
#import "IFContentURLProtocol.h"

@implementation IFContentSchemeHandler

- (id)dereference:(IFCompoundURI *)uri parameters:(NSDictionary *)params {
    id content = nil;
    // The compound URI name contains both the authority and content path (e.g. as
    // content://{authority}/{path/to/content}).
    NSRange range = [uri.name rangeOfString:@"/"];
    if (range.location != NSNotFound) {
        NSString *authority = [uri.name substringToIndex:range.location];
        NSString *path = [uri.name substringFromIndex:range.location + 1];
        // Find the content container.
        id<IFContentContainer> contentContainer = [IFContentURLProtocol findContentContainerForAuthority:authority];
        if (contentContainer) {
            // Get the content.
            content = [contentContainer contentForAuthority:authority path:path parameters:params];
        }
    }
    return content;
}

@end
