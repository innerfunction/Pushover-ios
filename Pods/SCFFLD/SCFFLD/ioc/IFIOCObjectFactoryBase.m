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
//  Created by Julian Goacher on 16/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFIOCObjectFactoryBase.h"

@implementation IFIOCObjectFactoryBase

- (id)initWithBaseConfiguration:(NSDictionary *)baseConfiguration {
    self = [super init];
    if (self) {
        IFConfiguration *configuration = [[IFConfiguration alloc] initWithData:baseConfiguration];
        _baseConfiguration = [configuration flatten];
    }
    return self;
}

- (id)buildObjectWithConfiguration:(IFConfiguration *)configuration
                       inContainer:(IFContainer *)container
                    withParameters:(NSDictionary *)params
                        identifier:(NSString *)identifier {
    // Flatten the object configuration.
    configuration = [configuration flatten];
    // Extend the object configuration from the base configuration.
    configuration = [configuration mixoverConfiguration:_baseConfiguration];
    // If any parameters then extend the configuration using them.
    if (params) {
        configuration = [configuration extendWithParameters:params];
    }
    // Ask the container to build the object, then return the result.
    return [container buildObjectWithConfiguration:configuration identifier:identifier];
}

- (id)buildObjectWithConfiguration:(IFConfiguration *)configuration
                       inContainer:(IFContainer *)container
                        identifier:(NSString *)identifier {
    return [self buildObjectWithConfiguration:configuration inContainer:container withParameters:nil identifier:identifier];
}

@end
