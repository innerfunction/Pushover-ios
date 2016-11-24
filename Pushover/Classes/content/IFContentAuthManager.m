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
//  Created by Julian Goacher on 24/11/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFContentAuthManager.h"

@implementation IFContentAuthManager

- (id)initWithURL:(NSString *)url realm:(NSString *)realm {
    self = [super init];
    if (self) {
        NSURL *nsurl = [NSURL URLWithString:url];
        _protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:nsurl.host
                                                                 port:[nsurl.port integerValue]
                                                             protocol:nsurl.scheme
                                                                realm:realm
                                                 authenticationMethod:nil];
        _activeUsernameDefaultsKey = [NSString stringWithFormat:@"IFContentAuthManager.activeUsername:%@:%@", url, realm != nil ? realm : @""];
    }
    return self;
}

- (void)loginWithUsername:(NSString *)username password:(NSString *)password {
    // Create the credential.
    NSURLCredential *credential = [NSURLCredential credentialWithUser:username
                                                             password:password
                                                          persistence:NSURLCredentialPersistencePermanent];
    // Store the credential.
    [[NSURLCredentialStorage sharedCredentialStorage] setCredential:credential
                                                 forProtectionSpace:_protectionSpace];
    // Store the active username.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:username forKey:_activeUsernameDefaultsKey];
}

- (BOOL)isLoggedIn {
    // Test whether an active username is set.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *activeUsername = [defaults stringForKey:_activeUsernameDefaultsKey];
    return activeUsername != nil;
}

- (NSURLCredential *)getActiveCredential {
    NSURLCredential *credential = nil;
    // Read the active username.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *activeUsername = [defaults stringForKey:_activeUsernameDefaultsKey];
    if (activeUsername) {
        // Get the active user's credentials.
        NSURLCredentialStorage *storage = [NSURLCredentialStorage sharedCredentialStorage];
        NSDictionary *credentials = [storage credentialsForProtectionSpace:_protectionSpace];
        credential = credentials[activeUsername];
    }
    return credential;
}

- (void)logout {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // Read the active username.
    NSString *activeUsername = [defaults stringForKey:_activeUsernameDefaultsKey];
    if (activeUsername) {
        // Get the active user's credentials.
        NSURLCredentialStorage *storage = [NSURLCredentialStorage sharedCredentialStorage];
        NSDictionary *credentials = [storage credentialsForProtectionSpace:_protectionSpace];
        NSURLCredential *credential = credentials[activeUsername];
        // Remove the active user's credentials.
        [storage removeCredential:credential forProtectionSpace:_protectionSpace];
    }
    // Remove the active username.
    [defaults removeObjectForKey:_activeUsernameDefaultsKey];
}

@end
