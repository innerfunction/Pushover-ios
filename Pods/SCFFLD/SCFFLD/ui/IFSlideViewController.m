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

#import "IFSlideViewController.h"
#import "IFViewController.h"
#import "IFNavigationViewController.h"

@implementation IFSlideViewController

- (id)init {
    self = [super init];
    if (self) {
        self.slidePosition = @"left";
    }
    return self;
}

- (void)setSlideView:(id)slideView {
    if ([slideView isKindOfClass:[UIView class]]) {
        slideView = [[IFViewController alloc] initWithView:(UIView *)slideView];
    }
    if ([slideView isKindOfClass:[UIViewController class]]) {
        _slideView = slideView;
        self.rearViewController = slideView;
    }
}

- (void)setMainView:(id)mainView {
    if ([mainView isKindOfClass:[UIView class]]) {
        mainView = [[IFViewController alloc] initWithView:(UIView *)mainView];
    }
    if ([mainView isKindOfClass:[UIViewController class]]) {
        _mainView = mainView;
        self.frontViewController = mainView;
        //[self setFrontViewController:mainView animated:YES];
        
        // Set gesture receive on main view.
        if ([mainView isKindOfClass:[IFNavigationViewController class]]) {
            [(IFNavigationViewController *)mainView replaceBackSwipeGesture:self.panGestureRecognizer];
        }
        else {
            [((UIViewController *)mainView).view addGestureRecognizer:self.panGestureRecognizer];
        }
    }
}

- (void)setSlidePosition:(NSString *)slidePosition {
    if ([@"right" isEqualToString:slidePosition]) {
        slideOpenPosition = FrontViewPositionRight;
        slideClosedPosition = FrontViewPositionRightMostRemoved;
    }
    else {
        slideOpenPosition = FrontViewPositionLeft;
        slideClosedPosition = FrontViewPositionLeftSideMostRemoved;
    }
    self.frontViewPosition = slideOpenPosition;
}

#pragma mark - IFMessageRouter

- (BOOL)routeMessage:(IFMessage *)message sender:(id)sender {
    BOOL routed = NO;
    if ([message hasTarget:@"slide"]) {
        message = [message popTargetHead];
        if ([message hasEmptyTarget] && [self.slideView conformsToProtocol:@protocol(IFMessageReceiver)]) {
            routed = [(id<IFMessageReceiver>)self.slideView receiveMessage:message sender:sender];
        }
        else if ([self.slideView conformsToProtocol:@protocol(IFMessageRouter)]) {
            routed = [(id<IFMessageRouter>)self.slideView routeMessage:message sender:sender];
        }
    }
    else if ([message hasTarget:@"main"]) {
        message = [message popTargetHead];
        if ([message hasEmptyTarget] && [self.mainView conformsToProtocol:@protocol(IFMessageReceiver)]) {
            routed = [(id<IFMessageReceiver>)self.mainView receiveMessage:message sender:sender];
        }
        else if ([self.mainView conformsToProtocol:@protocol(IFMessageRouter)]) {
            routed = [(id<IFMessageRouter>)self.mainView routeMessage:message sender:sender];
        }
        self.frontViewPosition = slideClosedPosition;
    }
    return routed;
}

#pragma mark - IFMessageReceiver

- (BOOL)receiveMessage:(IFMessage *)message sender:(id)sender {
    // NOTE 'open' is deprecated. Note also other deprecations below.
    if ([message hasName:@"show"] || [message hasName:@"open"]) {
        // Replace main view.
        self.mainView = [message.parameters valueForKey:@"view"];
        return YES;
    }
    if ([message hasName:@"show-in-slide"] || [message hasName:@"open-in-slide"]) {
        // Replace the slide view.
        self.slideView = [message.parameters valueForKey:@"view"];
        return YES;
    }
    if ([message hasName:@"open-slide"] || [message hasName:@"show-slide"]) {
        // Open the slide view.
        self.frontViewPosition = slideOpenPosition;
        return YES;
    }
    if ([message hasName:@"close-slide"] || [message hasName:@"hide-slide"]) {
        // Close the slide view.
        self.frontViewPosition = slideClosedPosition;
        return YES;
    }
    if ([message hasName:@"toggle-slide"]) {
        [self revealToggleAnimated:YES];
        return YES;
    }
    return NO;
}

@end
