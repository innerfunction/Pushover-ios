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
//  Created by Julian Goacher on 30/11/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFCMSAuthenticationManager.h"
#import "SSKeychain.h"

#define UserDefaultsKey(k)  ([NSString stringWithFormat:@"IFCMSContentAuthenticationManager.%@.%@", _realm, k])

@interface IFCMSAuthenticationManager()

- (NSString *)basicAuthHeader;

@end

@implementation IFCMSAuthenticationManager

- (id)initWithRealm:(NSString *)realm {
    self = [super init];
    if (self) {
        _realm = realm;
        _basicAuthHeader = nil;
    }
    return self;
}

- (void)registerCredentials:(NSDictionary *)credentials {
    NSString *username = credentials[@"username"];
    NSString *password = credentials[@"password"];
    [self registerUsername:username password:password];
}

- (void)registerUsername:(NSString *)username password:(NSString *)password {
    if (username && password) {
        NSString *key = UserDefaultsKey(@"username");
        [[NSUserDefaults standardUserDefaults] setObject:username forKey:key];
        [SSKeychain setPassword:password forService:_realm account:username];
    }
}

- (BOOL)hasCredentials {
    NSString *key = UserDefaultsKey(@"username");
    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:key];
    return username != nil;
}

- (void)removeCredentials {
    NSString *key = UserDefaultsKey(@"username");
    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:key];
    if (username) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
        [SSKeychain deletePasswordForService:_realm account:username];
    }
    _basicAuthHeader = nil;
}

#pragma mark - private

- (NSString *)basicAuthHeader {
    if (_basicAuthHeader == nil) {
        NSString *key = UserDefaultsKey(@"username");
        NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:key];
        NSString *password = nil;
        if (username) {
            password = [SSKeychain passwordForService:_realm account:username];
        }
        if (username && password) {
            // URI encode the username & password.
            username = [username stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
            password = [password stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
            // Concatentate to make token.
            NSString *token = [NSString stringWithFormat:@"%@:%@", username, password ];
            // Base64 encode the token.
            NSData *tokenData = [token dataUsingEncoding:NSUTF8StringEncoding];
            _basicAuthHeader = [@"Basic " stringByAppendingString:[tokenData base64EncodedStringWithOptions:0]];
        }
    }
    return _basicAuthHeader;
}

#pragma mark - IFHTTPClientDelegate

- (void)httpClient:(IFHTTPClient *)httpClient willSendRequest:(NSMutableURLRequest *)request {
    NSString *basicAuthHeader = [self basicAuthHeader];
    if (basicAuthHeader) {
        NSLog(@"Authorization: %@", basicAuthHeader);
        [request setValue:basicAuthHeader forHTTPHeaderField:@"Authorization"];
    }
}

@end
