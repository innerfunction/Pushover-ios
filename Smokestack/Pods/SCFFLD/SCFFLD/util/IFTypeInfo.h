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
// limitations under the License
//
//  Created by Julian Goacher on 22/04/2015.
//  Copyright (c) 2015 InnerFunction. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

/**
 * A class providing information about a single object property.
 * Allows the information about a property's type and accessibility to be accessed.
 */
@interface IFPropertyInfo : NSObject {
    // A description of the property's type information.
    NSString *_propertyType;
    // The property's declared class. Nil for primitive property types.
    __unsafe_unretained Class _propertyClass;
    // A selector for the property's protocol, if any.
    Protocol *_propertyProtocol;
    // A boolean specifying whether the property is writeable.
    BOOL _isWriteable;
}

/** Initialize a property which is id/NSObject compatible. */
- (id)init;
/** Initialize with a property reference. */
- (id)initWithProperty:(objc_property_t)property;
/** Initialize with a class reference. */
- (id)initWithClass:(__unsafe_unretained Class)classObj;
/** Test whether the property is a _boolean_ type. */
- (BOOL)isBoolean;
/** Test whether the property is an _integer_ type. */
- (BOOL)isInteger;
/** Test whether the property is a _float_ type. */
- (BOOL)isFloat;
/** Test whether the property is a _double_ type. */
- (BOOL)isDouble;
/** Test whether the property is an any-type reference. */
- (BOOL)isId;
/** Test whether the property type is assignable from another class. */
- (BOOL)isAssignableFrom:(__unsafe_unretained Class)classObj;
/** Test whether the property type is a member or subclass of another class. */
- (BOOL)isMemberOrSubclassOf:(__unsafe_unretained Class)classObj;
/** Get the property's declared class type. */
- (__unsafe_unretained Class)getPropertyClass;
/** Test whether the property is writeable. */
- (BOOL)isWriteable;

@end

/**
 * A class for inspecting all of the declared properties on an object.
 * Generates a list of all the publically accessible properties on an object's class
 * and all of its superclasses. Information can then be accessed for each property.
 */
@interface IFTypeInfo : NSObject {
    // A list of all the public properties on the object's class, including all superclasses.
    NSMutableDictionary *_properties;
}

/** Initialize with the specified object. Builds a list of all properties on the specified object. */
- (id)initWithObject:(id)object;
/**
 * Get information on a named property.
 * @param propName  The name of a property.
 * @return Information about the specified property, @see <IFPropertyInfo>.
 * Returns _nil_ if the property name isn't found.
 */
- (IFPropertyInfo *)infoForProperty:(NSString *)propName;

/**
 * Get type information for the specified object. This method will cache new type info instances
 * under the object's class name.
 * @param object The object to inspect.
 * @return Type information for the object's properties. If an object of this class has already been
 * seen then the cached result of the previous call is returned; otherwise a new instance is built
 * and cached before it is returned.
 */
+ (IFTypeInfo *)typeInfoForObject:(id)object;
/** Clear the type info cache. */
+ (void)clearCache;

@end
