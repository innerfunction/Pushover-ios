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

#define CacheDirName ([NSString stringWithFormat:@"pushover.fileset.%@", _category])

@implementation IFCMSFileset

@end

@implementation IFCMSFilesetCachePolicy

- (void)setPolicy:(NSString *)policy {
    _policy = policy;
    if ([@"NoCache" isEqualToString:policy]) {
        _cachable = NO;
    }
    if ([@"ContentCache" isEqualToString:policy]) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        NSString *cachePath = [paths objectAtIndex:0];
        self.path = [cachePath stringByAppendingPathComponent:CacheDirName];
        _cachable = YES;
    }
    else if ([@"AppCache" isEqualToString:policy]) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cachePath = [paths objectAtIndex:0];
        self.path = [cachePath stringByAppendingPathComponent:CacheDirName];
        _cachable = YES;
    }
    else {
        // Unrecognized cache policy.
        _cachable = NO;
    }
}

#pragma mark - IFIOCObjectAware

- (void)notifyIOCObject:(id)object propertyName:(NSString *)propertyName {
    // Record the fileset's category name as the name this object is bound to in its parent object.
    _category = propertyName;
}

@end