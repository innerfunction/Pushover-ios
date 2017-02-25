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

/// A protocol implemented by objects which can post actions for other objects.
@protocol IFActionProxy <NSObject>

/**
 * Register an action message which should be posted when the specified object requests.
 * @param action    The action message.
 * @param object    The object associated with the action message.
 */
- (void)registerAction:(NSString *)action forObject:(id)object;
/**
 * Post the registered action for the specified object.
 * @param object    An object previously registered by a call to [registerAction:forObject:];
 * the action proxy will then post the action message provided during registration.
 */
- (void)postActionForObject:(id)object;

@end
