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
//  Created by Julian Goacher on 28/09/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFContentAuthority.h"
#import "IFCommandScheduler.h"
#import "IFHTTPClient.h"
#import "IFIOCTypeInspectable.h"
#import "IFIOCSingleton.h"

/**
 * A provider of content to the content: URL protocol.
 * A content provider is a collection of content authorities, which encapsulate different
 * sources of content.
 */
@interface IFContentProvider : NSObject <IFIOCSingleton, IFIOCTypeInspectable>

/// A map of content authority instances keyed by authority name.
@property (nonatomic, strong) NSDictionary *authorities;
/// A command scheduler to be used by the different content authorities.
@property (nonatomic, strong) IFCommandScheduler *commandScheduler;
/// An HTTP client to be used by the different content authorities.
@property (nonatomic, strong) IFHTTPClient *httpClient;
/// A path for temporarily staging downloaded content.
@property (nonatomic, strong) NSString *stagingPath;
/// A path for caching app content.
@property (nonatomic, strong) NSString *appCachePath;
/// A path for caching downloaded content.
@property (nonatomic, strong) NSString *contentCachePath;
/// A path for app packaged content.
@property (nonatomic, strong) NSString *packagedContentPath;

/// Find a content authority by name, or return nil of no match found.
- (id<IFContentAuthority>)contentAuthorityForName:(NSString *)name;

/// Return the singleton instance of this class.
+ (IFContentProvider *)getInstance;

@end
