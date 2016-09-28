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
//  Created by Julian Goacher on 09/09/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFWPContentAuthority.h"
#import "IFIOCContainerAware.h"

/**
 * An adapater for the posts DB providing specific methods for data access.
 */
@interface IFWPPostDBAdapter : NSObject <IFIOCContainerAware> {
    /// The content container.
    IFWPContentAuthority *_container;
    /// The file manager.
    NSFileManager *_fileManager;
}

@property (nonatomic, weak) IFDB *postDB;

/** Return a posts record from the posts DB. */
- (NSDictionary *)getPostData:(NSString *)postID;

/** Render the post content for the post with the specified ID. */
- (id)renderPostWithID:(NSString *)postID;

/** Render the post content from the specified post data. */
- (id)renderPostData:(NSDictionary *)postData;

/** Return the child posts of a specified post. Doesn't render the post content. */
- (id)getPostChildren:(NSString *)postID withParams:(NSDictionary *)params;

/** Return the child posts of a specified post. Optionally renders the post content. */
- (id)getPostChildren:(NSString *)postID withParams:(NSDictionary *)params renderContent:(BOOL)renderContent;

/** Get all descendants of a post. Returns the posts children, grandchildren etc. */
- (id)getPostDescendants:(NSString *)postID withParams:(NSDictionary *)params;

/** Query the post database using a predefined filter. */
- (id)queryPostsUsingFilter:(NSString *)filterName params:(NSDictionary *)params;

/**
 * Search the post database for the specified text in the specified post types with an optional parent post.
 * When the parent post ID is specified, the search will be confined to that post and any of its descendants
 * (i.e. children, grand-children etc.).
 */
- (id)searchPostsForText:(NSString *)text searchMode:(NSString *)searchMode postTypes:(NSArray *)postTypes parentPost:(NSString *)parentID;

/** Render a post's content by evaluating template reference's within the content field. */
- (NSDictionary *)renderPostContent:(NSDictionary *)postData;

@end
