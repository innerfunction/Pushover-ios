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
#import "IFContentContainer.h"

/**
 * A class providing functionality for writing responses to content URL and URI requests.
 */
@protocol IFContentContainerResponse <NSObject>

/**
 * Respond with content data.
 * Writes the full response and then closes the response.
 */
- (void)respondWithMimeType:(NSString *)mimeType cacheStoragePolicy:(NSURLCacheStoragePolicy)policy data:(NSData *)data;
/// Start a content response. Note that the [done] method must be called on completion.
- (void)respondWithMimeType:(NSString *)mimeType cacheStoragePolicy:(NSURLCacheStoragePolicy)policy;
/**
 * Write content data to the response.
 * The response must be started with a call to the [respondWithMimeType: cacheStoragePolicy:] method before
 * this method is called. This method may then be called as many times as necessary to write the content data
 * in full. The [done] method must be called once all data is written.
 */
- (void)sendData:(NSData *)data;
/// End a content response.
- (void)done;

@end

/**
 * An abstract content container.
 * This class provides standard functionality needed to service requests from content URLs and URIs. It
 * automatically handles cancellation of NSURLProtocol requests. All requests are forwarded to the
 * [writeResponse: forAuthority: path: parameters:] method, and subclasses should override this method
 * with an implementation which resolves content data as appropriate for the request.
 */
@interface IFAbstractContentContainer : NSObject <IFContentContainer> {
    /// A set of live NSURL responses.
    NSMutableSet *_liveResponses;
    /// TODO
    NSMutableDictionary *_resources;
}

/**
 * Resolve content data for the specified authority, path and parameters, and write the data to the provided
 * response object.
 * Subclasses should override this method with an appropriate implementation.
 */
- (void)writeResponse:(id<IFContentContainerResponse>)response
         forAuthority:(NSString *)authority
                 path:(NSString *)path
           parameters:(NSDictionary *)parameters;

@end
