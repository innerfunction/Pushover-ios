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

#import "IFFormImageField.h"

@implementation IFFormImageField

- (id)init {
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:IFFormFieldReuseID];
    if (self) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeCenter;
        [self addSubview:_imageView];
    }
    return self;
}

- (void)setImage:(UIImage *)image {
    _image = image;
    _imageView.image = image;
    self.height = [NSNumber numberWithFloat:image.size.height];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _imageView.frame = self.contentView.frame;
}

@end
