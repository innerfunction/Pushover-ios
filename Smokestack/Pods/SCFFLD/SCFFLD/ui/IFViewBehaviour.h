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
//  Created by Julian Goacher on 12/03/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IFMessageReceiver.h"

/**
 * A protocol to be implemented by view behaviours.
 * A view behaviour allows a view controller to be decorated with additional functionality.
 */
@protocol IFViewBehaviour <IFMessageReceiver>

/// The view controller the behaviour is attached to.
@property (nonatomic, weak) UIViewController *viewController;

/// Method called when the attached view controller appears.
- (void)viewDidAppear;

@end

/**
 * A protocol for view controllers capable of having their behaviour decorated.
 */
@protocol IFViewBehaviourController <NSObject>

/// Configure a list of attached view behaviours.
@property (nonatomic, strong) NSArray *behaviours;
/// Configure a single view behaviour.
@property (nonatomic, strong) id<IFViewBehaviour> behaviour;

/// Add a new behaviour to the list of behaviours.
- (void)addBehaviour:(id<IFViewBehaviour>)behaviour;

@end