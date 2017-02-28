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
//  Created by Julian Goacher on 11/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IFIOCContainerAware.h"
#import "IFIOCConfigurationAware.h"
#import "IFMessageReceiver.h"
#import "IFMessageRouter.h"
#import "IFActionProxy.h"
#import "IFViewBehaviour.h"
#import "IFLogger.h"

/**
 * A configurable version of the _UIViewController_ class.
 * Implements the <IFMessageReceiver> protocol and responds to the following messages:
 * - _toast_: Display an Android style popup message. Must have a _message_ parameter.
 * - _show-image_: Display an image in a pop-over view. Must have an _image_ parameter.
 *
 * This class supports loading of view layouts from XIB files, and configuration of view
 * components contained by such layouts. This can be done in a couple of ways.
 *
 * Method one utilizes the container's ability to perform configuration of in-place
 * property values. To use this method, this class should be subclassed with new properties
 * representing the configurable view components. The properties should be marked using the
 * IBOutlet attribute and then be used as referencing outlets within the XIB. When the
 * new view controller class is instantiated by a container, the layout will be loaded and
 * the view components mapped to their respective properties before the container performs
 * its IOC configuration on the controller instance, at which point it can inject any
 * additional configuration values into the view component properties.
 *
 * The second method involves creating empty views as placeholders within the layout, and
 * mapping these placeholders to named referencing outlets. The actual view instances can
 * then be defined under the _namedViews_ collection property of the controller. After the
 * layout is loaded, the controller will look for placeholders for each of its named views,
 * and replace each placeholder with the named view instance. This can be done for both
 * UIView and UIViewController instances. This second method doesn't necessarily require
 * this class to be subclassed, so long as the referencing outlets are named appropriately
 * in the layout file.
 */
@interface IFViewController : UIViewController <IFIOCContainerAware, IFIOCConfigurationAware, IFMessageReceiver, IFMessageRouter, IFActionProxy, IFViewBehaviourController> {
    NSMutableDictionary *_actionProxyLookup;
    BOOL _loadingLayout;
    NSMutableDictionary *_namedViewPlaceholders;
    IFLogger *_logger;
}

/** Flag indicating whether to show or hide the title bar. */
@property (nonatomic, assign) BOOL hideTitleBar;
/** The title of the view's back button when presented within a navigation controller. */
@property (nonatomic, strong) NSString *backButtonTitle;
/** An optional left-side title bar item. */
@property (nonatomic, strong) UIBarButtonItem *leftTitleBarButton;
/** An optional right-side title bar item. */
@property (nonatomic, strong) UIBarButtonItem *rightTitleBarButton;
/**
 * The layout name. Corresponds to the name of a nib file. If specified then the view controller will load and display
 * the layout.
 */
@property (nonatomic, strong) NSString *layoutName;
/**
 * Map of named view components. Allows placeholder elements within the layout to be replaced with components
 * built from the configurations described in this map.
 */
@property (nonatomic, strong) NSDictionary *namedViews;
/// Flag indicating whether the layout uses auto-layout.
@property (nonatomic, assign) BOOL useAutoLayout;

- (id)initWithView:(UIView *)view;
/// Post a message.
- (void)postMessage:(NSString *)message;
/**
 * Load the view's layout. The object should be configured with a _layoutName_ value, which it will use
 * as the name of a XIB file to load the layout from.
 */
- (void)loadLayout;
/**
 * Replace any view placeholders in the layout with views instantiated by the container.
 */
- (void)replaceViewPlaceholders;
/// Replace one of the view's subviews with a new view.
- (void)replaceSubview:(UIView *)view withView:(UIView *)view;

@end
