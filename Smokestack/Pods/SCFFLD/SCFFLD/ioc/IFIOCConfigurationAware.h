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
//  Created by Julian Goacher on 26/10/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFContainer.h"

/**
 * An IOC component aware of the configuration lifecycle.
 */
@protocol IFIOCConfigurationAware <NSObject>

/**
 * Called immediately before the object is configured via dependency injection.
 * @param configuration The object's configuration.
 */
- (void)beforeIOCConfiguration:(IFConfiguration *)configuration;

/**
 * Called immediately after the object is configured via dependency injection.
 * @param configuration The object's configuration.
 */
- (void)afterIOCConfiguration:(IFConfiguration *)configuration;

@end
