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
//  Created by Julian Goacher on 02/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFResource.h"

/**
 * A description of a file referenced by an internal URI.
 */
@interface IFFileDescription : NSObject

/**
 * Initialize a new file description.
 * @param handle The file handler.
 * @param url A URL referencing the file.
 * @param path The path to the file.
 */
- (id)initWithHandle:(NSFileHandle *)handle url:(NSURL *)url path:(NSString *)path;

/// The file's handle.
@property (nonatomic, strong) NSFileHandle *handle;
/// The file's URL.
@property (nonatomic, strong) NSURL *url;
/// The file's absolute path.
@property (nonatomic, strong) NSString *path;

@end

/**
 * A resource type used to represent file data.
 */
@interface IFFileResource : IFResource

/**
 * Initialize a new resource.
 * @param handle A file handle.
 * @param url A URL referencing the file.
 * @param path An absolute path to the file.
 * @param uri The internal URI used to reference the file.
 */
- (id)initWithHandle:(NSFileHandle *)handle url:(NSURL *)url path:(NSString *)filePath uri:(IFCompoundURI *)uri;

/// The file descriptor.
@property (nonatomic, strong) IFFileDescription *fileDescription;

@end

/**
 * A resource type used to represent directories on the file system.
 */
@interface IFDirectoryResource : IFResource

/**
 * Initialize a new resource.
 * @param path The path to the directory.
 * @param uri The internal URI used to reference the directory.
 */
- (id)initWithPath:(NSString *)path uri:(IFCompoundURI *)uri;

@end