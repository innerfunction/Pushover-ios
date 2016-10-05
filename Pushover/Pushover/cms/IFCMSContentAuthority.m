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
//  Created by Julian Goacher on 13/09/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFCMSContentAuthority.h"
#import "IFCMSFileset.h"
#import "IFCMSFilesetCategoryPathRoot.h"
#import "IFCMSPostsPathRoot.h"

@implementation IFCMSContentAuthority

- (id)init {
    self = [super init];
    if (self) {
        _fileDB = [IFCMSFileDB new];
        self.configurationTemplate = @{
            @"fileDB": @{
                @"name":    @"$fileDBName",
                @"version": @1,
                @"tables": @{
                    @"files": @{
                        @"columns": @{
                            @"id":          @{ @"type": @"INTEGER", @"tag": @"id" },
                            @"path":        @{ @"type": @"STRING" },
                            @"category":    @{ @"type": @"STRING" },
                            @"status":      @{ @"type": @"STRING" },
                            @"commit":      @{ @"type": @"STRING",  @"tag": @"version" }
                        }
                    },
                    @"posts": @{
                        @"columns": @{
                            @"id":          @{ @"type": @"INTEGER", @"tag": @"id" },
                            @"type":        @{ @"type": @"STRING" },
                            @"title":       @{ @"type": @"STRING" },
                            @"body":        @{ @"type": @"STRING" },
                            @"image":       @{ @"type": @"INTEGER" },
                            @"commit":      @{ @"type": @"STRING",  @"tag": @"version" }

                        }
                    },
                    @"commits": @{
                        @"columns": @{
                            @"commit":      @{ @"type": @"STRING",  @"tag": @"id" },
                            @"date":        @{ @"type": @"STRING" },
                            @"subject":     @{ @"type": @"STRING" }
                        }
                    },
                    @"meta": @{
                        @"columns": @{
                            @"id":          @{ @"type": @"STRING",  @"tag": @"id", @"format": @"{fileid}:{key}" },
                            @"fileid":      @{ @"type": @"INTEGER", @"tag": @"ownerid" },
                            @"key":         @{ @"type": @"STRING",  @"tag": @"key" },
                            @"value":       @{ @"type": @"STRING" },
                            @"commit":      @{ @"type": @"STRING",  @"tag": @"version" }

                        }
                    }
                },
                @"orm": @{
                    @"source": @"files",
                    @"mappings": @{
                        @"post": @{
                            @"relation":    @"object",
                            @"table":       @"posts"
                        },
                        @"commit": @{
                            @"relation":    @"shared-object",
                            @"table":       @"commits"
                        },
                        @"meta": @{
                            @"relation":    @"map",
                            @"table":       @"meta"
                        }
                    }
                },
                @"filesets": @{
                    @"posts": @{
                        @"includes":        @[ @"posts/*.json" ],
                        @"mappings":        @[ @"commit", @"meta", @"post" ],
                        @"cache":           @"none"
                    },
                    @"pages": @{
                        @"includes":        @[ @"pages/*.json" ],
                        @"mappings":        @[ @"commit", @"meta" ],
                        @"cache":           @"none"
                    },
                    @"images": @{
                        @"includes":        @[ @"posts/images/*", @"pages/images/*" ],
                        @"mappings":        @[ @"commit", @"meta" ],
                        @"cache":           @"content"
                    },
                    @"assets": @{
                        @"includes":        @[ @"assets/**" ],
                        @"mappings":        @[ @"commit" ],
                        @"cache":           @"content"
                    },
                    @"templates": @{
                        @"includes":        @[ @"templates/**" ],
                        @"mappings":        @[ @"commit" ],
                        @"cache":           @"app"
                    }
                }
            },
            @"postsPathRoot": @{
                @"*ios-class":              @"IFCMSPostsPathRoot"
            },
            @"pathRoots": @{
                @"~posts":                  @"$postsPathRoot",
                @"~pages":                  @"$postsPathRoot",
                @"~files": @{
                    @"*ios-class":          @"IFCMSFilesetCategoryPathRoot"
                }
            }
        };
        // TODO Record types (posts/pages): dbjson, html, webview
        // TODO Query types: dbjson, tableview
    }
    return self;
}

- (NSDictionary *)filesets {
    return _fileDB.filesets;
}

- (void)setAuthorityName:(NSString *)authorityName {
    super.authorityName = authorityName;
    if (_fileDBName == nil) {
        self.fileDBName = authorityName;
    }
    self.configurationParameters[@"authorityName"] = authorityName;
}

- (void)setFileDBName:(NSString *)fileDBName {
    _fileDBName = fileDBName;
    self.configurationParameters[@"fileDBName"] = fileDBName;
}

- (void)setPostsPathRoot:(IFCMSPostsPathRoot *)postsPathRoot {
    _postsPathRoot = postsPathRoot;
    self.configurationParameters[@"postsPathRoot"] = postsPathRoot;
}

#pragma mark - IFAbstractContentAuthority override

- (void)writeResponse:(id<IFContentAuthorityResponse>)response
         forAuthority:(NSString *)authority
                 path:(IFContentPath *)path
           parameters:(NSDictionary *)parameters {
    
    // A tilde at the start of a path indicates a fileset category reference; so any path which
    // doesn't start with tilde is a direct reference to a file by its path. Convert the reference
    // to a fileset reference by looking up the file ID and category for the path.
    NSString *root = [path root];
    if (![root hasPrefix:@"~"]) {
        // Lookup file entry by path.
        NSArray *result = [_fileDB performQuery:@"SELECT id, category FROM files WHERE path=?"
                                     withParams:@[ [path fullPath] ]];
        if ([result count] > 0) {
            // File entry found in database; rewrite content path to a direct resource reference.
            NSDictionary *row = result[0];
            NSString *fileID = row[@"id"];
            NSString *category = row[@"category"];
            NSString *resourcePath = [NSString stringWithFormat:@"~%@/$%@", category, fileID];
            path = [[IFContentPath alloc] initWithPath:resourcePath];
        }
    }
    [super writeResponse:response forAuthority:authority path:path parameters:parameters];
}

#pragma mark - IFIOCConfigurationAware

- (void)beforeIOCConfiguration:(IFConfiguration *)configuration {
}

- (void)afterIOCConfiguration:(IFConfiguration *)configuration {
    [super afterIOCConfiguration:configuration];
    // Ensure a path root exists for each fileset, and is associated with the fileset.
    NSDictionary *filesets = [self filesets];
    for (NSString *category in [filesets keyEnumerator]) {
        IFCMSFileset *fileset = filesets[category];
        // Note that fileset category path roots are prefixed with a tilde.
        NSString *pathRootName = [@"~" stringByAppendingString:category];
        id pathRoot = self.pathRoots[pathRootName];
        if (pathRoot == nil) {
            // Create a default path root for the current category.
            pathRoot = [[IFCMSFilesetCategoryPathRoot alloc] initWithFileset:fileset container:self];
            self.pathRoots[pathRootName] = pathRoot;
        }
        else if ([pathRoot isKindOfClass:[IFCMSFilesetCategoryPathRoot class]]) {
            // Path root for category found, match it up with its fileset.
            ((IFCMSFilesetCategoryPathRoot *)pathRoot).fileset = fileset;
        }
    }
}

@end
