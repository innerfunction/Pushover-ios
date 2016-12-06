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

#import "IFHTTPClient.h"
#import "SSKeychain.h"
#import <MPMessagePack/MPMessagePack.h>

#define LogJSONResponse (0)

NSString const * _Nonnull IFHTTPClientRequestOptionAccept           = @"IFHTTPClientRequestOptionAccept";
NSString const * _Nonnull IFHTTPClientRequestOptionAcceptEncoding   = @"IFHTTPClientRequestOptionAcceptEncoding";

typedef QPromise *(^IFHTTPClientAction)();

@interface IFHTTPClient()

- (void)setOptions:(NSDictionary *)options onRequest:(NSMutableURLRequest *)request;
- (QPromise *)submitAction:(IFHTTPClientAction)action;
- (NSURLSession *)makeSession;

NSURL *makeURL(NSString *url, NSDictionary *params);

@end

@implementation IFHTTPClientResponse

- (id)initWithHTTPResponse:(NSURLResponse *)response data:(NSData *)data {
    self = [super init];
    if (self) {
        self.httpResponse = (NSHTTPURLResponse *)response;
        self.data = data;
    }
    return self;
}

- (id)initWithHTTPResponse:(NSURLResponse *)response downloadLocation:(NSURL *)location {
    self = [super init];
    if (self) {
        self.httpResponse = (NSHTTPURLResponse *)response;
        self.downloadLocation = location;
    }
    return self;
}

- (id)parseData {
    id data = nil;
    NSString *contentType = _httpResponse.MIMEType;
    if ([@"application/json" isEqualToString:contentType]) {
#if LogJSONResponse
        NSLog(@"%@", [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding]);
#endif
        data = [NSJSONSerialization JSONObjectWithData:_data
                                               options:0
                                                 error:nil];
        // TODO: Parse error handling.
    }
    else if ([@"application/msgpack" isEqualToString:contentType]) {
        NSError *error;
        data = [MPMessagePackReader readData:_data error:&error];
        if (error) {
            NSLog(@"%@", error );
        }
    }
    else if ([@"application/x-www-form-urlencoded" isEqualToString:contentType]) {
        // Adapted from http://stackoverflow.com/questions/8756683/best-way-to-parse-url-string-to-get-values-for-keys
        NSMutableDictionary *mdata = [NSMutableDictionary new];
        // TODO: Proper handling of response text encoding.
        NSString *paramString = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
        NSArray *params = [paramString componentsSeparatedByString:@"&"];
        for (NSString *param in params) {
            NSArray *pair = [param componentsSeparatedByString:@"="];
            NSString *name = [(NSString *)pair[0] stringByRemovingPercentEncoding];
            NSString *value = [(NSString *)pair[1] stringByRemovingPercentEncoding];
            mdata[name] = value;
        }
        data = mdata;
    }
    else if ([contentType hasPrefix:@"text/"]) {
        data = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
    }
    return data;
}

@end

@implementation IFHTTPClient

- (id)initWithNSURLSessionTaskDelegate:(id<NSURLSessionDataDelegate>)sessionTaskDelegate {
    self = [super init];
    if (self) {
        _sessionTaskDelegate = sessionTaskDelegate;
    }
    return self;
}

- (QPromise *)get:(NSString *)url {
    return [self get:url data:nil options:nil];
}

- (QPromise *)get:(NSString *)url data:(NSDictionary *)data {
    return [self get:url data:data options:nil];
}

- (QPromise *)get:(NSString *)url data:(NSDictionary *)data options:(NSDictionary *)options {
    return [self submitAction:^QPromise *{
        QPromise *promise = [QPromise new];
        // Send request.
        NSURL *nsurl = makeURL(url, data);
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:nsurl
                                                               cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                           timeoutInterval:60];
        [self setOptions:options onRequest:request];
        NSURLSession *session = [self makeSession];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                                completionHandler:
        ^(NSData * _Nullable responseData, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error) {
                [promise reject:error];
            }
            else {
                [promise resolve:[[IFHTTPClientResponse alloc] initWithHTTPResponse:response data:responseData]];
            }
        }];
        [task resume];
        return promise;
    }];
}

