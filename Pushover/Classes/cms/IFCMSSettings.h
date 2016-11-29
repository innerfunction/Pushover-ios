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
////  Created by Julian Goacher on 20/10/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>

/// A class representing a Pushover content repository's settings.
@interface IFCMSSettings : NSObject

/// The CMS host name.
@property (nonatomic, strong) NSString *host;
/// The CMS account name.
@property (nonatomic, strong) NSString *account;
/// The CMS repo name.
@property (nonatomic, strong) NSString *repo;
/// The CMS branch name.
@property (nonatomic, strong) NSString *branch;
/// The CMS HTTP authentication realm.
@property (nonatomic, strong) NSString *authRealm;
/// The CMS path root;
@property (nonatomic, strong) NSString *pathRoot;

/// Return the URL for login authentication.
- (NSString *)urlForAuthentication;
/// Return the URL for the updates feed.
- (NSString *)urlForUpdates;
/// Return the URL for downloading a fileset of the specified category.
- (NSString *)urlForFileset:(NSString *)category;
/// Return the URL for downloading a file at the specified path.
- (NSString *)urlForFile:(NSString *)path;
// Get the API's base URL. Used as the HTTP authentication protection space.
- (NSString *)apiBaseURL;

@end
