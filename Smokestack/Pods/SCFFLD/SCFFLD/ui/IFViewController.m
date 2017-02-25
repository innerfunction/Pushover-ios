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

#import "IFViewController.h"
#import "IFAppContainer.h"
#import "UIViewController+Toast.h"
#import "UIViewController+ImageView.h"

@implementation IFViewController

@synthesize iocContainer = _iocContainer, behaviours = _behaviours;

- (id)init {
    self = [super init];
    if (self) {
        _hideTitleBar = NO;
        _namedViews = @{};
        _actionProxyLookup = [NSMutableDictionary new];
        _behaviours = @[];
        _useAutoLayout = YES;
        _logger = [[IFLogger alloc] initWithTag:@"IFViewController"];
    }
    return self;
}

- (id)initWithView:(UIView *)view {
    self = [self init];
    if (self) {
        self.view = view;
    }
    return self;
}

#pragma mark - IFIOCConfigurationAware protocol

- (void)beforeIOCConfiguration:(IFConfiguration *)configuration {
    _layoutName = [configuration getValueAsString:@"layoutName" defaultValue:_layoutName];
    [self loadLayout];
}

- (void)afterIOCConfiguration:(IFConfiguration *)configuration {
    [self replaceViewPlaceholders];
}

#pragma mark - IFViewBehaviourController protocol

- (void)setBehaviour:(id<IFViewBehaviour>)behaviour {
    if (behaviour != nil) {
        self.behaviours = @[ behaviour ];
    }
}

- (id<IFViewBehaviour>)behaviour {
    return [self.behaviours firstObject];
}

- (void)setBehaviours:(NSArray *)behaviours {
    _behaviours = behaviours;
    for (id<IFViewBehaviour> behaviour in _behaviours) {
        behaviour.viewController = self;
    }
}

- (void)addBehaviour:(id<IFViewBehaviour>)behaviour {
    if (behaviour) {
        _behaviours = [_behaviours arrayByAddingObject:behaviour];
    }
}

#pragma mark - Lifecycle methods

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = _hideTitleBar;
    [super viewWillAppear:animated];
    if (_backButtonTitle) {
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:_backButtonTitle
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:nil
                                                                                action:nil];
    }
    if (_leftTitleBarButton) {
        self.navigationItem.leftBarButtonItem = _leftTitleBarButton;
    }
    if (_rightTitleBarButton) {
        self.navigationItem.rightBarButtonItem = _rightTitleBarButton;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    for (id<IFViewBehaviour> behaviour in _behaviours) {
        [behaviour viewDidAppear];
    }
}

#pragma mark - Instance methods

- (void)postMessage:(NSString *)message {
    [IFAppContainer postMessage:message sender:self];
}

#pragma mark - IFMessageReceiver protocol

- (BOOL)receiveMessage:(IFMessage *)message sender:(id)sender {
    for (id<IFViewBehaviour> behaviour in _behaviours) {
        if ([behaviour receiveMessage:message sender:sender]) {
            return YES;
        }
    }
    if ([message hasName:@"toast"]) {
        NSString *toastMessage = [message parameterValue:@"message"];
        if (toastMessage) {
            [self showToastMessage:toastMessage];
        }
        return YES;
    }
    if ([message hasName:@"show-image"]) {
        NSString *url = [message parameterValue:@"url"];
        if (url) {
            [self showImageAtURL:[NSURL URLWithString:url] referenceView:self.view];
        }
    }
    return NO;
}

#pragma mark - IFMessageRouter

- (BOOL)routeMessage:(IFMessage *)message sender:(id)sender {
    BOOL routed = NO;
    id targetName = [message targetHead];
    id targetView = _namedViews[targetName];
    if (!targetView) {
        @try {
            targetView = [self valueForKey:targetName];
        }
        @catch(id ex) {
            // targetName property not found
        }
    }
    if (targetView) {
        message = [message popTargetHead];
        if ([message hasEmptyTarget]) {
            if ([targetView conformsToProtocol:@protocol(IFMessageReceiver)]) {
                routed = [(id<IFMessageReceiver>)targetView receiveMessage:message sender:sender];
            }
        }
        else if ([targetView conformsToProtocol:@protocol(IFMessageRouter)]) {
            routed = [(id<IFMessageRouter>)targetView routeMessage:message sender:sender];
        }
    }
    return routed;
}

#pragma mark - IFActionProxy

- (void)registerAction:(NSString *)action forObject:(id)object {
    NSValue *key = [NSValue valueWithNonretainedObject:object];
    _actionProxyLookup[key] = action;
}

- (void)postActionForObject:(id)object {
    NSValue *key = [NSValue valueWithNonretainedObject:object];
    NSString *action = _actionProxyLookup[key];
    if (action) {
        [self postMessage:action];
    }
}

