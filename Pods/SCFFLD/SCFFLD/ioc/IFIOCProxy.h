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
//  Created by Julian Goacher on 04/03/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * A protocol which must be implemented by configuration proxies.
 * A configuration proxy is a class for objects which are configured in place of objects of
 * another class. They are useful for providing standardized configuration APIs which are
 * consistent across platforms; or for providing simplified configuration interfaces for
 * otherwise difficult to configure objects.
 * Configuration proxy classes should be registered using the IFContainer
 * _[registerConfigurationProxyClass: forClassName:]_ method.
 */
@protocol IFIOCProxy <NSObject>

/**
 * Initialize the proxy with a wrapped value.
 * This method will be called by the container when configuring an in-place value (i.e. a
 * value already on the object instance before dependency injection starts).
 * Support for this method is optional, depending on the particularities of the class being
 * proxied, but in general most proxies should support two modes of operation; (1) where the
 * value being proxied is new, and (2) where the value being proxied is in-place.
 */
- (id)initWithValue:(id)value;
/**
 * Unwrap the proxied value.
 * Called at the end of the configuration cycle. Should return a fully configured instance of
 * the class being proxied.
 */
- (id)unwrapValue;

@end
