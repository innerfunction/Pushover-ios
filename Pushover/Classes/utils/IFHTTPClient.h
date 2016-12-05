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
//  Created by Julian Goacher on 24/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Q/Q.h>

/// HTTP client request option; set the Accept header value.
NSString const * _Nonnull IFHTTPClientRequestOptionAccept = @"IFHTTPClientRequestOptionAccept";

@class IFHTTPClient;

/// An HTTP response.
@interface IFHTTPClientResponse : NSObject

- (id _Nonnull)initWithHTTPResponse:(NSURLResponse * _Nonnull)response data:(NSData * _Nullable)data;
- (id _Nonnull)initWithHTTPResponse:(NSURLResponse * _Nonnull)response downloadLocation:(NSURL * _Nonnull)location;

@property (nonatomic, strong) NSHTTPURLResponse * _Nonnull httpResponse;
@property (nonatomic, strong) NSData * _Nullable data;
@property (nonatomic, strong) NSURL * _Nullable downloadLocation;

/**
 * Parse the response data.
 * Inspects the response content type and parses the data accordingly.
 */
- (id _Nullable)parseData;

@end

@interface IFHTTPClient : NSObject

- (id _Nonnull)initWithNSURLSessionTaskDelegate:(id<NSURLSessionTaskDelegate> _Nullable)sessionTaskDelegate;

@property (nonatomic, weak) id<NSURLSessionTaskDelegate> _Nullable sessionTaskDelegate;

/**
 * Get a URL.
 */
- (QPromise * _Nonnull)get:(NSString * _Nonnull)url;
/**
 * Get a URL, passing the specified data.
 * @param url   The URL to get.
 * @param data  Data to include in the URL's query string.
 */
- (QPromise * _Nonnull)get:(NSString * _Nonnull)url data:(NSDictionary * _Nullable)data;
/**
 * Get a URL, passing the specified data.
 * @param url   The URL to get.
 * @param data  Data to include in the URL's query string.
 * @param options   Additional request options, see the IFHTTPClientRequestOptionXXX constants.
 */
- (QPromise * _Nonnull)get:(NSString * _Nonnull)url data:(NSDictionary * _Nullable)data options:( NSDictionary * _Nullable )options;
/**
 * Get a file from a URL.
 */
- (QPromise * _Nonnull)getFile:(NSString * _Nonnull)url;
/**
 * Get a file from a URL, passing the specified data.
 * @param url   The URL to get.
 * @param data  Data to include in the URL's query string.
 */
- (QPromise * _Nonnull)getFile:(NSString * _Nonnull)url data:(NSDictionary * _Nullable)data;
/**
 * Get a file from a URL, passing the specified data.
 * @param url       The URL to get.
 * @param data      Data to include in the URL's query string.
 * @param options   Additional request options, see the IFHTTPClientRequestOptionXXX constants.
 */
- (QPromise * _Nonnull)getFile:(NSString * _Nonnull)url data:(NSDictionary * _Nullable)data options:( NSDictionary * _Nullable )options;
/**
 * Post data to a URL.
 * @param url   The URL to post to.
 * @param data  The data to post.
 */
- (QPromise * _Nonnull)post:(NSString * _Nonnull)url data:(NSDictionary * _Nullable)data;
/**
 * Post data to a URL.
 * @param url   The URL to post to.
 * @param data  The data to post.
 * @param options   Additional request options, see the IFHTTPClientRequestOptionXXX constants.
 */
- (QPromise * _Nonnull)post:(NSString * _Nonnull)url data:(NSDictionary * _Nullable)data options:(NSDictionary * _Nullable)options;

/**
 * Submit data to a URL.
 * @param method    The method to use, e.g. GET or POST.
 * @param url       The URL to request.
 * @param data      The data to submit.
 */
- (QPromise * _Nonnull)submit:(NSString * _Nonnull)method url:(NSString * _Nonnull)url data:(NSDictionary * _Nullable)data;

@end
