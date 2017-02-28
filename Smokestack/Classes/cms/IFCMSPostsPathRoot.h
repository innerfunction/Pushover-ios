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
//  Created by Julian Goacher on 30/09/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFCMSFilesetCategoryPathRoot.h"

/// A path root providing post content.
@interface IFCMSPostsPathRoot : IFCMSFilesetCategoryPathRoot

/**
 * Render a post's full HTML content.
 * Combines a post's body HTML with the appropriate client-side template to
 * generate the full HTML page.
 */
- (NSString *)renderPostContent:(NSDictionary *)postData;

@end
