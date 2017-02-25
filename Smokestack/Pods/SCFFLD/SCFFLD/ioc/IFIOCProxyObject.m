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
//  Created by Julian Goacher on 09/03/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFIOCProxyObject.h"

@implementation IFIOCProxyObject

- (id)initWithValue:(id)value {
    return [super init];
}

- (id)unwrapValue {
    return nil;
}

#pragma mark - Static methods

// Map of configuration proxies keyed by class name. Classes without a registered proxy get an NSNull entry.
static NSMutableDictionary *IFIOCProxyObject_proxies;

+ (void)initialize {
    IFIOCProxyObject_proxies = [NSMutableDictionary new];
}

+ (void)registerConfigurationProxyClass:(__unsafe_unretained Class)proxyClass forClassName:(NSString *)className {
    IFIOCProxyObject_proxies[className] = [NSValue valueWithNonretainedObject:proxyClass];
}

+ (NSDictionary *)registeredProxyClasses {
    NSMutableDictionary *result = IFIOCProxyObject_proxies;
    IFIOCProxyObject_proxies = nil; // Discard proxy dictionary.
    return result;
}

@end
