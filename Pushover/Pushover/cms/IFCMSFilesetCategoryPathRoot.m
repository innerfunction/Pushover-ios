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
//  Created by Julian Goacher on 23/09/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFCMSFilesetCategoryPathRoot.h"
#import "IFContentProvider.h"
#import "IFCMSContentAuthority.h"
#import "IFCMSFileset.h"
#import "IFContentTypeConverter.h"
#import "IFDBORM.h"
#import "IFHTTPClient.h"
#import "IFMIMETypes.h"

@implementation IFCMSFilesetCategoryPathRoot

- (id)initWithFileset:(IFCMSFileset *)fileset container:(IFCMSContentAuthority *)container {
    self = [super init];
    if (self) {
        self.fileset = fileset;
        self.authority = container;
    }
    return self;
}

- (void)setAuthority:(IFCMSContentAuthority *)container {
    _orm = container.db.orm;
}

- (NSArray *)queryWithParameters:(NSDictionary *)parameters {

    NSMutableArray *wheres = [NSMutableArray new];
    NSMutableArray *values = [NSMutableArray new];
    
    // Note that category field is qualifed by source table name.
    [wheres addObject:[NSString stringWithFormat:@"%@.category = ?", _orm.source]];
    [values addObject:_fileset.category];
    
    // Add filters for each of the specified parameters.
    for (id key in [parameters keyEnumerator]) {
        // Note that parameter names must be qualified by the correct relation name.
        [wheres addObject:[NSString stringWithFormat:@"%@ = ?", key]];
        [values addObject:parameters[key]];
    }
    
    // Join the wheres into a single where clause.
    NSString *where = [wheres componentsJoinedByString:@" AND "];
    // Execute query and return result.
    return [_orm selectWhere:where values:values mappings:_fileset.mappings];
}

- (NSDictionary *)entryWithKey:(NSString *)key {
    // Read the content and return the result.
    return [_orm selectKey:key mappings:_fileset.mappings];
}

- (void)writeQueryContent:(NSArray *)content asType:(NSString *)type toResponse:(id<IFContentAuthorityResponse>)response {
    if (type) {
        id<IFContentTypeConverter> typeConverter = self.authority.queryTypes[type];
        if (typeConverter) {
            [typeConverter writeContent:content toResponse:response];
        }
        else {
            [response respondWithError:makeUnsupportedTypeResponseError(type)];
        }
    }
    else {
        [response respondWithJSONData:content cachePolicy:NSURLCacheStorageNotAllowed];
    }
}

- (void)writeEntryContent:(NSDictionary *)content asType:(NSString *)type toResponse:(id<IFContentAuthorityResponse>)response {
    if (type) {
        id<IFContentTypeConverter> typeConverter = self.authority.recordTypes[type];
        if (typeConverter) {
            [typeConverter writeContent:content toResponse:response];
        }
        else {
            // No specific type converter found.
            // Check if the content file type is compatible with the requested type.
            NSString *path = content[@"path"];
            if ([type isEqualToString:[path pathExtension]]) {
                NSString *mimeType = [IFMIMETypes mimeTypeForType:type];
                NSString *url = [self.authority.cmsBaseURL stringByAppendingPathComponent:path];
                NSString *cachePath = [self.fileset.path stringByAppendingPathComponent:content[@"path"]];
                BOOL cachable = [self.fileset cachable];
                // Check if a local copy of the file exists in the cache.
                if (cachable && [[NSFileManager defaultManager] fileExistsAtPath:path]) {
                    // Local copy found, respond with contents.
                    [response respondWithFileData:cachePath
                                         mimeType:mimeType
                                      cachePolicy:NSURLCacheStorageNotAllowed];
                }
                else {
                    // No local copy found, so download from server.
                    IFHTTPClient *httpClient = self.authority.provider.httpClient;
                    [httpClient getFile:url]
                    .then((id)^(IFHTTPClientResponse *httpResponse) {
                        NSString *downloadPath = [httpResponse.downloadLocation path];
                        NSError *error = nil;
                        // If cachable then move file to cache.
                        if (cachable) {
                            [[NSFileManager defaultManager] moveItemAtPath:downloadPath
                                                                    toPath:cachePath
                                                                     error:&error];
                        }
                        if (error) {
                            [response respondWithError:error];
                        }
                        else {
                            // Respond with file contents.
                            NSString *contentPath = cachable ? cachePath : downloadPath;
                            [response respondWithFileData:contentPath
                                                 mimeType:mimeType
                                              cachePolicy:NSURLCacheStorageNotAllowed];
                        }
                    })
                    .fail(^(id error) {
                        // TODO
                    });
                }
            }
            else {
                [response respondWithError:makeUnsupportedTypeResponseError(type)];
            }
        }
    }
    else {
        [response respondWithJSONData:content cachePolicy:NSURLCacheStorageNotAllowed];
    }
}

#pragma mark - IFContentAuthorityPathRoot

- (void)writeResponse:(id<IFContentAuthorityResponse>)response
         forAuthority:(NSString *)authority
                 path:(IFContentPath *)path
           parameters:(NSDictionary *)parameters {
    
    if ([path isEmpty]) {
        NSString *type = [path ext];
        NSArray *content = [self queryWithParameters:parameters];
        [self writeQueryContent:content asType:type toResponse:response];
    }
    else if ([[path components] count] == 1) {
        // Content path specifies a resource. The resource identifier may be in the format
        // {key}.{type}, so following code attempts to break the identifier into these parts.
        NSString *key = [path root];
        NSString *type = [path ext];

        NSDictionary *entry = [self entryWithKey:key];
        [self writeEntryContent:entry asType:type toResponse:response];

    }
    else {
        // Invalid path.
        [response respondWithError:makeInvalidPathResponseError([path fullPath])];
    }
}

@end
