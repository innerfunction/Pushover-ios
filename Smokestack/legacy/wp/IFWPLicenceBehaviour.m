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

#import "IFWPLicenceBehaviour.h"
#import "IFAppContainer.h"

@interface IFWPLicenceMessageBehaviour : IFViewBehaviourObject {
    __weak IFWPLicenceBehaviour *_parentBehaviour;
}

- (id)initWithParentBehaviour:(IFWPLicenceBehaviour *)parentBehaviour;

@end

@interface IFWPLicenceBehaviour()

- (NSString *)getUsername;

@end

@implementation IFWPLicenceBehaviour

- (id)init {
    self = [super init];
    if (self) {
        _locals = [NSUserDefaults standardUserDefaults];
        _localsKey = @"licenceAccepted";
    }
    return self;
}

- (void)setLicenceView:(UIViewController *)licenceView {
    _licenceView = licenceView;
    // NOTE: The policy view must implement the IFViewBehaviourController protocol.
    if ([licenceView conformsToProtocol:@protocol(IFViewBehaviourController)]) {
        // Add the message handling behaviour to the policy view.
        id<IFViewBehaviour> behaviour = [[IFWPLicenceMessageBehaviour alloc] initWithParentBehaviour:self];
        [(id<IFViewBehaviourController>)licenceView addBehaviour:behaviour];
    }
}

- (void)viewDidAppear {
    NSString *licenceAcceptedBy = [_locals stringForKey:_localsKey];
    BOOL licenceAccepted = [licenceAcceptedBy isEqualToString:[self getUsername]];
    if (!licenceAccepted) {
        _licenceView.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        _licenceView.modalPresentationStyle = UIModalPresentationOverFullScreen;
        [self.viewController presentViewController:_licenceView animated:YES completion:^{}];
    }
}

- (BOOL)receiveMessage:(IFMessage *)message sender:(id)sender {
    if ([message hasName:@"licence/accept"]) {
        NSString *username = [self getUsername];
        [_locals setObject:username forKey:_localsKey];
        [self.viewController dismissViewControllerAnimated:_licenceView completion:^{}];
        return YES;
    }
    if ([message hasName:@"licence/reject"]) {
        [_authManager logout];
        [self.viewController dismissViewControllerAnimated:_licenceView completion:^{
            [IFAppContainer postMessage:_rejectAction sender:self.viewController];
        }];
        return YES;
    }
    return NO;
}

#pragma mark - Private methods

- (NSString *)getUsername {
    NSString *username = [_authManager getUsername];
    if (!username) {
        username = @"<user>";
    }
    return username;
}

@end

@implementation IFWPLicenceMessageBehaviour

- (id)initWithParentBehaviour:(IFWPLicenceBehaviour *)parentBehaviour {
    self = [super init];
    if (self) {
        _parentBehaviour = parentBehaviour;
    }
    return self;
}

- (BOOL)receiveMessage:(IFMessage *)message sender:(id)sender {
    return [_parentBehaviour receiveMessage:message sender:sender];
}

@end
