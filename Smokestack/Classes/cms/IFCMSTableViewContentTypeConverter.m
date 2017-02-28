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
//  Created by Julian Goacher on 04/10/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFCMSTableViewContentTypeConverter.h"

@implementation IFCMSTableViewContentTypeConverter

#pragma mark - IFContentTypeConverter

- (void)writeContent:(id)content toResponse:(id<IFContentAuthorityResponse>)response {
    NSMutableArray *tableData = [NSMutableArray new];
    for (NSDictionary *contentItem in (NSArray *)content) {
        // TODO Handling of nil items
        // TODO This input assumes a post query, should be reflected in naming? What about none-post queries?
        // TODO How to define action.
        NSDictionary *rowItem = @{
            @"title":       contentItem[@"post.title"],
            @"description": contentItem[@"post.body"],
            @"image":       contentItem[@"post.image"],
            @"action":      @""
        };
        [tableData addObject:rowItem];
    }
    [response respondWithJSONData:tableData cachePolicy:NSURLCacheStorageNotAllowed];
}

@end
