//
//  IFHTTPClient.m
//  Pushover
//
//  Created by Julian Goacher on 24/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFHTTPClient.h"
#import "SSKeychain.h"

typedef QPromise *(^IFHTTPClientAction)();

@interface IFHTTPClient()

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
        data = [NSJSONSerialization JSONObjectWithData:_data
                                               options:0
                                                 error:nil];
        // TODO: Parse error handling.
    }
    else if ([@"application/x-www-form-urlencoded" isEqualToString:contentType]) {
        // Adapted from http://stackoverflow.com/questions/8756683/best-way-to-parse-url-string-to-get-values-for-keys
        NSMutableDictionary *mdata = [[NSMutableDictionary alloc] init];
        // TODO: Proper handling of response text encoding.
        NSString *paramString = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
        NSArray *params = [paramString componentsSeparatedByString:@"&"];
        for (NSString *param in params) {
            NSArray *pair = [param componentsSeparatedByString:@"="];
            NSString *name = [(NSString *)[pair objectAtIndex:0] stringByRemovingPercentEncoding];
            NSString *value = [(NSString *)[pair objectAtIndex:1] stringByRemovingPercentEncoding];
            [mdata setObject:value forKey:name];
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
    return [self get:url data:nil];
}

- (QPromise *)get:(NSString *)url data:(NSDictionary *)data {
    return [self submitAction:^QPromise *{
        QPromise *promise = [QPromise new];
        // Send request.
        NSURLRequest *request = [NSURLRequest requestWithURL:makeURL(url, data)];
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
    return [self getFile:url data:nil];
}

- (QPromise *)getFile:(NSString *)url data:(NSDictionary *)data {
    return [self submitAction:^QPromise *{
        QPromise *promise = [QPromise new];
        NSURL *fileURL = makeURL(url, data);
        // See note here about NSURLConnection cacheing: http://blackpixel.com/blog/2012/05/caching-and-nsurlconnection.html
        NSURLRequest *request = [NSURLRequest requestWithURL:fileURL
                                                 cachePolicy:NSURLRequestReloadRevalidatingCacheData // NOTE
                                             timeoutInterval:60];
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
    return [self submitAction:^QPromise *{
        QPromise *promise = [QPromise new];
        // Build URL.
        NSURL *nsURL = [NSURL URLWithString:url];
        // Send request.
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:nsURL];
        request.HTTPMethod = @"POST";
        [request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        if (data) {
            NSMutableArray *queryItems = [[NSMutableArray alloc] init];
            for (NSString *name in data) {
                NSString *pname = [name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
                NSString *pvalue = [[[data objectForKey:name] description] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
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

- (QPromise *)submitAction:(IFHTTPClientAction)action {
    return action();
}

- (NSURLSession *)makeSession {
    if (_sessionTaskDelegate) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        return [NSURLSession sessionWithConfiguration:configuration
                                             delegate:_sessionTaskDelegate
                                        delegateQueue:nil];
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
