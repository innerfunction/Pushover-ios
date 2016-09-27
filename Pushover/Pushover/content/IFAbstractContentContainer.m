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

#import "IFAbstractContentContainer.h"
#import "IFResource.h"
#import "NSArray+IF.h"
#import "IFCompoundURI.h"

@interface IFNSURLProtocolResponse : NSObject <IFContentContainerResponse> {
    __weak NSMutableSet *_liveResponses;
    NSURLProtocol *_protocol;
}

- (id)initWithNSURLProtocol:(NSURLProtocol *)protocol liveResponses:(NSMutableSet *)liveResponses;

@end

@interface IFSchemeHandlerResponse : IFResource <IFContentContainerResponse> {
    NSMutableData *_buffer;
}

@end

@implementation IFAbstractContentContainer

- (id)init {
    self = [super init];
    if (self) {
        _liveResponses = [NSMutableSet new];
        _pathRoots = [NSMutableDictionary new];
    }
    return self;
}

#pragma mark - IFContentContainer

- (void)handleURLProtocolRequest:(NSURLProtocol *)protocol {
    [_liveResponses addObject:protocol];
    IFNSURLProtocolResponse *response = [[IFNSURLProtocolResponse alloc] initWithNSURLProtocol:protocol
                                                                                 liveResponses:_liveResponses];
    NSURL *url = protocol.request.URL;
    NSString *authority = url.host;
    IFContentPath *contentPath = [[IFContentPath alloc] initWithURL:url];
    
    // Parse the URL's scheme and path parts as a compound URI; this is to allow encoding of
    // request parameters in the compound URI format - i.e. +p1@v1+p2@v2 etc.
    IFCompoundURI *uri = [[IFCompoundURI alloc] initWithScheme:url.scheme name:url.path];
    NSDictionary *parameters = [self.uriHandler dereferenceParameters:uri];
    
    [self writeResponse:response
           forAuthority:authority
                   path:contentPath
             parameters:parameters];
}

- (void)cancelURLProtocolRequest:(NSURLProtocol *)protocol {
    [_liveResponses removeObject:protocol];
}

- (id)contentForAuthority:(NSString *)authority path:(NSString *)path parameters:(NSDictionary *)parameters {
    IFSchemeHandlerResponse *response = [IFSchemeHandlerResponse new];
    IFContentPath *contentPath = [[IFContentPath alloc] initWithPath:path];
    [self writeResponse:response
           forAuthority:authority
                   path:contentPath
             parameters:parameters];
    return response;
}

- (void)writeResponse:(id<IFContentContainerResponse>)response
         forAuthority:(NSString *)authority
                 path:(IFContentPath *)path
           parameters:(NSDictionary *)parameters {
    
    // Look-up a path root for the first path component, and if one is found then delegate the request to it.
    NSString *root = [path root];
    id<IFContentContainerPathRoot> pathRoot = _pathRoots[root];
    if (pathRoot) {
        // The path root only sees the rest of the path.
        path = [path rest];
        // Delegate the request.
        [pathRoot writeResponse:response
                   forAuthority:authority
                           path:path
                     parameters:parameters];
    }
    else {
        // Path not found, respond with error.
        NSError *error = makePathNotFoundResponseError([path fullPath]);
        [response respondWithError:error];
    }
}

@end

@implementation IFNSURLProtocolResponse

- (id)initWithNSURLProtocol:(NSURLProtocol *)protocol liveResponses:(NSMutableSet *)liveResponses {
    self = [super init];
    if (self) {
        _protocol = protocol;
        _liveResponses = liveResponses;
    }
    return self;
}

- (void)respondWithData:(NSData *)data mimeType:(NSString *)mimeType cachePolicy:(NSURLCacheStoragePolicy)policy {
    if ([_liveResponses containsObject:_protocol]) {
        id<NSURLProtocolClient> client = _protocol.client;
        NSURLResponse *response = [[NSURLResponse alloc] initWithURL:_protocol.request.URL
                                                            MIMEType:mimeType
                                               expectedContentLength:data.length
                                                    textEncodingName:nil];
        [client URLProtocol:_protocol didReceiveResponse:response cacheStoragePolicy:policy];
        [client URLProtocol:_protocol didLoadData:data];
        [client URLProtocolDidFinishLoading:_protocol];
        [_liveResponses removeObject:self];
    }
}

