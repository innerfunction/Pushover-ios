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
//  Created by Julian Goacher on 22/10/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IFMessageReceiver.h"

/**
 * A configurable navigation view controller.
 * The class implements the IFMessageReceiver protocol and respond to the following messages:
 * - _show_: Show a view by pushing onto the navigation stack. The message must have a _view_ parameter.
 * - _back_: Navigate back to the previous view on the navigation stack.
 * - _home_: Navigate back to the root view on the navigation stack.
 */
@interface IFNavigationViewController : UINavigationController <IFMessageReceiver> {
    UIPanGestureRecognizer *_panGestureRecognizer;
}

/** Configure the first view in the navigation stack. */
@property (nonatomic, strong) UIViewController *rootView;
/** Configure the title (navigation) bar background colour. */
@property (nonatomic, strong) UIColor *titleBarColor;
/** Configure the title (navigation) bar text colour. */
@property (nonatomic, strong) UIColor *titleTextColor;

/**
 * Replace the back swipe gesture with some other gesture.
 * Used e.g. by the slide view controller so that the pan gesture can be used to show the slide menu.
 */
- (void)replaceBackSwipeGesture:(UIPanGestureRecognizer *)recognizer;

@end
