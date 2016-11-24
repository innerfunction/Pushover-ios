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

#import <Foundation/Foundation.h>

@interface IFContentAuthManager : NSObject {
    NSURLProtectionSpace *_protectionSpace;
    NSString *_activeUsernameDefaultsKey;
}

/// Initialize an authorization manager for the specified URL and (optional) realm.
- (id)initWithURL:(NSString *)url realm:(NSString *)realm;

/**
 * Login using the specified credentials.
 * Creates an NSURLCredentials and stores it on the device keychain.
 * It is up to the client code to validate the credentials after login, e.g. by requesting
 * an authenticated URL and checking for a valid response. Use the invalidateUsername:
 * method if credentials are found to be invalid.
 */
- (void)loginWithUsername:(NSString *)username password:(NSString *)password;

/**
 * Return YES if the client is logged in.
 * Tests whether an active username is available, and whether credentials for that username
 * are stored on the keychain; doesn't validate the credentials.
 */
- (BOOL)isLoggedIn;

/**
 * Return the active authentication credential.
 */
- (NSURLCredential *)getActiveCredential;

/**
 * Logout the client.
 * Removes the active username and deletes the stored credential.
 */
- (void)logout;

@end
