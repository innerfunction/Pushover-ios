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

#import "IFUIBarButtonItemProxy.h"
#import "IFActionProxy.h"
#import "IFContainer.h"

@implementation IFUIBarButtonItemProxy

- (id)init {
    self = [super init];
    if (self) {
        _barButtonItem = [[UIBarButtonItem alloc] initWithTitle:nil
                                                          style:UIBarButtonItemStylePlain
                                                         target:nil
                                                         action:nil];
    }
    return self;
}

- (id)initWithValue:(id)value {
    self = [super init];
    if (self) {
        _barButtonItem = (UIBarButtonItem *)value;
    }
    return self;
}

- (void)setTitle:(NSString *)title {
    _barButtonItem.title = title;
}

- (NSString *)title {
    return _barButtonItem.title;
}

- (void)setImage:(UIImage *)image {
    _barButtonItem.image = image;
}

- (UIImage *)image {
    return _barButtonItem.image;
}

#pragma mark - IFIOCProxy

- (id)unwrapValue {
    return _barButtonItem;
}

#pragma mark - IFIOCObjectAware

- (void)notifyIOCObject:(id)object propertyName:(NSString *)propertyName {
    // If the button has an action specified and the parent object is an action proxy,
    // then register the buttons action with the proxy and target the proxy when the
    // button is tapped.
    if (_action && [object conformsToProtocol:@protocol(IFActionProxy)]) {
        id<IFActionProxy> actionProxy = (id<IFActionProxy>)object;
        [actionProxy registerAction:_action forObject:_barButtonItem];
        _barButtonItem.target = actionProxy;
        _barButtonItem.action = @selector(postActionForObject:);
    }
}

#pragma mark - Class loading

+ (void)load {
    [IFIOCProxyObject registerConfigurationProxyClass:self forClassName:@"UIBarButtonItem"];
}

@end