- (QPromise *)getFile:(NSString *)url {
    return [self getFile:url data:nil options:nil];
}

- (QPromise *)getFile:(NSString *)url data:(NSDictionary *)data {
    return [self getFile:url data:data options:nil];
}

- (QPromise *)getFile:(NSString *)url data:(NSDictionary *)data options:(NSDictionary *)options {
    return [self submitAction:^QPromise *{
        QPromise *promise = [QPromise new];
        NSURL *fileURL = makeURL(url, data);
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:fileURL
                                                               cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                           timeoutInterval:60];
        [self setOptions:options onRequest:request];
        NSURLSession *session = [self makeSession];
        NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request
                                                        completionHandler:
        ^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error) {
                [promise reject:error];
            }
            else {
                [promise resolve:[[IFHTTPClientResponse alloc] initWithHTTPResponse:response downloadLocation:location]];
            }
        }];
        [task resume];
        return promise;
    }];
}

- (QPromise *)post:(NSString *)url data:(NSDictionary *)data {
    return [self post:url data:data options:nil];
}

- (QPromise *)post:(NSString *)url data:(NSDictionary *)data options:(NSDictionary *)options {
    return [self submitAction:^QPromise *{
        QPromise *promise = [QPromise new];
        // Build URL.
        NSURL *nsURL = [NSURL URLWithString:url];
        // Send request.
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:nsURL
                                                               cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                           timeoutInterval:60];
        request.HTTPMethod = @"POST";
        [request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [self setOptions:options onRequest:request];
        if (data) {
            NSMutableArray *queryItems = [[NSMutableArray alloc] init];
            for (NSString *name in data) {
                NSString *pname = [name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
                NSString *pvalue = [data[name] description];
                pvalue = [pvalue stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
                NSString *param = [NSString stringWithFormat:@"%@=%@", pname, pvalue];
                [queryItems addObject:param];
            }
            NSString *body = [queryItems componentsJoinedByString:@"&"];
            request.HTTPBody = [body dataUsingEncoding:NSUTF8StringEncoding];
        }
        NSURLSession *session = [self makeSession];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request
            completionHandler:^(NSData * _Nullable responseData, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                if (error) {
                    [promise reject:error];
                }
                else {
                    [promise resolve:[[IFHTTPClientResponse alloc] initWithHTTPResponse:response data:responseData]];
                }
            }];
        [task resume];
        return promise;
    }];
}

- (QPromise *)submit:(NSString *)method url:(NSString *)url data:(NSDictionary *)data {
    if ([@"POST" isEqualToString:method]) {
        return [self post:url data:data];
    }
    return [self get:url data:data];
}

#pragma mark - Private methods

- (void)setOptions:(NSDictionary *)options onRequest:(NSMutableURLRequest *)request {
    if (options) {
        NSString *accept = options[IFHTTPClientRequestOptionAccept];
        if (accept) {
            [request setValue:accept forHTTPHeaderField:@"Accept"];
        }
        NSString *acceptEncoding = options[IFHTTPClientRequestOptionAcceptEncoding];
        if (acceptEncoding) {
            [request setValue:acceptEncoding forHTTPHeaderField:@"Accept-Encoding"];
        }
    }
}

- (QPromise *)submitAction:(IFHTTPClientAction)action {
    return action();
}

- (NSURLSession *)makeSession {
    if (_sessionTaskDelegate) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSOperationQueue *operationQueue = [NSOperationQueue mainQueue];
        return [NSURLSession sessionWithConfiguration:configuration
                                             delegate:_sessionTaskDelegate
                                        delegateQueue:operationQueue];
    }
    return [NSURLSession sharedSession];
}

NSURL *makeURL(NSString *url, NSDictionary *params) {
    NSURLComponents *urlParts = [NSURLComponents componentsWithString:url];
    if (params) {
        NSMutableArray *queryItems = [[NSMutableArray alloc] init];
        for (NSString *name in params) {
            NSURLQueryItem *queryItem = [NSURLQueryItem queryItemWithName:name value:params[name]];
            [queryItems addObject:queryItem];
        }
        urlParts.queryItems = queryItems;
    }
    return urlParts.URL;
}

@end
