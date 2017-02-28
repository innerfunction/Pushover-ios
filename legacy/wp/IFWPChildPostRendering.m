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
//  Created by Julian Goacher on 10/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFWPChildPostRendering.h"

@implementation IFWPChildPostRendering

- (IFContainer *)iocContainer {
    return _contentContainer;
}

- (void)setIocContainer:(IFContainer *)iocContainer {
    if ([iocContainer isKindOfClass:[IFWPContentAuthority class]]) {
        _contentContainer = (IFWPContentAuthority *)iocContainer;
    }
}

- (void)beforeIOCConfiguration:(IFConfiguration *)configuration {}

- (void)afterIOCConfiguration:(IFConfiguration *)configuration {}

- (NSString *)renderForMustacheTag:(GRMustacheTag *)tag
                           context:(GRMustacheContext *)context
                          HTMLSafe:(BOOL *)HTMLSafe
                             error:(NSError *__autoreleasing *)error {
    NSString *result = @"";
    // Get the in-scope post ID.
    NSString *postID = [context valueForMustacheKey:@"id"];
    if (postID) {
        // Read the list of child posts.
        NSArray *childPosts = [_contentContainer.postDBAdapter getPostChildren:postID withParams:@{} renderContent:YES];
        // Iterate and render each child post.
        for (id childPost in childPosts) {
            GRMustacheContext *childContext = [context contextByAddingObject:childPost];
            NSString *childHTML = [tag renderContentWithContext:childContext HTMLSafe:HTMLSafe error:error];
            if (*error) {
                NSString *errHTML = [NSString stringWithFormat:@"<pre class=\"error\">Template error: %@</pre>", *error];
                result = [result stringByAppendingString:errHTML];
                *error = nil;
            }
            result = [result stringByAppendingString:childHTML];
        }
    }
    *HTMLSafe = YES;
    return result;
}

@end
