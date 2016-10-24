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
//  Created by Julian Goacher on 28/09/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFContentProvider.h"
#import "IFContentAuthority.h"
#import "IFCMSContentAuthority.h"

#define PushoverNamePrefix (@"po")

@implementation IFContentProvider

- (id)init {
    self = [super init];
    if (self) {
        _commandScheduler = [IFCommandScheduler new];
        _commandScheduler.queueDBName = [NSString stringWithFormat:@"%@.commandqueue", PushoverNamePrefix];
        _httpClient = [IFHTTPClient new];
        
        // NOTES on staging and cache paths:
        // * Freshly downloaded content is stored under the staging path until the download is complete,
        //   after which it is deployed to the appropriate cache path and deleted from the staging location.
        //   The staging path is placed under NSApplicationSupportDirectory to avoid it being deleted by
        //   the system mid-download, in the case where the system needs to free up disk space.
        // * App content is deployed under NSApplicationSupportDirectory to avoid it being cleared by the system.
        // * All other content is deployed under NSCachesDirectory, where the system may remove it if it needs to
        //   recover disk space. If this happens then Semo will attempt to re-downloaded the content again, if
        //   needed.
        // See:
        // * http://developer.apple.com/library/ios/#documentation/FileManagement/Conceptual/FileSystemProgrammingGUide/FileSystemOverview/FileSystemOverview.html
        //
        // * https://developer.apple.com/library/ios/#documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/PerformanceTuning/PerformanceTuning.html#//apple_ref/doc/uid/TP40007072-CH8-SW8
        //
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        NSString *cachePath = [paths objectAtIndex:0];
        NSString *dirName = [NSString stringWithFormat:@"%@.staging", PushoverNamePrefix];
        _stagingPath = [cachePath stringByAppendingPathComponent:dirName];
        dirName = [NSString stringWithFormat:@"%@.app", PushoverNamePrefix];
        _appCachePath = [cachePath stringByAppendingPathComponent:dirName];
        
        // Switch cache path for content location.
        paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        cachePath = [paths objectAtIndex:0];
        dirName = [NSString stringWithFormat:@"%@.content", PushoverNamePrefix];
        _contentCachePath = [cachePath stringByAppendingPathComponent:dirName];

        // Packaged content stored in a folder named 'packaged-content'.
        _packagedContentPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"packaged-content"];
    }
    return self;
}

- (void)setAuthorities:(NSDictionary *)authorities {
    _authorities = authorities;
    for (id name in [authorities keyEnumerator]) {
        id<IFContentAuthority> authority = _authorities[name];
        authority.provider = self;
    }
}

- (id<IFContentAuthority>)contentAuthorityForName:(NSString *)name {
    return _authorities[name];
}

+ (IFContentProvider *)getInstance {
    static IFContentProvider *instance;
    if (instance == nil) {
        instance = [IFContentProvider new];
    }
    return instance;
}

#pragma mark - IFIOCTypeInspectable

- (__unsafe_unretained Class)memberClassForCollection:(NSString *)propertyName {
    if ([@"authorities" isEqualToString:propertyName]) {
        // Use CMSContentAuthority as the default authority type.
        return [IFCMSContentAuthority class];
    }
    return nil;
}

#pragma mark - IFIOCSingleton

+ (id)iocSingleton {
    return [IFContentProvider getInstance];
}

@end
