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

@interface IFCMSLoginFormViewController ()

@end

@implementation IFCMSLoginFormViewController

- (id)init {
    self = [super init];
    if (self) {
        __block IFCMSLoginFormViewController *this = self;
        IFFormView *form = self.form;
        form.onSubmit = ^(IFFormView *form, NSDictionary *values) {
            IFContentProvider *provider = [IFContentProvider getInstance];
            id authority = [provider contentAuthorityForName:this.authority];
            if ([authority isKindOfClass:[IFCMSContentAuthority class]]) {
                IFCMSContentAuthority *cmsAuthority = (IFCMSContentAuthority *)authority;
                [form submitting:YES];
                [cmsAuthority loginWithCredentials:values]
                .then( (id)^(BOOL ok) {
                    [form submitting:NO];
                    [this postMessage:this.onlogin];
                    return nil;
                })
                .fail( ^(id err) {
                    [form submitting:NO];
                    // Show toast message.
                });
            }
        };
    }
    return self;
}

@end
