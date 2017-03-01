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
//  Created by Julian Goacher on 07/09/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFContentAuthority.h"
#import "IFIOCObjectAware.h"
#import "IFIOCConfigurationAware.h"
#import "IFIOCTypeInspectable.h"
#import "IFContainer.h"
#import "IFIOCProxyObject.h"
#import "IFJSONData.h"

// TODO Does this class need to extend IFContainer any more?

@interface IFCMSAbstractContentAuthorityConfigurationProxy : IFIOCProxyObject <IFIOCObjectAware>

/// The name of the authority that the class instance is bound to.
@property (nonatomic, strong) NSString *authorityName;
/// The path roots supported by this authority.
@property (nonatomic, strong) IFJSONObject *pathRoots;

@end

/**
 * An abstract content authority.
 * This class provides standard functionality needed to service requests from content URLs and URIs. It
 * automatically handles cancellation of NSURLProtocol requests. All requests are forwarded to the
 * [writeResponse: forAuthority: path: parameters:] method, and subclasses should override this method
 * with an implementation which resolves content data as appropriate for the request.
 */
@interface IFAbstractContentAuthority : IFContainer <IFContentAuthority, IFIOCTypeInspectable> {
    /// A set of live NSURL responses.
    NSMutableSet *_liveResponses;
}

/// The name of the authority that the class instance is bound to.
@property (nonatomic, strong) NSString *authorityName;
/// A map of addressable path roots. For example, given the path files/all, the path root is 'files'.
@property (nonatomic, strong) NSMutableDictionary *pathRoots;
/// A path for temporarily staging downloaded content.
@property (nonatomic, readonly) NSString *stagingPath;
/// A path for caching app content.
@property (nonatomic, readonly) NSString *appCachePath;
/// A property for caching downloaded content.
@property (nonatomic, readonly) NSString *contentCachePath;
/// A path for CMS content that has been packaged with the app.
@property (nonatomic, readonly) NSString *packagedContentPath;
/// Interval between content refreshes; in minutes.
@property (nonatomic, assign) CGFloat refreshInterval;

/**
 * Refreshed content, e.g. by checking a server for downloadable updates.
 * Subclasses should provide an implementation of this class.
 */
- (void)refreshContent;

@end
