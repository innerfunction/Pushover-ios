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
//  Created by Julian Goacher on 04/10/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFContentTypeConverter.h"
#import "IFCMSPostsPathRoot.h"

// TODO This formats as config, the table view version formats as data?

/// A content type converter which formats resource entry data as web view configuration.
@interface IFCMSWebViewContentTypeConverter : NSObject <IFContentTypeConverter>

@property (nonatomic, weak) IFCMSPostsPathRoot *postsPathRoot;

@end
