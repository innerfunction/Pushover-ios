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

#import "IFFormViewController.h"

@interface IFCMSLoginFormViewController : IFFormViewController {
    UIImageView *_backgroundImageView;
}

/// The name of the content authority the form is being used to login to.
@property (nonatomic, strong) NSString *authority;
/// An action to be posted after a successful login.
@property (nonatomic, strong) NSString *onlogin;
/**
 * A flag indicating that the current user should be logged out when the form is displayed.
 * This is used as part of the UI logout functionality.
 */
@property (nonatomic, assign) BOOL logout;
/// A message to be displayed after logout.
@property (nonatomic, strong) NSString *logoutMessage;
/// A background image for the view controller.
@property (nonatomic, strong) UIImage *backgroundImage;

@end
