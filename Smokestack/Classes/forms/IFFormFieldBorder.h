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
//  Created by Julian Goacher on 06/12/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IFFormField.h"

@interface IFFormFieldBorder : NSObject {
    __weak IFFormField *_formField;
    CALayer *_border;
    CALayer *_topBorder;
    CALayer *_bottomBorder;
    CALayer *_leftBorder;
    CALayer *_rightBorder;
    BOOL _setup;
}

@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat top;
@property (nonatomic, assign) CGFloat bottom;
@property (nonatomic, assign) CGFloat left;
@property (nonatomic, assign) CGFloat right;
@property (nonatomic, assign) CGFloat radius;
@property (nonatomic, assign) CGFloat margin;

- (id)initWithFormField:(IFFormField *)formField;
- (void)layoutBorder;

@end
