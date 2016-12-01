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

@implementation IFCMSAuthenticationManager

- (id)initWithRealm:(NSString *)realm {
    self = [super init];
    if (self) {
        _realm = realm;
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
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    if (challenge.previousFailureCount == 0) {
        NSString *key = UserDefaultsKey(@"username");
        NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:key];
        if (username) {
            NSString *password = [SSKeychain passwordForService:_realm account:username];
            if (password) {
                NSURLCredential *credential = [NSURLCredential credentialWithUser:username
                                                                         password:password
                                                                      persistence:NSURLCredentialPersistenceNone];
                completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
                return;
            }
        }
    }
    completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
}

@end