#pragma mark - Key-Value coding

- (void)setValue:(id)value forKey:(NSString *)key {
    // The layout will use this method when passing view instances to their referencing
    // outlets.
    // (See https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/LoadingResources/CocoaNibs/CocoaNibs.html#//apple_ref/doc/uid/10000051i-CH4-SW19)
    // Use this to keep track of view placeholders.
    if (_loadingLayout) {
        [_namedViewPlaceholders setObject:value forKey:key];
    }
    [super setValue:value forKey:key];
}

#pragma mark - private

- (void)loadLayout {
    // If no view already specified and a layout name has been specified then load the nib file of
    // that name.
    if (_layoutName) {
        _namedViewPlaceholders = [NSMutableDictionary new];
        _loadingLayout = YES;
        NSArray *result = [[NSBundle mainBundle] loadNibNamed:_layoutName owner:self options:nil];
        if (![result count]) {
            [_logger warn:@"Failed to load layout from %@.xib", _layoutName];
        }
        else {
            self.view = result[0];
        }
        _loadingLayout = NO;
    }
}

- (void)replaceViewPlaceholders {
    for (NSString *name in _namedViewPlaceholders) {
        id view = [_namedViews objectForKey:name];
        if (!view) {
            view = [self valueForKey:name];
        }
        if (view) {
            UIView *placeholder = [_namedViewPlaceholders objectForKey:name];
            // Replace the placeholder with the named view.
            if ([view isKindOfClass:[UIView class]]) {
                [self replaceSubview:placeholder withView:view];
            }
            else if ([view isKindOfClass:[UIViewController class]]) {
                UIViewController *controller = (UIViewController *)view;
                [self addChildViewController:controller];
                [self replaceSubview:placeholder withView:controller.view];
            }
            else {
                [_logger warn:@"Named view '%@' has non-view class '%@'", name, [view class]];
            }
        }
        else {
            [_logger warn:@"No placeholder for named view '%@'", name];
        }
    }
    // Discard the placeholder views.
    _namedViewPlaceholders = nil;
}

- (void)replaceSubview:(UIView *)subView withView:(UIView *)newView {
    // Copy frame and bounds
    newView.frame = subView.frame;
    newView.bounds = subView.bounds;
    if (!_useAutoLayout) {
        // Copy layout params to the new view
        newView.autoresizingMask = subView.autoresizingMask;
        newView.autoresizesSubviews = subView.autoresizesSubviews;
    }
    newView.contentMode = subView.contentMode;
    UIView *superview = subView.superview;
    NSArray *newConstraints = nil;
    if (_useAutoLayout) {
        newConstraints = removeConstraintsOnView(self.view, subView, newView);
    }
    // Swap the views & update the constraints.
    NSUInteger idx = [superview.subviews indexOfObject:subView];
    [subView removeFromSuperview];
    [superview insertSubview:newView atIndex:idx];
    if (_useAutoLayout) {
        for (NSArray *item in newConstraints) {
            UIView *view = item[0];
            NSArray *constraints = item[1];
            [view addConstraints:constraints];
        }
    }
}

// Copy constraints
// See http://stackoverflow.com/a/31785898
NSArray *removeConstraintsOnView(UIView *view, UIView *oldView, UIView *newView) {
    NSMutableArray *obsConstraints = [NSMutableArray new];
    NSMutableArray *newConstraints = [NSMutableArray new];
    for (NSLayoutConstraint *c0 in view.constraints) {
        NSLayoutConstraint *c1 = c0;
        if (c0.firstItem == oldView) {
            c1 = [NSLayoutConstraint constraintWithItem:newView
                                              attribute:c0.firstAttribute
                                              relatedBy:c0.relation
                                                 toItem:c0.secondItem
                                              attribute:c0.secondAttribute
                                             multiplier:c0.multiplier
                                               constant:c0.constant];
        }
        if (c0.secondItem == oldView) {
            c1 = [NSLayoutConstraint constraintWithItem:c1.firstItem
                                              attribute:c1.firstAttribute
                                              relatedBy:c1.relation
                                                 toItem:newView
                                              attribute:c1.secondAttribute
                                             multiplier:c1.multiplier
                                               constant:c1.constant];
        }
        if (c1 != c0) {
            [obsConstraints addObject:c0];
            [newConstraints addObject:c1];
        }
    }
    [view removeConstraints:obsConstraints];
    // Which view will the new constraints be added to? If the old view then switch to the new view.
    UIView *objView = (view == oldView) ? newView : view;
    NSArray *result = @[ @[ objView, newConstraints ] ];
    for (UIView *subView in view.subviews) {
        result = [result arrayByAddingObjectsFromArray:removeConstraintsOnView(subView, oldView, newView)];
    }
    return result;
}

@end
