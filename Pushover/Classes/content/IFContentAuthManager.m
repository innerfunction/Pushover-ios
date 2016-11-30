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

/* NOTE on credential storage:
 * In testing, it was found that [NSURLCredentialStorage defaultCredentialForProtectionSpace:]
 * would return the last used credential, even after that credential had been removed from the
 * storage space. This behaviour was inconsisent, e.g. the credential would seem to eventually
 * disappear from storage after some period of time. However this did cause problems; for
 * example, (1) log in (2) log out (3) stop and restart app -> app displays main screen instead
 * of login form. Because of this, the code below, as well as storing the active credential
 * in the credential storage, also stores a flag in user defaults saying whether the app is
 * logged in for the associated protection space (using a defaults key derived from the
 * protection space description), and will only report an active login if there is both an
 * active credential AND if the flag is set.
 * This problem has only been identified on the iphone simulator, actual devices may actually
 * not have this problem.
 */

@interface IFContentAuthManager()

@end

@implementation IFContentAuthManager

- (id)initWithURL:(NSString *)url realm:(NSString *)realm {
    self = [super init];
    if (self) {
        NSURL *nsurl = [NSURL URLWithString:url];
        NSInteger port = [nsurl.port integerValue];
        if (port == 0) {
            if ([@"http" isEqualToString:nsurl.scheme]) {
                port = 80;
            }
            else if ([@"https" isEqualToString:nsurl.scheme]) {
                port = 443;
            }
        }
        _protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:nsurl.host
                                                                 port:port
                                                             protocol:nsurl.scheme
                                                                realm:realm
                                                 authenticationMethod:nil];
        
        _userDefaults = [NSUserDefaults standardUserDefaults];
        // Calculate a defaults key from the protection space description.
        NSString *pspaceDesc = [_protectionSpace description];
        // Example: <NSURLProtectionSpace: 0x7fc728c2fc30>: Host:127.0.0.1, Server:http ...
        // Remove the address from the start of the string.
        NSRange range = [pspaceDesc rangeOfString:@">: "]; // Find end of address
        if (range.location != NSNotFound) {
            pspaceDesc = [pspaceDesc substringFromIndex:range.location];
        }
        _userDefaultsKey = [NSString stringWithFormat:@"IFContentAuthManager.isLoggedIn(%ld)", [pspaceDesc hash]];
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
    // Store that we're logged in in the user defaults.
    [_userDefaults setBool:YES forKey:_userDefaultsKey];
}

- (BOOL)isLoggedIn {
    // Test whether there is an active credential and a flag indicating that we're logged in.
    BOOL loggedIn = [_userDefaults boolForKey:_userDefaultsKey];
    return [self getActiveCredential] != nil && loggedIn;
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
    [_userDefaults setBool:NO forKey:_userDefaultsKey];
}

@end
