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

#import <Foundation/Foundation.h>
#import "IFIOCProxy.h"
#import "IFContainer.h"

/**
 * A concrete implementation of the IOCProxy protocol. The main purpose of this class is to provide
 * a standard method for proxy class registration in IFContainer. Subclasses can invoke the
 * [registerConfigurationProxyClass: forClassName:] class method from their class [load] method;
 * IFContainer will then call the [registerProxyClasses] method on this class.
 * It's not required that configuration proxies extend this class, but implementations which don't
 * will then need to provide their own alternative registration method.
 */
@interface IFIOCProxyObject : NSObject <IFIOCProxy>

+ (void)registerConfigurationProxyClass:(Class)proxyClass forClassName:(NSString *)className;

+ (NSDictionary *)registeredProxyClasses;

@end
