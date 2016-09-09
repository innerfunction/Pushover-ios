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
#import "IFAbstractContentContainer.h"
#import "NSDictionary+IFValues.h"

@interface IFWPPostsPathRoot()

void writeStringResponse(id<IFContentContainerResponse> response, NSString *strData, NSString *mimeType);
void writeJSONResponse(id<IFContentContainerResponse> response, id jsonData);

@end

@implementation IFWPPostsPathRoot

- (id)initWithPostAdapter:(IFWPPostDBAdapter *)postAdapter {
    self = [super init];
    if (self) {
        _postAdapter = postAdapter;
    }
    return self;
}

#pragma mark - IFContentContainerPathRoot

- (void)writeResponse:(id<IFContentContainerResponse>)response
         forAuthority:(NSString *)authority
                 path:(IFContentPath *)path
           parameters:(NSDictionary *)params {
    
    // Check for an invalid request path.
    if ([path isEmpty]) {
        [response respondWithError:makeInvalidPathResponseError([path fullPath])];
        return;
    }
    
    // Parse the request path and resolve the data.
    /*
     posts/all                  list, JSON
     posts/xxx                  posts: dict, JSON; attachments: data, source MIME type
     posts/xxx.html             string, HTML
     posts/xxx.url              string, remote URL
     posts/xxx.json             dict, JSON
     posts/xxx/children         list, JSON
     posts/xxx/descendants      list, JSON
     search                     list, JSON
     */
    NSArray *components = [path components];
    NSString *rscID = components[0];
    if ([@"all" isEqualToString:rscID]) {
        if ([components count] == 1) {
            // e.g. content://{authority}/posts/all
            id content = [_postAdapter queryPostsUsingFilter:nil params:params];
            writeJSONResponse(response, content);
        }
        else {
            [response respondWithError:makeInvalidPathResponseError([path fullPath])];
        }
    }
    else if ([@"search" isEqualToString:rscID]) {
        if ([components count] == 1) {
            // e.g. content://{authority}/search
            NSString *text = params[@"text"];
            NSString *mode = params[@"mode"];
            NSArray *postTypes = nil;
            NSString *types = params[@"types"];
            if (types) {
                postTypes = [types componentsSeparatedByString:@","];
            }
            NSString *parent = params[@"parent"];
            id content = [_postAdapter searchPostsForText:text
                                               searchMode:mode
                                                postTypes:postTypes
                                               parentPost:parent];
            writeJSONResponse(response, content);
        }
        else {
            [response respondWithError:makeInvalidPathResponseError([path fullPath])];
        }
    }
    else {
        // The resource ID might be in the form xxx.ext, (where xxx is a post ID, and
        // .ext is a file extension indicating the required type).
        NSArray *rscIDParts = [rscID componentsSeparatedByString:@"."];
        NSString *postID = rscIDParts[0];
        NSString *type = nil;
        if ([rscIDParts count] > 1) {
            type = rscIDParts[1];
        }
        if ([components count] == 2) {
            // e.g. content://{authority}/posts/{id}.{type}
            // TODO this section this to handle cases where the content is located remotely, e.g.
            // attachment posts where the associated file hasn't yet been downloaded.
            /*
             * Get post data
             * Decide on post type:
             *      type == nil:
             *          postType == attachment => attachment file type
             *          :else => json
             *      type != html or json:
             *          => confirm postType == attachment and file type is available
             * If type == json:
             *      as getPost:
             * If type == html:
             *      as json, return html portion
             * :else
             *      if file downloaded:
             *          copy file content to response
             *      :else
             *          download file
             *          if should be cached locally then write content to cache location
             *          copy file content to response
             */
            NSDictionary *postData = [_postAdapter getPostData:postID];
            NSString *postType = [postData getValueAsString:@"type"];
            NSString *filename = [postData getValueAsString:@"filename"];
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
                id json = [_postAdapter renderPostData:postData];
                writeJSONResponse(response, json);
            }
            else if ([@"html" isEqualToString:type]) {
                NSDictionary *json = [_postAdapter renderPostData:postData];
                NSString *html = json[@"content"];
                writeStringResponse(response, html, @"text/html");
            }
            else if (type) {
                // Check if attachment file is downloaded:
                //  => copy file content to response
                // Else:
                //  => download file; file local copy if cacheable; write to response;
            }
            else {
                [response respondWithError:makePathNotFoundResponseError([path fullPath])];
            }
        }
        else if ([components count] == 3) {
            NSString *filter = components[2];
            if ([@"children" isEqualToString:filter]) {
                // e.g. content://{authority}/posts/{id}/children
                id content = [_postAdapter getPostChildren:postID withParams:params];
                writeJSONResponse(response, content);
            }
            else if ([@"descendants" isEqualToString:filter]) {
                // e.g. content://{authority}/posts/{id}/descendants
                id content = [_postAdapter getPostDescendants:postID withParams:params];
                writeJSONResponse(response, content);
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

void writeStringResponse(id<IFContentContainerResponse> response, NSString *strData, NSString *mimeType) {
    NSData *data = [strData dataUsingEncoding:NSUTF8StringEncoding];
    [response respondWithMimeType:mimeType
               cacheStoragePolicy:NSURLCacheStorageNotAllowed
                             data:data];
}

void writeJSONResponse(id<IFContentContainerResponse> response, id jsonData) {
    NSData *data = [NSJSONSerialization dataWithJSONObject:jsonData
                                                   options:0
                                                     error:nil];
    [response respondWithMimeType:@"application/json"
               cacheStoragePolicy:NSURLCacheStorageNotAllowed
                             data:data];
}

@end
