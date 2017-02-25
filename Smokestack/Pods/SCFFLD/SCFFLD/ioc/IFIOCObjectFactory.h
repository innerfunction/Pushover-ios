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
//  Created by Julian Goacher on 15/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFConfiguration.h"
#import "IFContainer.h"

/**
 * A protocol implemented by objects which act as object factories for the IOC container.
 * Component configurations can nominate an object factory to build the object instead of the container,
 * using the _@factory_ instantiation hint.
 * Note that object factories take full responsibility for creating and building the required component
 * from its configuration, i.e. the container won't perform any dependency injection on the component
 * after its construction has been delegated to the function.
 */
@protocol IFIOCObjectFactory <NSObject>

/**
 * Build an object from its configuration. Instantiates and configures the object.
 * @param configuration     The object configuration.
 * @param container         The IOC container delegating the configuration.
 * @param identifier        An identifier for the object instance, used for log output.
 * @returns Returns a fully configured object instance.
 */
- (id)buildObjectWithConfiguration:(IFConfiguration *)configuration
                       inContainer:(IFContainer *)container
                        identifier:(NSString *)identifier;

@end