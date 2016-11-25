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
    }
    return self;
}

- (void)loginWithUsername:(NSString *)username password:(NSString *)password {
    NSURLCredentialStorage *storage = [NSURLCredentialStorage sharedCredentialStorage];
    // Check for an existing credential with the same username.
    NSURLCredential *credential = [self getCredentialForUsername:username];
    if (credential) {
        // Existing credential found, delete it before continuing.
        [storage removeCredential:credential forProtectionSpace:_protectionSpace];
    }
    // Create the credential.
    credential = [NSURLCredential credentialWithUser:username
                                            password:password
                                         persistence:NSURLCredentialPersistencePermanent];
    // Set the default credential.
    [storage setDefaultCredential:credential forProtectionSpace:_protectionSpace];
}

- (BOOL)isLoggedIn {
    // Test whether there is an active credential.
    return [self getActiveCredential] != nil;
}

- (NSURLCredential *)getActiveCredential {
    // Get the default credential.
    NSURLCredentialStorage *storage = [NSURLCredentialStorage sharedCredentialStorage];
    NSURLCredential *credential = [storage defaultCredentialForProtectionSpace:_protectionSpace];
    return credential;
}

- (NSURLCredential *)getCredentialForUsername:(NSString *)username {
    NSURLCredentialStorage *storage = [NSURLCredentialStorage sharedCredentialStorage];
    NSDictionary *credentials = [storage credentialsForProtectionSpace:_protectionSpace];
    NSURLCredential *credential = credentials[username];
    return credential;
}

- (void)logout {
    NSURLCredential *credential = [self getActiveCredential];
    if (credential != nil) {
        // Remove the active user's credentials.
        NSURLCredentialStorage *storage = [NSURLCredentialStorage sharedCredentialStorage];
        [storage removeCredential:credential forProtectionSpace:_protectionSpace];
    }
}

@end
