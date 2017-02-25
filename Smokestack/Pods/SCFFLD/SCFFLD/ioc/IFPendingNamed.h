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
//  Created by Julian Goacher on 14/03/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFTypeInfo.h"
#import "IFObjectConfigurer.h"

/**
 * A placeholder value used to represent a deferred named value.
 * Deferred names happen when circular dependencies are detected. In such cases, the named
 * value can't be resolved till after its configuration is complete. This placeholder allows
 * the details of the named dependency to be recorded so that it can be resolved after the
 * configuration cycle has completed.
 */
@interface IFPendingNamed : NSObject

/** The object which owns the property waiting for the pending value. */
@property (nonatomic, strong) id object;
/** A key value to use when tracking this pending in different container dictionaries. */
@property (nonatomic, strong) NSValue *objectKey;
/** The property key, e.g. property name; or array index or dictionary key. */
@property (nonatomic, strong) id key;
/** The key path of the property value on the named object. */
@property (nonatomic, strong) NSString *referencePath;
/** The object configurer waiting for the pending value. */
@property (nonatomic, weak) IFObjectConfigurer *configurer;
/** Information about the waiting property. Needed when injecting the resolved value into the property. */
@property (nonatomic, strong) IFPropertyInfo *propInfo;

/**
 * Test whether the pending has a configurer waiting for the result.
 * Not all pendings are used - some are discarded (e.g. when attempting to resolve a
 * configuration) and so don't need to be completed when resolved.
 */
- (BOOL)hasWaitingConfigurer;
/** Complete the pending by notifying the waiting configurer of the value result. */
- (id)completeWithValue:(id)value;

@end