- (void)respondWithMimeType:(NSString *)mimeType cacheStoragePolicy:(NSURLCacheStoragePolicy)policy {
    if ([_liveResponses containsObject:_protocol]) {
        id<NSURLProtocolClient> client = _protocol.client;
        NSURLResponse *response = [[NSURLResponse alloc] initWithURL:_protocol.request.URL
                                                            MIMEType:mimeType
                                               expectedContentLength:-1
                                                    textEncodingName:nil];
        [client URLProtocol:_protocol didReceiveResponse:response cacheStoragePolicy:policy];
    }
}

- (void)sendData:(NSData *)data {
    if ([_liveResponses containsObject:_protocol]) {
        id<NSURLProtocolClient> client = _protocol.client;
        [client URLProtocol:_protocol didLoadData:data];
    }
}

- (void)done {
    if ([_liveResponses containsObject:_protocol]) {
        id<NSURLProtocolClient> client = _protocol.client;
        [client URLProtocolDidFinishLoading:_protocol];
        [_liveResponses removeObject:_protocol];
    }
}

- (void)respondWithError:(NSError *)error {
    if ([_liveResponses containsObject:_protocol]) {
        [_protocol.client URLProtocol:_protocol didFailWithError:error];
        [_liveResponses removeObject:_protocol];
    }
}

- (void)respondWithStringData:(NSString *)stringData mimeType:(NSString *)mimeType cachePolicy:(NSURLCacheStoragePolicy)cachePolicy {
    NSData *data = [stringData dataUsingEncoding:NSUTF8StringEncoding];
    [self respondWithData:data mimeType:mimeType cachePolicy:cachePolicy];
}

- (void)respondWithJSONData:(id)jsonData cachePolicy:(NSURLCacheStoragePolicy)cachePolicy {
    NSData *data = [NSJSONSerialization dataWithJSONObject:jsonData
                                                   options:0
                                                     error:nil];
    [self respondWithData:data mimeType:@"application/json" cachePolicy:cachePolicy];
}

- (void)respondWithFileData:(NSString *)filepath mimeType:(NSString *)mimeType cachePolicy:(NSURLCacheStoragePolicy)cachePolicy {
    NSData *data = [NSData dataWithContentsOfFile:filepath];
    [self respondWithData:data mimeType:mimeType cachePolicy:cachePolicy];
}

@end

@implementation IFSchemeHandlerResponse

- (void)respondWithData:(NSData *)data mimeType:(NSString *)mimeType cachePolicy:(NSURLCacheStoragePolicy)policy {
    // TODO: Allow IFResource to report MIME types?
    self.data = data;
}

- (void)respondWithMimeType:(NSString *)mimeType cacheStoragePolicy:(NSURLCacheStoragePolicy)policy {
    // TODO: Allow IFResource to report MIME types?
    _buffer = [NSMutableData new];
}

- (void)sendData:(NSData *)data {
    [_buffer appendData:data];
}

- (void)done {
    self.data = _buffer;
    _buffer = nil;
}

- (void)respondWithError:(NSError *)error {
    // TODO: Should errors be reported through the IFResource interface?
    _buffer = nil;
}

- (void)respondWithStringData:(NSString *)stringData mimeType:(NSString *)mimeType cachePolicy:(NSURLCacheStoragePolicy)cachePolicy {
    NSData *data = [stringData dataUsingEncoding:NSUTF8StringEncoding];
    [self respondWithData:data mimeType:mimeType cachePolicy:cachePolicy];
}

- (void)respondWithJSONData:(id)jsonData cachePolicy:(NSURLCacheStoragePolicy)cachePolicy {
    NSData *data = [NSJSONSerialization dataWithJSONObject:jsonData
                                                   options:0
                                                     error:nil];
    [self respondWithData:data mimeType:@"application/json" cachePolicy:cachePolicy];
}

- (void)respondWithFileData:(NSString *)filepath mimeType:(NSString *)mimeType cachePolicy:(NSURLCacheStoragePolicy)cachePolicy {
    NSData *data = [NSData dataWithContentsOfFile:filepath];
    [self respondWithData:data mimeType:mimeType cachePolicy:cachePolicy];
}

@end