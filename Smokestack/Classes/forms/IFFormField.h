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
//  Created by Julian Goacher on 12/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IFFormFieldPadding.h"

@class IFFormView;
@class IFFormFieldBorder;

#define IFFormFieldReuseID  (NSStringFromClass([self class]))

@interface IFFormField : UITableViewCell {
    CGFloat _displayHeight;
}

@property (nonatomic, weak) IFFormView *form;
@property (nonatomic, assign) BOOL isInput;
@property (nonatomic, readonly) BOOL isSelectable;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) id value;
@property (nonatomic, strong) NSString *selectAction;
@property (nonatomic, strong) NSNumber *height;
@property (nonatomic, strong) IFFormFieldPadding *padding;
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong) UIImage *backgroundImage;
@property (nonatomic, strong) UIImage *focusedBackgroundImage;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, readonly) UILabel *titleLabel;
@property (nonatomic, strong) NSArray *fieldGroup;
@property (nonatomic, strong) IFFormFieldBorder *border;

- (BOOL)takeFieldFocus;
- (void)releaseFieldFocus;
- (BOOL)validate;
- (void)selectField;
- (CGFloat)displayHeight;

@end
