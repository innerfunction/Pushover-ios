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

@class IFHTTPClient;

@interface IFHTTPClientResponse : NSObject

- (id)initWithHTTPResponse:(NSURLResponse *)response data:(NSData *)data;
- (id)initWithHTTPResponse:(NSURLResponse *)response downloadLocation:(NSURL *)location;

@property (nonatomic, strong) NSHTTPURLResponse *httpResponse;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSURL *downloadLocation;

- (id)parseData;

@end

@interface IFHTTPClient : NSObject

- (id)initWithNSURLSessionTaskDelegate:(id<NSURLSessionTaskDelegate>)sessionTaskDelegate;

@property (nonatomic, weak) id<NSURLSessionTaskDelegate> sessionTaskDelegate;

- (QPromise *)get:(NSString *)url;
- (QPromise *)get:(NSString *)url data:(NSDictionary *)data;
- (QPromise *)getFile:(NSString *)url;
- (QPromise *)getFile:(NSString *)url data:(NSDictionary *)data;
- (QPromise *)post:(NSString *)url data:(NSDictionary *)data;
- (QPromise *)submit:(NSString *)method url:(NSString *)url data:(NSDictionary *)data;

@end
