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
//  Created by Julian Goacher on 13/09/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFAbstractContentAuthority.h"
#import "IFCMSFileDB.h"
#import "IFCMSFilesetCategoryPathRoot.h"
#import "IFCMSCommandProtocol.h"
#import "IFCMSSettings.h"
#import "IFContentAuthManager.h"
#import "IFIOCObjectAware.h"
#import "IFIOCContainerAware.h"
#import "IFIOCConfigurationAware.h"
#import "IFMessageReceiver.h"
#import "IFJSONData.h"
#import "Q.h"

@class IFCMSPostsPathRoot;

// TODO Rename class group - and change class name prefix - to po / PO?

@interface IFCMSContentAuthorityConfigurationProxy : IFCMSAbstractContentAuthorityConfigurationProxy <IFIOCContainerAware, IFMessageReceiver>

/// The file database settings.
@property (nonatomic, strong) IFJSONObject *fileDB;
/// The CMS settings (host / account / repo).
@property (nonatomic, strong) NSDictionary *cms;
/// The content refresh interval, in minutes.
@property (nonatomic, assign) CGFloat refreshInterval;

@end

/**
 * A content authority which sources its content from a Pushover CMS
 */
@interface IFCMSContentAuthority : IFAbstractContentAuthority <IFService>

/// The file database.
@property (nonatomic, strong) IFCMSFileDB *fileDB;
/// The path root for 'posts'.
@property (nonatomic, strong) IFCMSPostsPathRoot *postsPathRoot;
/// The filesets defined for this authority.
@property (nonatomic, strong, readonly) NSDictionary *filesets;
/// The CMS settings (host / account / repo).
@property (nonatomic, strong) IFCMSSettings *cms;
/// A map of available content record type converters.
@property (nonatomic, strong) NSDictionary *recordTypes;
/// A map of available content query type converters.
@property (nonatomic, strong) NSDictionary *queryTypes;
/// The authority's scheduled command protocol.
@property (nonatomic, strong) IFCMSCommandProtocol *commandProtocol;
/// The authority's authentication manager.
@property (nonatomic, strong) IFContentAuthManager *authManager;

/**
 * Do a CMS login using the specified credentials.
 * The supplied dictionary should include username and password values.
 * The method does the following:
 * - Registers the credentials with the content authentication manager;
 * - Validates the credentials by performing a POST request on the CMS's /authenticate URI.
 * - Then performs a synchronous content refresh.
 */
- (QPromise *)loginWithCredentials:(NSDictionary *)credentials;

/// Test whether there is an active user login for this content authority.
- (BOOL)isLoggedIn;

/// Logout the active user.
- (QPromise *)logout;

@end
