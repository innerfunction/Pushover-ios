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
//  Created by Julian Goacher on 26/09/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFCMSFileset.h"

#define CacheDirName ([@"~" stringByAppendingString:_category])

@implementation IFCMSFileset

- (void)setCache:(NSString *)cache {
    _cache = cache;
    _cachable = ([@"content" isEqualToString:cache] || [@"app" isEqualToString:cache]);
}

- (NSString *)cachePath:(IFCMSContentAuthority *)authority {
    NSString *path = nil;
    if ([@"content" isEqualToString:_cache]) {
        path = [authority.contentCachePath stringByAppendingString:CacheDirName];
    }
    else if ([@"app" isEqualToString:_cache]) {
        path = [authority.appCachePath stringByAppendingString:CacheDirName];
    }
    return path;
}

#pragma mark - IFIOCObjectAware

- (void)notifyIOCObject:(id)object propertyName:(NSString *)propertyName {
    // Record the fileset's category name as the name this object is bound to in its parent object.
    _category = propertyName;
}

@end