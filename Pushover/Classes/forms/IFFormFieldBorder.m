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

#import "IFFormFieldBorder.h"

#define BorderWidth(v,w)    (v > 0.0f ? v : (w > 0.0f ? w : 0.0f))

@implementation IFFormFieldBorder

- (id)initWithFormField:(IFFormField *)formField {
    self = [super init];
    if (self) {
        _formField = formField;
        _color = [UIColor blackColor];
        _width  = -1.0f;
        _top    = -1.0f;
        _bottom = -1.0f;
        _left   = -1.0f;
        _right  = -1.0f;
        _radius = 0.0f;
        _margin = 0.0f;
        _border = nil;
        _topBorder = nil;
        _bottomBorder = nil;
        _leftBorder = nil;
        _rightBorder = nil;
        _setup = NO;
    }
    return self;
}

- (void)layoutBorder {
    if (!_setup) {
        CALayer *layer = _formField.contentView.layer;
        if (_width > 0.0f && _top < 0.0f && _bottom < 0.0f && _left < 0.0f && _right < 0.0f) {
            // Set a continual border (i.e. all sides are the same width).
            _border = [CALayer layer];
            _border.borderWidth = _width;
            _border.borderColor = _color.CGColor;
            // NOTE that corner radius is only supported for a continual border.
            if (_radius) {
                _border.cornerRadius = _radius;
                _border.masksToBounds = YES;
            }
            [layer addSublayer:_border];
        }
        else {
            CGFloat top = BorderWidth(_top,_width);
            if (top > 0.0f) {
                _topBorder = [CALayer layer];
                _topBorder.backgroundColor = _color.CGColor;
                [layer addSublayer:_topBorder];
            }
            CGFloat bottom = BorderWidth(_bottom,_width);
            if (bottom > 0.0f) {
                _bottomBorder = [CALayer layer];
                _bottomBorder.backgroundColor = _color.CGColor;
                [layer addSublayer:_bottomBorder];
            }
            CGFloat left = BorderWidth(_left,_width);
            if (left > 0.0f) {
                _leftBorder = [CALayer layer];
                _leftBorder.backgroundColor = _color.CGColor;
                [layer addSublayer:_leftBorder];
            }
            CGFloat right = BorderWidth(_right,_width);
            if (right > 0.0f) {
                _rightBorder = [CALayer layer];
                _rightBorder.backgroundColor = _color.CGColor;
                [layer addSublayer:_rightBorder];
            }
        }
        _setup = YES;
    }
    CGRect frame = _formField.contentView.frame;
    if (_border) {
        _border.frame = CGRectInset(frame, _margin, _margin);
    }
    if (_topBorder) {
        _topBorder.frame = CGRectMake(frame.origin.x, frame.origin.y + _margin, frame.size.width, _top - 1.0f);
    }
    if (_bottomBorder) {
        _bottomBorder.frame = CGRectMake(frame.origin.x, frame.size.height - _bottom - _margin, frame.size.width, _bottom - 1.0f);
    }
    if (_leftBorder) {
        _leftBorder.frame = CGRectMake(frame.origin.x + _margin, frame.origin.y, _left - 1.0f, frame.size.height);
    }
    if (_rightBorder) {
        _rightBorder.frame = CGRectMake(frame.origin.x + frame.size.width - _right - _margin, frame.origin.y, _right - 1.0f, frame.size.height);
    }
}

@end
