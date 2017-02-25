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
//  Created by Julian Goacher on 11/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFContainer.h"
#import "IFDB.h"
#import "IFWPContentCommandProtocol.h"
#import "IFCommandScheduler.h"
#import "IFIOCContainerAware.h"
#import "IFIOCTypeInspectable.h"
#import "IFAbstractContentAuthority.h"
#import "IFWPContentAuthorityFormFactory.h"
#import "IFWPAuthManager.h"
#import "IFMessageReceiver.h"
#import "IFHTTPClient.h"
#import "IFJSONData.h"

@class IFWPClientTemplateContext;
@class IFWPPostDBAdapter;
@class IFWPPostsPathRoot;
@class IFWPSearchPathRoot;

@interface IFWPContentAuthority : IFAbstractContentAuthority <IFIOCContainerAware, IFMessageReceiver, IFIOCTypeInspectable> {
    // Container configuration template.
    IFConfiguration *_configTemplate;
    // Command scheduler for unpack and refresh operations.
    IFCommandScheduler *_commandScheduler;
    // Location for staging downloaded content prior to deployment.
    NSString *_stagingPath;
}

/** The name of the posts DB. */
@property (nonatomic, strong) NSString *postDBName;
/** The URL of the WP posts feed. */
@property (nonatomic, strong) NSString *feedURL;
/**
 * The URL of the content image pack.
 * Used when the app is first installed, to bulk download initial image content.
 */
@property (nonatomic, strong) NSString *imagePackURL;
/** The location of pre-packaged post content, relative to the installed app. */
@property (nonatomic, strong) NSString *packagedContentPath;
/** The location of base content. */
@property (nonatomic, strong) NSString *baseContentPath;
/** The location of downloaded post content once deployed. */
@property (nonatomic, strong) NSString *contentPath;
/** The WP realm name. Used for authentication, defaults to 'semo'. */
@property (nonatomic, strong) NSString *wpRealm;
/** Action to be posted when the container wants to show the login form. */
@property (nonatomic, strong) NSString *showLoginAction;
/** The posts DB instance. */
@property (nonatomic, strong) IFDB *postDB;
/** An adapter for the posts DB providing specific data access methods. */
@property (nonatomic, strong) IFWPPostDBAdapter *postDBAdapter;
/** Whether to reset the post DB on start. (Useful for debug). */
@property (nonatomic, assign) BOOL resetPostDB;
/** Interval in minutes between checks for content updates. */
@property (nonatomic, assign) NSInteger updateCheckInterval;
/** The content command protocol instance; manages feed downloads. */
@property (nonatomic, strong) IFWPContentCommandProtocol *contentCommandProtocol;
/** Post list data formats. */
@property (nonatomic, strong) NSDictionary *listFormats;
/** Post data formats. */
@property (nonatomic, strong) NSDictionary *postFormats;
/** Template for generating post URIs. See uriForPostWithID: */
@property (nonatomic, strong) NSString *postURITemplate;
/** Factory for producing login and account management forms. */
@property (nonatomic, strong, readonly) IFWPContentAuthorityFormFactory *formFactory;
/** Map of pre-defined post filters, keyed by name. */
@property (nonatomic, strong) NSDictionary *filters;
/** An object to use as the template context when rendering the client template for a post. */
@property (nonatomic, strong) IFWPClientTemplateContext *clientTemplateContext;
/** An object used to manage WP server authentication. */
@property (nonatomic, strong) IFWPAuthManager *authManager;
/** A HTTP client. */
@property (nonatomic, strong) IFHTTPClient *httpClient;
/** The maximum number of rows to return for wp:search results. */
@property (nonatomic, assign) NSInteger searchResultLimit;
/**
 * A map describing legal post-type relationships.
 * Allows legal child post types for a post type to be listed. Each map key is a parent post type,
 * and is mapped to either a child post type name (as a string), or a list of child post type names.
 * If a post type has no legal child post types then the type name should be mapped to an empty list.
 * Any post type not described in this property will allow any child post type.
 * Used by the getPostChildren: methods.
 */
@property (nonatomic, strong) IFJSONObject *postTypeRelations;

/** Unpack packaged content. */
- (void)unpackPackagedContent;

/** Refresh content. */
- (void)refreshContent;

/** Download content from the specified URL and store in the content location using the specified filename. */
- (void)getContentFromURL:(NSString *)url writeToFilename:(NSString *)filename;

/** Generate a URI to reference the post with the specified ID. */
- (NSString *)uriForPostWithID:(NSString *)postID;

/** Show the login form. */
- (void)showLoginForm;

@end
