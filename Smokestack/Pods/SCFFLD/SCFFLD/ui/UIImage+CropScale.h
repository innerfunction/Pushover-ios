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
//  Created by Julian Goacher on 13/04/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//
#import <UIKit/UIKit.h>

/**
 * A category providing utility methods for cropping and scaling an image.
 */
@interface UIImage (CropScale)

/// Crop the image to the specified rectangle.
- (UIImage *)crop:(CGRect)rect;
/// Crop the image to the specified height, but keep its current width.
- (UIImage *)cropToHeight:(CGFloat)height;
/// Scale the image to fit the specified size.
- (UIImage *)scale:(CGSize)size;
/// Scale the image to fit the specified width, preserving the image's aspect ratio.
- (UIImage *)scaleToWidth:(CGFloat)width;
/// Scale the image to fit the specified width and height.
- (UIImage *)scaleToWidth:(CGFloat)width height:(CGFloat)height;

@end
