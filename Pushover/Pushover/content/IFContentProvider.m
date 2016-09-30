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

@implementation IFContentProvider

- (id)init {
    self = [super init];
    if (self) {
        _commandScheduler = [IFCommandScheduler new];
        _commandScheduler.queueDBName = @"po.commandqueue";
        _httpClient = [IFHTTPClient new];
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

#pragma mark - IFIOCSingleton

+ (id)iocSingleton {
    return [IFContentProvider getInstance];
}

@end
