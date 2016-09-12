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
//  Created by Julian Goacher on 12/09/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFWPSearchPathRoot.h"

@implementation IFWPSearchPathRoot

- (id)initWithContainer:(IFWPContentContainer *)container {
    self = [super init];
    if (self) {
        _container = container;
        _postDBAdapter = container.postDBAdapter;
    }
    return self;
}

#pragma mark - IFContentContainerPathRoot

- (void)writeResponse:(id<IFContentContainerResponse>)response
         forAuthority:(NSString *)authority
                 path:(IFContentPath *)path
           parameters:(NSDictionary *)params {
    NSArray *components = [path components];
    if ([components count] == 0) {
        // e.g. content://{authority}/search
        NSString *text = params[@"text"];
        NSString *mode = params[@"mode"];
        NSArray *postTypes = nil;
        NSString *types = params[@"types"];
        if (types) {
            postTypes = [types componentsSeparatedByString:@","];
        }
        NSString *parent = params[@"parent"];
        id content = [_postDBAdapter searchPostsForText:text
                                             searchMode:mode
                                              postTypes:postTypes
                                             parentPost:parent];
        [response respondWithJSONData:content cachePolicy:NSURLCacheStorageNotAllowed];
    }
    else {
        [response respondWithError:makeInvalidPathResponseError([path fullPath])];
    }
}

@end
