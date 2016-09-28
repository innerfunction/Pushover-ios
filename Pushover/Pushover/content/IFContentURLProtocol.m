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

#import "IFContentURLProtocol.h"
#import "IFContentProvider.h"

@implementation IFContentURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return [request.URL.scheme isEqualToString:@"content"];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

+ (id<IFContentAuthority>)findContentAuthorityForName:(NSString *)name {
    return [[IFContentProvider getInstance] contentAuthorityForName:name];
}

- (void)startLoading {
    id<IFContentAuthority> contentContainer = [IFContentURLProtocol findContentAuthorityForName:self.request.URL.host];
    if (contentContainer) {
        [contentContainer handleURLProtocolRequest:self];
    }
    else {
        NSString *description = [NSString stringWithFormat:@"Content authority %@ not found", self.request.URL.host];
        // See http://nshipster.com/nserror/
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                             code:NSURLErrorCannotFindHost
                                         userInfo:@{ NSLocalizedDescriptionKey: description }];
        [self.client URLProtocol:self didFailWithError:error];
    }
    //NSString *appID = [NSBundle.mainBundle.infoDictionary objectForKey:@"CFBundleIdentifier"];
    
}

- (void)stopLoading {
    [[IFContentURLProtocol findContentAuthorityForName:self.request.URL.host] cancelURLProtocolRequest:self];
}

@end
