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

@interface IFHTTPClient : NSObject {
    __weak id<NSURLSessionTaskDelegate> _sessionTaskDelegate;
}

- (id)initWithNSURLSessionTaskDelegate:(id<NSURLSessionDataDelegate>)sessionTaskDelegate;

- (QPromise *)get:(NSString *)url;
- (QPromise *)get:(NSString *)url data:(NSDictionary *)data;
- (QPromise *)getFile:(NSString *)url;
- (QPromise *)getFile:(NSString *)url data:(NSDictionary *)data;
- (QPromise *)post:(NSString *)url data:(NSDictionary *)data;
- (QPromise *)submit:(NSString *)method url:(NSString *)url data:(NSDictionary *)data;

@end
