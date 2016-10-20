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
//  Created by Julian Goacher on 30/09/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFCMSPostsPathRoot.h"
#import "IFCMSFileset.h"
#import "IFCMSContentAuthority.h"
#import "NSDictionary+IF.h"
#import "GRMustache.h"
#import "IFLogger.h"

static IFLogger *Logger;

@implementation IFCMSPostsPathRoot

+ (void)initialize {
    Logger = [[IFLogger alloc] initWithTag:@"IFCMSPostsPathRoot"];
}

- (NSString *)renderPostContent:(NSDictionary *)postData {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *postType = postData[@"posts.type"];
    NSString *postHTML;
    NSString *clientTemplatePath = nil;
    NSString *templatePath = [self.fileDB cacheLocationForFileset:@"templates"];
    if (templatePath) {
        // Resolve the client template to use to render the post.
        NSString *clientTemplateFilename = [NSString stringWithFormat:@"template-posts-%@.html", postType];
        clientTemplatePath = [templatePath stringByAppendingPathComponent:clientTemplateFilename];
        if (![fileManager fileExistsAtPath:clientTemplatePath]) {
            clientTemplatePath = [templatePath stringByAppendingPathComponent:@"template-posts.html"];
            if (![fileManager fileExistsAtPath:clientTemplatePath]) {
                [Logger warn:@"Client template not found for post type %@", postType];
                clientTemplatePath = nil;
            }
        }
    }
    else {
        [Logger warn:@"Templates fileset not found"];
    }
    if (clientTemplatePath) {
        // Load the template and render the post.
        NSString *template = [NSString stringWithContentsOfFile:clientTemplatePath encoding:NSUTF8StringEncoding error:nil];
        NSError *error;
        // TODO: Investigate using template repositories to load templates
        // https://github.com/groue/GRMustache/blob/master/Guides/template_repositories.md
        // as they should allow partials to be used within templates, whilst supporting the two
        // use cases of loading templates from file (i.e. for full post html) or evaluating
        // a template from a string (i.e. for post content only).
        postHTML = [GRMustacheTemplate renderObject:postData fromString:template error:&error];
        if (error) {
            [Logger error:@"Rendering %@: %@", clientTemplatePath, error];
        }
    }
    if (!postHTML) {
        // If failed to render content then return a default rendering of the post body.
        NSString *postBody = postData[@"posts.body"];
        postHTML = [NSString stringWithFormat:@"<html>%@</html>", postBody];
    }
    return postHTML;
}

- (void)writeEntryContent:(NSDictionary *)content asType:(NSString *)type toResponse:(id<IFContentAuthorityResponse>)response {
    NSString *postHTML = [self renderPostContent:content];
    if ([@"html" isEqualToString:type]) {
        [response respondWithStringData:postHTML mimeType:@"text/html" cachePolicy:NSURLCacheStorageNotAllowed];
    }
    else {
        content = [content extendWith:@{ @"postHTML": postHTML }];
        [super writeEntryContent:content asType:type toResponse:response];
    }
}

@end
