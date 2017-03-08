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
//  Created by Julian Goacher on 01/03/2017.
//  Copyright © 2017 InnerFunction. All rights reserved.
//

#import "IFContentAppContainer.h"
#import "IFContentSchemeHandler.h"
#import "IFCoreTypes.h"
#import "NSDictionary+IF.h"

@implementation IFContentAppContainer

- (id)init {
    self = [super init];
    if (self) {
        // Add a content: scheme handler.
        [_appURIHandler addHandler:[IFContentSchemeHandler new] forScheme:@"content"];
    }
    return self;
}

#pragma mark - Static overrides

static IFContentAppContainer *IFContentAppContainer_instance;

+ (IFAppContainer *)getAppContainer {
    if (IFContentAppContainer_instance == nil) {
        IFContentAppContainer_instance = [IFContentAppContainer new];
        [IFContentAppContainer_instance loadConfiguration:@{
            @"types":       @"@app:/SCFFLD/types.json",
            @"schemes":     @"@dirmap:/SCFFLD/schemes",
            @"patterns":    @"@dirmap:/SCFFLD/patterns",
            @"nameds":      @"@dirmap:/SCFFLD/nameds",
            @"contentProvider": @{
                @"authorities":  @"@dirmap:/SCFFLD/cas"
            }
        }];
        [IFContentAppContainer_instance startService];
    }
    return IFContentAppContainer_instance;
}

+ (UIWindow *)window {
    UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    IFAppContainer *container = [IFContentAppContainer getAppContainer];
    container.window = window;
    return window;
}
@end
