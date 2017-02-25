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

#import "SWRevealViewController.h"
#import "IFMessageReceiver.h"
#import "IFMessageRouter.h"

/**
 * A configurable version of the _SWRevealViewController_ class. Can be used for example to display a screen
 * with a menu in a hidden view which slides out from the side.
 *
 * The class implements the _IFMessageReceiver_ protocol and responds to the following messages:
 * - _show_: Show a new view by replacing the view displayed in the screen's main area. The message must have
 * a _view_ parameter.
 * - _show-in-slide_: Show a new view in the slide area. The message must have a _view_ parameter.
 * - _open-slide_: Make the slide view visible.
 * - _close-slide_: Hide the slide view, if visible.
 * - _toggle-slide_: Toggle the slide view's visibility.
 *
 * The class implements the _IFMessageRouter_ protocol and provides the following targets, which
 * messages can be addressed to:
 * - _main_: The main view area.
 * - _slide_: The slide view area.
 */
@interface IFSlideViewController : SWRevealViewController <IFMessageReceiver, IFMessageRouter> {
    FrontViewPosition slideOpenPosition;
    FrontViewPosition slideClosedPosition;
}

/** Configure the slide view. */
@property (nonatomic, strong) id slideView;
/** Configure the main view. */
@property (nonatomic, strong) id mainView;
/** The position of the slide view. Values can be "left" or "right". */
@property (nonatomic, strong) NSString *slidePosition;

@end
