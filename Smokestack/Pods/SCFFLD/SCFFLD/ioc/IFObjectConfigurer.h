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
//  Created by Julian Goacher on 06/04/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFConfiguration.h"
#import "IFTypeInfo.h"
#import "IFLogger.h"

@class IFContainer;

/**
 * A class responsible for configuring an object. Processes the object's configuration
 * by resolving property values and injecting them into the object.
 */
@interface IFObjectConfigurer : NSObject {
    /// The object container.
    IFContainer *_container;
    /// The container's property type information.
    IFTypeInfo *_containerTypeInfo;
    /// The object logger.
    IFLogger *_logger;
}

/**
 * Initialize a container configurer.
 * A container is considered a collection (i.e. of named objects) with a default collection
 * member type of 'id'.
 * @param container The container to be configured.
 */
-(id)initWithContainer:(IFContainer *)container;
/// Perform the object configuration.
- (void)configureWith:(IFConfiguration *)configuration;
/**
 * Configure a named object of the container.
 * @param name              A property name.
 * @param configuration     The container configuration.
 * @return The fully configured object.
 */
- (id)configureNamed:(NSString *)name withConfiguration:(IFConfiguration *)configuration;
/**
 * Configure a single object using standard type info for the object class.
 * @param object            The object to configure.
 * @param configuration     The object's configuration.
 * @param kpPrefix          The key path prefix; used for logging.
 */

- (void)configureObject:(id)object
      withConfiguration:(IFConfiguration *)configuration
          keyPathPrefix:(NSString *)kpPrefix;
/**
 * Configure a single object.
 * @param object            The object to configure.
 * @param configuration     The object's configuration.
 * @param typeInfo          Type information for all the object's properties.
 * @param kpPrefix          The key path prefix; used for logging.
 */
- (void)configureObject:(id)object
      withConfiguration:(IFConfiguration *)configuration
               typeInfo:(IFTypeInfo *)typeInfo
          keyPathPrefix:(NSString *)kpPrefix;
/**
 * Build a property value from the specified object configuration.
 * @param object        The object being configured.
 * @param propName      The name of the property to configure.
 * @param configuration The object configuration; should contain the property configuration.
 * @param propInfo      Property type information for the object.
 * @param kpRef         A key path reference for the object; used for logging.
 * @return The value the property was configured with.
 */
- (id)buildValueForObject:(id)object
                 property:(NSString *)propName
        withConfiguration:(IFConfiguration *)configuration
                 propInfo:(IFPropertyInfo *)propInfo
               keyPathRef:(NSString *)kpRef;
/**
 * Inject a property value into the object.
 * @param object    The object being configured.
 * @param value     The value resolved from the object configuration.
 * @param name      The name of the property to inject.
 * @param propInfo  Property type information for the object.
 * @return The actual value injected into the property. May differ from configuration value if
 * e.g. the value was an IOCProxy.
 */
- (id)injectIntoObject:(id)object
                 value:(id)value
          intoProperty:(NSString *)name
              propInfo:(IFPropertyInfo *)propInfo;

@end
