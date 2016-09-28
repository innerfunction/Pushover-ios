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
//  Created by Julian Goacher on 08/09/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFWPPostsPathRoot.h"
#import "IFAbstractContentAuthority.h"

@interface IFWPPostsPathRoot()

/// Return the MIME type for a specified request type.
NSString *mimeTypeForType(NSString *type);
/// Return an NSError object generated from the function argument.
NSError *errorFromResponseError(id error);

@end

@implementation IFWPPostsPathRoot

- (id)init {
    self = [super init];
    if (self) {
        _fileManager = [NSFileManager defaultManager];
    }
    return self;
}

#pragma mark - IFContentAuthorityPathRoot

- (void)writeResponse:(id<IFContentAuthorityResponse>)response
         forAuthority:(NSString *)authority
                 path:(IFContentPath *)path
           parameters:(NSDictionary *)params {
    
    // Parse the request path and resolve the data.
    /*
     posts                      Same as posts/all
     posts/all                  list, JSON
     posts/xxx                  posts: dict, JSON; attachments: data, source MIME type
     posts/xxx.html             string, HTML
     posts/xxx.url              string, remote URL
     posts/xxx.json             dict, JSON
     posts/xxx/children         list, JSON
     posts/xxx/descendants      list, JSON
     */
    NSString *rscID = @"all";
    NSArray *components = [path components];
    if ([components count]) {
        rscID = components[0];
    }

    if ([@"all" isEqualToString:rscID]) {
        if ([components count] == 1) {
            // e.g. content://{authority}/posts/all
            id content = [_postDBAdapter queryPostsUsingFilter:nil params:params];
            [response respondWithJSONData:content cachePolicy:NSURLCacheStorageNotAllowed];
        }
        else {
            // Trailing path after /all
            [response respondWithError:makeInvalidPathResponseError([path fullPath])];
        }
    }
    else {
        // The resource ID may be in the form xxx.ext, where xxx is a post ID, and .ext
        // is a file extension indicating the required type. If no file extension is
        // specified then a default type will be inferred from the post type.
        NSArray *rscIDParts = [rscID componentsSeparatedByString:@"."];
        NSString *postID = rscIDParts[0];
        NSString *type = nil;
        if ([rscIDParts count] > 1) {
            type = rscIDParts[1];
        }
        if ([components count] == 2) {
            // e.g. content://{authority}/posts/{id}.{type}
            // Read the post data.
            NSDictionary *postData = [_postDBAdapter getPostData:postID];
            NSString *postType = postData[@"type"];
            NSString *filename = postData[@"filename"];
            NSString *url = postData[@"url"];
            // Check which representation of the post to return by examining the type.
            if (!type) {
                // No type specified, decide what is the default type.
                if ([@"attachment" isEqualToString:postType]) {
                    // For attachments, use the attachment file's type.
                    type = [filename pathExtension];
                }
                else {
                    // For all other posts, return the post's JSON representation.
                    type = @"json";
                }
            }
            else if (!([@"html" isEqualToString:type] || [@"json" isEqualToString:type])) {
                // A type is specified which is neither html nor json; check that the post is an
                // attachment with a file of the specified type.
                if (!([@"attachment" isEqualToString:postType] && [type isEqualToString:[filename pathExtension]])) {
                    type = nil; // Can't resolve requested type.
                }
            }
            
            // Resolve the content data and write the response.
            if ([@"json" isEqualToString:type]) {
                id json = [_postDBAdapter renderPostData:postData];
                [response respondWithJSONData:json cachePolicy:NSURLCacheStorageNotAllowed];
            }
            else if ([@"html" isEqualToString:type]) {
                NSDictionary *json = [_postDBAdapter renderPostData:postData];
                NSString *html = json[@"content"];
                [response respondWithStringData:html mimeType:@"text/html" cachePolicy:NSURLCacheStorageNotAllowed];
            }
            else if ([@"url" isEqualToString:type]) {
                // TODO What are the precise use cases for this type? Should the file: URL of a locally cached
                // copy be returned, when available? Should the referenced resource be downloaded and then it's
                // local file: URL be returned, when not cached and caching is allowed?
                [response respondWithStringData:url mimeType:@"text/url" cachePolicy:NSURLCacheStorageNotAllowed];
            }
            else if (type) {
                NSString *mimeType = mimeTypeForType(type);
                NSString *location = postData[@"location"];
                if ([@"packaged" isEqualToString:location]) {
                    // This is used for content which is packaged with the app, and which is unpacked to a
                    // filesystem location when the app is installed.
                    NSString *filepath = [_packagedContentPath stringByAppendingPathComponent:filename];
                    if ([_fileManager fileExistsAtPath:filepath]) {
                        [response respondWithFileData:filepath mimeType:mimeType cachePolicy:NSURLCacheStorageNotAllowed];
                    }
                    else {
                        [response respondWithError:makePathNotFoundResponseError([path fullPath])];
                    }
                }
                else if ([@"downloaded" isEqualToString:location]) {
                    // This is used for attachment data which may be downloaded from the server and cached
                    // locally. Check if a cached copy of the file exists locally, otherwise download from
                    // the server and add to cache.
                    NSString *filepath = [_contentPath stringByAppendingPathComponent:filename];
                    if ([_fileManager fileExistsAtPath:filepath]) {
                        [response respondWithFileData:filepath mimeType:mimeType cachePolicy:NSURLCacheStorageNotAllowed];
                    }
                    else {
                        [_httpClient getFile:url]
                        .then((id)^(IFHTTPClientResponse *httpResponse) {
                            NSError *error = nil;
                            [_fileManager moveItemAtPath:httpResponse.downloadLocation.path
                                                  toPath:filepath
                                                   error:&error];
                            if (!error) {
                                [response respondWithFileData:filepath mimeType:mimeType cachePolicy:NSURLCacheStorageNotAllowed];
                            }
                            else {
                                [response respondWithError:error];
                            }
                            return nil;
                        })
                        .fail(^(id responseError) {
                            NSError *error = errorFromResponseError(responseError);
                            [response respondWithError:error];
                        });
                    }
                }
                else if ([@"server" isEqualToString:location]) {
                    // This is used for attachment data which must be kept on the server.
                    [_httpClient getFile:url]
                    .then((id)^(IFHTTPClientResponse *httpResponse) {
                        [response respondWithFileData:httpResponse.downloadLocation.path
                                             mimeType:mimeType
                                          cachePolicy:NSURLCacheStorageNotAllowed];
                        return nil;
                    })
                    .fail(^(id responseError) {
                        NSError *error = errorFromResponseError(responseError);
                        [response respondWithError:error];
                    });
                }
                else {
                    // TODO log invalid location
                    [response respondWithError:makePathNotFoundResponseError([path fullPath])];
                }
            }
            else {
                [response respondWithError:makePathNotFoundResponseError([path fullPath])];
            }
        }
        else if ([components count] == 3) {
            NSString *filter = components[2];
            if ([@"children" isEqualToString:filter]) {
                // e.g. content://{authority}/posts/{id}/children
                id content = [_postDBAdapter getPostChildren:postID withParams:params];
                [response respondWithJSONData:content cachePolicy:NSURLCacheStorageNotAllowed];
            }
            else if ([@"descendants" isEqualToString:filter]) {
                // e.g. content://{authority}/posts/{id}/descendants
                id content = [_postDBAdapter getPostDescendants:postID withParams:params];
                [response respondWithJSONData:content cachePolicy:NSURLCacheStorageNotAllowed];
            }
            else {
                [response respondWithError:makeInvalidPathResponseError([path fullPath])];
            }
        }
        else {
            [response respondWithError:makeInvalidPathResponseError([path fullPath])];
        }
    }
}

NSString *mimeTypeForType(NSString *type) {
    if ([@"html" isEqualToString:type]) {
        return @"text/html";
    }
    if ([@"json" isEqualToString:type]) {
        return @"application/json";
    }
    if ([@"png" isEqualToString:type]) {
        return @"image/png";
    }
    if ([@"jpg" isEqualToString:type] || [@"jpeg" isEqualToString:type]) {
        return @"image/jpeg";
    }
    if ([@"gif" isEqualToString:type]) {
        return @"image/gif";
    }
    return @"application/octet-stream";
}

NSError *errorFromResponseError(id responseError) {
    if ([responseError isKindOfClass:[NSError class]]) {
        return (NSError *)responseError;
    }
    NSString *description = [responseError description];
    return [NSError errorWithDomain:NSURLErrorDomain
                               code:NSURLErrorUnknown
                           userInfo:@{ NSLocalizedDescriptionKey: description }];
}

@end
