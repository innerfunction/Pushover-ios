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
//  Created by Julian Goacher on 27/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFFormOptionField.h"
#import "IFFormView.h"

@implementation IFFormOptionField

- (id)init {
    self = [super init];
    if (self) {
        self.isInput = YES;
    }
    return self;
}

- (void)setOptionSelected:(BOOL)optionSelected {
    _optionSelected = optionSelected;
    self.value = optionSelected ? self.optionValue : nil;
    dispatch_async(dispatch_get_main_queue(), ^{
         self.accessoryType = _optionSelected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    });
}

- (void)setOptionValue:(NSString *)optionValue {
    _optionValue = optionValue;
    if (_optionSelected) {
        self.value = optionValue;
    }
}

- (BOOL)isSelectable {
    return YES;
}

- (void)selectField {
    NSArray *fieldGroup = [self.form getFieldsInNameGroup:self.name];
    for (IFFormOptionField *field in fieldGroup) {
        field.optionSelected = NO;
        field.value = nil;
    }
    self.optionSelected = YES;
}

@end
