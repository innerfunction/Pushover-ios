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
//  Created by Julian Goacher on 29/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "UIViewController+ImageView.h"
#import "JTSImageInfo.h"
#import "JTSImageViewController.h"

@implementation UIViewController (ImageView)

- (void)showImageAtURL:(NSURL *)url referenceView:(UIView *)refView {
    // Create image info
    JTSImageInfo *imageInfo = [JTSImageInfo new];
    imageInfo.imageURL = url;
    imageInfo.referenceRect = refView.frame;
    imageInfo.referenceView = refView.superview;
    
    // Setup view controller
    JTSImageViewController *imageViewer = [[JTSImageViewController alloc] initWithImageInfo:imageInfo
                                                                                       mode:JTSImageViewControllerMode_Image
                                                                            backgroundStyle:JTSImageViewControllerBackgroundOption_Scaled];
    imageViewer.modalPresentationStyle = UIModalPresentationOverFullScreen;
    // Present the view controller.
    [imageViewer showFromViewController:self transition:JTSImageViewControllerTransition_FromOriginalPosition];
}

- (void)showImage:(UIImage *)image referenceView:(UIView *)refView {
    // Create image info
    JTSImageInfo *imageInfo = [JTSImageInfo new];
    imageInfo.image = image;
    imageInfo.referenceRect = refView.frame;
    imageInfo.referenceView = refView.superview;
    
    // Setup view controller
    JTSImageViewController *imageViewer = [[JTSImageViewController alloc] initWithImageInfo:imageInfo
                                                                                       mode:JTSImageViewControllerMode_Image
                                                                            backgroundStyle:JTSImageViewControllerBackgroundOption_Scaled];
    
    // Present the view controller.
    [imageViewer showFromViewController:self transition:JTSImageViewControllerTransition_FromOriginalPosition];
}

@end
