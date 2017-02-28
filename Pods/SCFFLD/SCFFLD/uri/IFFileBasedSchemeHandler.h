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
// limitations under the License
//
//  Created by Julian Goacher on 13/03/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFResource.h"
#import "IFFileResource.h"

/**
 * A URI scheme handler for referencing file data. Instances of this handler are
 * initialized with directory search paths (defined using standard NS file definitions),
 * or a single standard base path. The compound URI _name_ is used as the file path.
 * The handler uses the path to search for a matching file under each of its configured
 * base paths.
 * File based schemes support relative URIs, where a URI name representing a relative
 * path (i.e. a path not starting with /) is resolved against a reference absolute URI.
 */
@interface IFFileBasedSchemeHandler : NSObject <IFSchemeHandler> {
    // A list of one or more base paths.
    NSArray *_paths;
    // A reference to the default file manager.
    NSFileManager *_fileManager;
}

/** Initialize the handler with a specific search path. */
- (id)initWithDirectory:(NSSearchPathDirectory)directory;
/** Initialize the handler with the specified base path. */
- (id)initWithPath:(NSString *)path;
/**
 * Try dererencing a URI against a specified base path.
 * @param uri A URI belonging to the current handler's URI scheme.
 * @param path A base path.
 * @return If a file exists at the path, specified by the URI's name, relative to the specified
 * base path, then return a resource (@see <IFFileResource>) representing that file; otherwise
 * return _nil_.
 */
- (IFResource *)dereference:(IFCompoundURI *)uri againstPath:(NSString *)path;

@end