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
//  Created by Julian Goacher on 07/03/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import "IFResource.h"
#import "IFValues.h"

/**
 * A protocol providing access to configuration data.
 * See the _root_ property of @see <IFConfiguration>.
 */
@protocol IFConfigurationData <NSObject>

/**
 * Get a particular representation of a configuration value.
 * @param key The value key.
 * @param representation The name of the required representation. @see <IFTypeInfo> for a list
 * of representation names.
 * @return The value in the required representation.
 */
- (id)getValue:(NSString *)keyPath asRepresentation:(NSString *)representation;

@end

/**
 * A class used to parse and access component configurations.
 */
@interface IFConfiguration : NSObject <IFValues, IFConfigurationData>

/// The configuration data.
@property (nonatomic, strong) NSDictionary *data;
/// The original data which the configuration data was derived from.
@property (nonatomic, strong) id sourceData;
/**
 * The top-level configuration.
 * When being processed, sub-parts of a configuration are often instantiated as new
 * configuration objects, but a reference to the top-level configuration must be
 * retained in order to properly resolve hash # property value references.
 */
@property (nonatomic, weak) id<IFConfigurationData> root;
/**
 * The configuration's data context.
 * Used as the data context for templated values. A configuration supports two types of templated
 * values:
 * - String template values, indicated by property values prefixed with _?_;
 * - Configuration template values, indicated by property values prefixed with _$_.
 */
@property (nonatomic, strong) NSDictionary *context;

/// A URI handler used to derefence URIs within the configuration.
@property (nonatomic, strong) id<IFURIHandler> uriHandler;

/// Initialize the configuration with the specified data.
- (id)initWithData:(id)data;
/**
 * Initialize the configuration with the specified data and parent configuration.
 * A parent configuration is used to provide values for this configuration's _root_, _context_ and
 * _uriHandler_ variables.
 */
- (id)initWithData:(id)data parent:(IFConfiguration *)parent;
/// Initialize the configuration with the specified data and URI handler.
- (id)initWithData:(id)data uriHandler:(id<IFURIHandler>)uriHandler;

/**
 * Try to convert a value to a configuration object.
 * This will work for the following argument types:
 * - IFConfiguration;
 * - Collection types, i.e. NSDictionary and NSArray members;
 * - IFResource, if the asJSONData method returns a collection type.
 * @return If the argument can be converted then returns a new IFConfiguration instance with the
 * current configuration object as a parent; otherwise returns nil.
 */
- (IFConfiguration *)asConfiguration:(id)value;

/**
 * Return the named representation of the configuration value and the specified key path.
 * @param keyPath The key path of the required value.
 * @param representation The name of the required representation.
 * @return The value at _keyPath_, or _nil_ if the value isn't found, or can't be represented
 * using the named representation.
 */
- (id)getValue:(NSString *)keyPath asRepresentation:(NSString*)representation;

/// Return the value at _keyPath_ as a configuration.
- (IFConfiguration *)getValueAsConfiguration:(NSString *)keyPath;
/// Return the value at _keyPath_ as a configuration. Return _defaultValue_ if _keyPath_ returns nil.
- (IFConfiguration *)getValueAsConfiguration:(NSString *)keyPath defaultValue:(IFConfiguration *)defaultValue;
/**
 * Return the value as JSON data.
 * This will be essentially the raw data read from the configuration file. JSON object or array values
 * will be returned as instances of JSONObject or JSONArray as appropriate (see JSONData.h).
 */
- (id)getValueAsJSONData:(NSString *)keyPath;

/**
 * Return the property value at _keyPath_ as a list of configurations.
 * The bare value at _keyPath_ should be an array. A new configuration will then be instantiated for
 * each item in the array, and the result returned.
 */
- (NSArray *)getValueAsConfigurationList:(NSString *)keyPath;

/**
 * Return the property value at _keyPath_ as a map (i.e. NSDictionary) of configurations.
 * This assumes that the underlying property value is a map (i.e. is described using a JSON object).
 * A new configuration object is instantiated for each item value in the map, and placed in the result
 * under the same item name.
 */
- (NSDictionary *)getValueAsConfigurationMap:(NSString *)keyPath;

/**
 * Create a new configuration by merging properties in another configuration with the current configuration.
 * The merge works by performing a top-level copy of properties from the argument to the current object.
 * This means that names in the argument will overwrite any properties with the same name in the current
 * configuration.
 * The _root_, _context_ and _uriHandler_ properties of the current configuration are copied to the result.
 */
- (IFConfiguration *)mixinConfiguration:(IFConfiguration *)otherConfig;

/**
 * Create a new configuration by merging the values of the current configuration over the values of another
 * configuration. This method is similar to the _mixinConfiguration:_ method except that value precedence
 * is in the reverse order (i.e. the current configuration's values take precedence over the other configs.
 * The _root_, _context_ and _uriHandler_ properties of the current configuration are copied to the result.
 */
- (IFConfiguration *)mixoverConfiguration:(IFConfiguration *)otherConfig;

/**
 * Create a new configuration with this configuration's data context extended with a set of named parameters.
 * The items in _params_ are added to this configuration's _context_ dictionary. Each parameter name
 * is prefixed with _$_ before being added, and will overwrite any parameters of the same name already
 * in the context.
 * @return Returns a new configuration which is a copy of the current configuration, but with a modified
 * data context.
 */
- (IFConfiguration *)extendWithParameters:(NSDictionary *)params;

/**
 * Flatten a configuration by resolving all _@config_ or _@mixin_ properties.
 * The @config and @mixin properties are provided as a horizontal extension mechanism. The property values
 * are resolved a configuration instances, and are then merged with the current configuration (see the
 * [mixinConfiguration:] method).
 * @return Returns the current configuration with the @config and @mixin properties merged in.
 */
- (IFConfiguration *)flatten;

/**
 * Normalize a configuration by first flattening, and then resolving any _@extends_ property.
 * This method resolves an extension hierarchy by resolving the _@extends_ property of the current
 * configuration, instantiating a configuration from that property value, and then resolving that
 * configuration's _@extends_ property, and so on until a root configuration is found. (Any closed
 * loops in the hierarchy are detected and ignored). Each configuration in the hierarchy is flattened
 * as it is resolved (i.e. mixins are copied in over the result). The hierarchy is then merged into
 * a single configuration result, with properties in child configurations taking priority over
 * properties with the same name in parent configurations.
 * @return Returns a new configuration containing the normalized result.
 */
- (IFConfiguration *)normalize;

/// Return a copy of the current configuration with the specified top-level keys removed.
- (IFConfiguration *)configurationWithKeysExcluded:(NSArray *)excludedKeys;

/// Returns a singleton-instance empty configuration object.
+ (IFConfiguration *)emptyConfiguration;

@end
