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
//  Created by Julian Goacher on 20/10/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFCMSSettings.h"

#define PushoverAPIVersion  (@"0.2")
#define PushoverAPIRoot     (@"semop")
#define PushoverAuthRealm   (@"Pushover")

// TODO Workings of this class have to be refactored to allow configuration of API version and root, and use of HTTPS.

@interface IFCMSSettings()

- (NSString *)pathForResource:(NSString *)resourceName trailing:(NSString *)trailing;
- (NSString *)urlForPath:(NSString *)path;

@end

@implementation IFCMSSettings

- (id)init {
    self = [super init];
    if (self) {
        self.authRealm = PushoverAuthRealm;
        self.pathRoot = [PushoverAPIRoot stringByAppendingPathComponent:PushoverAPIVersion];
    }
    return self;
}

- (NSString *)urlForAuthentication {
    return [self urlForPath:[self pathForResource:@"authenticate" trailing:nil]];
}

- (NSString *)urlForUpdates {
    return [self urlForPath:[self pathForResource:@"updates" trailing:nil]];
}

- (NSString *)urlForFileset:(NSString *)category {
    return [self urlForPath:[self pathForResource:@"filesets" trailing:category]];
}

- (NSString *)urlForFile:(NSString *)path {
    return [self urlForPath:[self pathForResource:@"files" trailing:path]];
}

- (NSString *)apiBaseURL {
    return [self urlForPath:@""];
}

#pragma mark - Private methods

// http://{host}/{apiroot}/{apiver}/path
- (NSString *)pathForResource:(NSString *)resourceName trailing:(NSString *)trailing {
    NSString *path = _pathRoot;
    path = [path stringByAppendingPathComponent:resourceName];
    path = [path stringByAppendingPathComponent:_account];
    path = [path stringByAppendingPathComponent:_repo];
    if (_branch) {
        path = [path stringByAppendingPathComponent:[@"~" stringByAppendingString:_branch]];
    }
    if (trailing) {
        path = [path stringByAppendingPathComponent:trailing];
    }
    return path;
}

- (NSString *)urlForPath:(NSString *)path {
    return [NSString stringWithFormat:@"http://%@/%@", _host, path];
}

@end
