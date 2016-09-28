//
//  IFContentProvider.m
//  Pushover
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
        _httpClient = [IFHTTPClient new];
    }
    return self;
}

- (void)setAuthorities:(NSDictionary *)authorities {
    _authorities = authorities;
    for (id name in [authorities keyEnumerator]) {
        id<IFContentAuthority> authority = _authorities[name];
        // TODO Pass scheduler & http client instances to authority here?
        // TODO Or just pass a reference to this provider?
        // TODO Or is there some way to do this using scffld?
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
