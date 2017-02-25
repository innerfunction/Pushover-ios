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
//  Created by Julian Goacher on 08/03/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Protocol implemented by property values that wish to be aware of their property's parent object.
 */
@protocol IFIOCObjectAware <NSObject>

/**
 * Notify a value that it is about to be injected into an object using the specified property.
 * @param object        The object which the current object is about to be attached to.
 * @param propertyName  The name of the property on _object_ that the current object is being
 * attached to.
 */
- (void)notifyIOCObject:(id)object propertyName:(NSString *)propertyName;

@end
