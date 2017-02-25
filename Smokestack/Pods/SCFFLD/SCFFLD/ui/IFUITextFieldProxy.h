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

#import <Foundation/Foundation.h>
#import "IFIOCProxyObject.h"
#import "IFTextStyle.h"

/**
 * A configuration proxy for UITextField instances.
 */
@interface IFUITextFieldProxy : IFIOCProxyObject {
    /// The text field being configured.
    UITextField *_textField;
}

/// Configure the input field's text value.
@property (nonatomic, strong) NSString *text;
/// Configure the input field's styles.
@property (nonatomic, strong) IFTextStyle *style;
/**
 * Configure the input field's keyboard type.
 * Values are:
 * - default
 * - web
 * - number
 * - phone
 * - email
 */
@property (nonatomic, strong) NSString *keyboard;
/**
 * Configure the input field's auto-capitalization style:
 * - none
 * - word
 * - sentences
 * - all
 */
@property (nonatomic, strong) NSString *autocapitalization;
/// Flag for configuring whether to auto-correct entered text.
@property (nonatomic, assign) BOOL autocorrection;

@end
