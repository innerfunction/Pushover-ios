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

#import "IFCMSContentContainer.h"
#import "IFCMSFileset.h"

// TODO Content-container container:
// The different content containers all need to share some common resources, e.g.:
// - command scheduler
// - http client
// They also need unique content authority names, and a sensible way for the content
// url protocol handler to discover each container from the authority name.
// All this suggests that content containers should themselves be contained within
// a parent container providing the common resources & authority name mappings.
// The question then is whether this container is a new container type, or can it
// be any generic container with the necessary global names, in which case should
// an app container just be used for the job? Also, if a generic container is
// suitable, then how/where is the standard configuration template for a content-
// container container specified?

@implementation IFCMSContentContainer
- (id)init {
    self = [super init];
    if (self) {
        _dbName = @""; // TODO Should be derived from authority name.
        id template = @{
            @"fileDB": @{
                @"name":    @"$dbName",
                @"version": @1,
                @"tables": @{
                    @"files": @{
                        @"columns": @{
                            @"id":          @{ @"type": @"INTEGER", @"tag": @"id" },
                            @"path":        @{ @"type": @"STRING" },
                            @"category":    @{ @"type": @"STRING" },
                            @"status":      @{ @"type": @"STRING" },
                            @"commit":      @{ @"type": @"STRING" }
                        }
                    },
                    @"posts": @{
                        @"columns": @{
                            @"id":          @{ @"type": @"INTEGER", @"tag": @"id" },
                            @"type":        @{ @"type": @"STRING" },
                            @"title":       @{ @"type": @"STRING" },
                            @"body":        @{ @"type": @"STRING" },
                            @"image":       @{ @"type": @"INTEGER" }
                        }
                    },
                    @"commits": @{
                        @"columns": @{
                            @"commit":      @{ @"type": @"STRING", @"tag": @"id" },
                            @"date":        @{ @"type": @"STRING" },
                            @"subject":     @{ @"type": @"STRING" }
                        }
                    },
                    @"meta": @{
                        @"columns": @{
                            @"id":          @{ @"type": @"STRING",  @"tag": @"id", @"format": @"{fileid}:{key}" },
                            @"fileid":      @{ @"type": @"INTEGER", @"tag": @"ownerid" },
                            @"key":         @{ @"type": @"STRING",  @"tag": @"key" },
                            @"value":       @{ @"type": @"STRING" }
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
            }
        };
    }
    return self;
}

@end
