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
//  Created by Julian Goacher on 25/11/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFCMSLoginFormViewController.h"
#import "IFContentProvider.h"
#import "IFCMSContentAuthority.h"
#import "UIViewController+Toast.h"

@interface IFCMSLoginFormViewController ()

- (IFCMSContentAuthority *)getContentAuthority;

@end

@implementation IFCMSLoginFormViewController

- (id)init {
    self = [super init];
    if (self) {
        __block IFCMSLoginFormViewController *this = self;
        IFFormView *form = self.form;
        form.onSubmit = ^(IFFormView *form, NSDictionary *values) {
            IFCMSContentAuthority *authority = [this getContentAuthority];
            if (authority) {
                [form submitting:YES];
                [authority loginWithCredentials:values]
                .then( (id)^(BOOL ok) {
                    [form submitting:NO];
                    [this postMessage:this.onlogin];
                    return nil;
                })
                .fail( ^(id err) {
                    [form submitting:NO];
                    [self showToastMessage:err];
                });
            }
        };
        
        _backgroundImageView = [UIImageView new];
        [self.view addSubview:_backgroundImageView];
        [self.view sendSubviewToBack:_backgroundImageView];
    }
    return self;
}

- (void)setBackgroundImage:(UIImage *)backgroundImage {
    _backgroundImageView.image = backgroundImage;
}

- (UIImage *)backgroundImage {
    return _backgroundImageView.image;
}

#pragma mark - Overrides

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    _backgroundImageView.frame = self.view.bounds;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // Check whether the user is already logged in.
    IFCMSContentAuthority *authority = [self getContentAuthority];
    if ([authority isLoggedIn]) {
        if (_logout) {
            // Logout the current user.
            [authority logout]
            .then( (id)^(id arg) {
                if (_logoutMessage) {
                    [self showToastMessage:_logoutMessage];
                }
                return nil;
            });
        }
        else {
            // Perform the login action.
            [self postMessage:self.onlogin];
        }
    }
}

#pragma mark - private

- (IFCMSContentAuthority *)getContentAuthority {
    IFContentProvider *provider = [IFContentProvider getInstance];
    id authority = [provider contentAuthorityForName:self.authority];
    if ([authority isKindOfClass:[IFCMSContentAuthority class]]) {
        return (IFCMSContentAuthority *)authority;
    }
    return nil;
}

@end
