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

#import "IFPendingNamed.h"

@implementation IFPendingNamed

- (void)setObject:(id)object {
    _object = object;
    _objectKey = [NSValue valueWithNonretainedObject:_object];
}

- (BOOL)hasWaitingConfigurer {
    return (_configurer != nil);
}

- (id)completeWithValue:(id)value {
    // If a reference path is set then use it to fully resolve the pending value on the named object.
    if (_referencePath) {
        if ([value respondsToSelector:@selector(valueForKeyPath:)]) {
            value = [value valueForKeyPath:_referencePath];
        }
        else {
            value = nil;
        }
    }
    [_configurer injectIntoObject:_object value:value intoProperty:_key propInfo:_propInfo];
    // IMPORTANT release unneeded refs.
    _object = nil;
    _propInfo = nil;
    return value;
}

@end
