//
//  IFHTTPClient.h
//  Pushover
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

/// Delegate interface for the HTTP client.
@protocol IFHTTPClientDelegate <NSObject>

// A method called when the client is about to send a request.
- (void)httpClient:(IFHTTPClient *)httpClient willSendRequest:(NSMutableURLRequest *)request;

@end

@interface IFHTTPClient : NSObject

- (id)initWithDelegate:(id<IFHTTPClientDelegate>)delegate;
- (id)initWithNSURLSessionTaskDelegate:(id<NSURLSessionDataDelegate>)sessionTaskDelegate;

@property (nonatomic, weak) id<NSURLSessionTaskDelegate> sessionTaskDelegate;
@property (nonatomic, weak) id<IFHTTPClientDelegate> delegate;

- (QPromise *)get:(NSString *)url;
- (QPromise *)get:(NSString *)url data:(NSDictionary *)data;
- (QPromise *)getFile:(NSString *)url;
- (QPromise *)getFile:(NSString *)url data:(NSDictionary *)data;
- (QPromise *)post:(NSString *)url data:(NSDictionary *)data;
- (QPromise *)submit:(NSString *)method url:(NSString *)url data:(NSDictionary *)data;

@end
