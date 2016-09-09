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
//  Created by Julian Goacher on 09/09/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFCompoundURI.h"

/// An object representing a content path.
@interface IFContentPath : NSObject {
    /// An array containing all components of the full path.
    NSArray *_path;
    /// The index of the current path's root component.
    NSInteger _rootIdx;
}

/// Initialize with a list of path components and a root component index.
- (id)initWithPath:(NSArray *)path rootIndex:(NSInteger)rootIdx;

/// Initialize with a string path.
- (id)initWithPath:(NSString *)path;

/// Initialize the path with a URL.
- (id)initWithURL:(NSURL *)url;

/// Return the root path component.
- (NSString *)root;

/**
 * Return the portion of the path after the root component.
 * Returns a new content path object whose root component is the path component after the
 * current root.
 */
- (IFContentPath *)rest;

/// Return a list containing the root component and all path components following it.
- (NSArray *)components;

/// Test if the path is empty, i.e. has no root component.
- (BOOL)isEmpty;

/// Return a string representation of the full path.
- (NSString *)fullPath;

@end
