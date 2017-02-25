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
//  Created by Julian Goacher on 08/03/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IFIOCProxyObject.h"
#import "IFIOCObjectAware.h"

/**
 * Configuration proxy for UIBarButtonItem instances.
 */
@interface IFUIBarButtonItemProxy : IFIOCProxyObject <IFIOCObjectAware> {
    /// The bar button item being configured.
    UIBarButtonItem *_barButtonItem;
}

/// Configure the button's title.
@property (nonatomic, strong) NSString *title;
/// Configure the button's image.
@property (nonatomic, strong) UIImage *image;
/// Configure the action message which is sent when the button is tapped.
@property (nonatomic, strong) NSString *action;

@end
