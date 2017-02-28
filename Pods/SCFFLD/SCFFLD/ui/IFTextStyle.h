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
//  Created by Julian Goacher on 17/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * A configuration wrapper for UI elements which display text.
 */
@interface IFTextStyle : NSObject

/// Set the text's font name.
@property (nonatomic, strong) NSString *fontName;
/// Set the size of the text.
@property (nonatomic, strong) NSNumber *fontSize;
/// Set the text colour.
@property (nonatomic, strong) UIColor *textColor;
/// Set the text's background colour.
@property (nonatomic, strong) UIColor *backgroundColor;
/// Set the text's alignment. Values are 'left' 'center' 'right'.
@property (nonatomic, strong) NSString *textAlign;
/// A flag indicating whether to bold the text.
@property (nonatomic, assign) BOOL bold;
/// A flag indicating whether to display the text in italic.
@property (nonatomic, assign) BOOL italic;

/// Apply the text style to a label.
- (void)applyToLabel:(UILabel *)label;
/// Apply the text style to an input field.
- (void)applyToTextField:(UITextField *)textField;

@end
