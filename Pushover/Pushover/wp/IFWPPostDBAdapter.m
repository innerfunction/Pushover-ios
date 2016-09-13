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

#import "IFWPPostDBAdapter.h"
#import "IFDBFilter.h"
#import "IFWPClientTemplateContext.h"
#import "IFDataFormatter.h"
#import "IFRegExp.h"
#import "IFLogger.h"
#import "NSDictionary+IFValues.h"
#import "NSDictionary+IF.h"
#import "GRMustache.h"

static IFLogger *Logger;

@interface IFWPPostDBAdapter()

/** Render a template with the specified data. */
- (NSString *)renderTemplate:(NSString *)template withData:(id)data;

@end

@implementation IFWPPostDBAdapter

- (id)init {
    self = [super init];
    if (self) {
        _fileManager = [NSFileManager defaultManager];
    }
    return self;
}

- (NSDictionary *)getPostData:(NSString *)postID {
    return [_postDB readRecordWithID:postID fromTable:@"posts"];
}

- (id)renderPostWithID:(NSString *)postID {
    NSDictionary *postData = [self getPostData:postID];
    return [self renderPostData:postData];
}

- (id)renderPostData:(NSDictionary *)postData {
    // Render the post content.
    postData = [self renderPostContent:postData];
    NSString *postID = postData[@"id"];
    // Load the client template for the post type.
    NSString *postType = postData[@"type"];
    NSString *templateName = [NSString stringWithFormat:@"template-%@.html", postType];
    NSString *templatePath = [_container.baseContentPath stringByAppendingPathComponent:templateName];
    if (![_fileManager fileExistsAtPath:templatePath isDirectory:nil]) {
        templatePath = [_container.baseContentPath stringByAppendingString:@"template-single.html"];
        if (![_fileManager fileExistsAtPath:templatePath isDirectory:nil]) {
            [Logger warn:@"Client template for post type '%@' not found at %@", postType, _container.baseContentPath];
            return nil;
        }
    }
    // Assume at this point that the template file exists.
    NSString *template = [NSString stringWithContentsOfFile:templatePath encoding:NSUTF8StringEncoding error:nil];
    // Generate the full post HTML using the post data and the client template.
    id context = [_container.clientTemplateContext templateContextForPostData:postData];
    // Render the post template
    NSString *postHTML = [self renderTemplate:template withData:context];
    // Generate a content URL within the base content directory - this to ensure that references to base
    // content can be resolved as relative references.
    NSString *separator = [_container.baseContentPath hasSuffix:@"/"] ? @"" : @"/";
    NSString *contentURL = [NSString stringWithFormat:@"file://%@%@%@-%@.html", _container.baseContentPath, separator, postType, postID ];
    // Add the post content and URL to the post data.
    postData = [postData extendWith:@{
        @"content":     postHTML,
        @"contentURL":  contentURL
    }];
    return postData;
}

- (id)queryPostsUsingFilter:(NSString *)filterName params:(NSDictionary *)params {
    id postData = nil;
    if (filterName) {
        IFDBFilter *filter = _container.filters[filterName];
        if (filter) {
            postData = [filter applyTo:_postDB withParameters:params];
        }
    }
    else {
        // Construct an anonymous filter instance.
        IFDBFilter *filter = [[IFDBFilter alloc] init];
        filter.table = @"posts";
        filter.orderBy = @"menu_order";
        // Construct a set of filter parameters from the URI parameters.
        IFRegExp *re = [[IFRegExp alloc] initWithPattern:@"^(\\w+)\\.(.*)"];
        NSMutableDictionary *filterParams = [[NSMutableDictionary alloc] init];
        // Ensure that only published posts are queried by default.
        filterParams[@"status"] = @"publish";
        for (NSString *paramName in [params allKeys]) {
            // The 'orderBy' parameter is a special name used to specify sort order.
            if ([@"_orderBy" isEqualToString:paramName]) {
                filter.orderBy = [params getValueAsString:@"_orderBy"];
                continue;
            }
            NSString *fieldName = paramName;
            NSString *paramValue = [params objectForKey:paramName];
            // Check for a comparison suffix on the name.
            NSArray *groups = [re match:paramName];
            if ([groups count] > 1) {
                fieldName = [groups objectAtIndex:0];
                NSString *comparison = [groups objectAtIndex:1];
                if ([@"min" isEqualToString:comparison]) {
                    paramValue = [NSString stringWithFormat:@">%@", paramValue];
                }
                else if ([@"max" isEqualToString:comparison]) {
                    paramValue = [NSString stringWithFormat:@"<%@", paramValue];
                }
                else if ([@"like" isEqualToString:comparison]) {
                    paramValue = [NSString stringWithFormat:@"LIKE %@", paramValue];
                }
                else if ([@"not" isEqualToString:comparison]) {
                    paramValue = [NSString stringWithFormat:@"NOT %@", paramValue];
                }
            }
            filterParams[fieldName] = paramValue;
        }
        // Remove any parameters not corresponding to a column on the posts table.
        filter.filters = [_postDB filterValues:filterParams forTable:@"posts"];
        // Apply the filter.
        postData = [filter applyTo:_postDB withParameters:@{}];
    }
    NSString *format = [params getValueAsString:@"_format" defaultValue:@"table"];
    id<IFDataFormatter> formatter = _container.listFormats[format];
    if (formatter) {
        postData = [formatter formatData:postData];
    }
    return postData;
}

- (id)getPostChildren:(NSString *)postID withParams:(NSDictionary *)params {
    return [self getPostChildren:postID withParams:params renderContent:NO];
}

- (id)getPostChildren:(NSString *)postID withParams:(NSDictionary *)params renderContent:(BOOL)renderContent {
    // Check the post type.
    NSDictionary *postData = [_postDB readRecordWithID:postID fromTable:@"posts"];
    NSString *postType = postData[@"type"];
    // Check for child type relations for this post type.
    id childTypes = _container.postTypeRelations[postType];
    if (childTypes) {
        params = [params extendWith:@{ @"type": childTypes }];
    }
    // Create the query.
    IFDBFilter *filter = [[IFDBFilter alloc] init];
    filter.table = @"posts";
    filter.filters = [params extendWith:@{ @"parent": postID }];
    filter.orderBy = @"menu_order";
    // Query the database.
    NSArray *result = [filter applyTo:_postDB withParameters:@{}];
    // Render content for each child post.
    if (renderContent) {
        NSMutableArray *posts = [NSMutableArray new];
        for (NSDictionary *row in result) {
            [posts addObject:[self renderPostContent:row]];
        }
        result = posts;
    }
    return result;
}

- (id)getPostDescendants:(NSString *)postID withParams:(NSDictionary *)params {
    NSArray *result = [_postDB performQuery:@"SELECT posts.* \
                       FROM posts, closures \
                       WHERE closures.parent=? AND closures.child=posts.id AND depth > 0 \
                       ORDER BY depth, parent, menu_order"
                                 withParams:@[ postID ]];
    BOOL renderContent = [@"true" isEqualToString:params[@"content"]];
    if (renderContent) {
        NSMutableArray *posts = [NSMutableArray new];
        for (NSDictionary *row in result) {
            [posts addObject:[self renderPostContent:row]];
        }
        result = posts;
    }
    /* TODO Add option to group posts by parent - sample code below, but grouping by direct parent may not make much
     sense for deeply nested descendents.
     NSMutableArray *groups = [NSMutableArray new];
     NSMutableArray *group = nil;
     id parent = nil;
     NSMutableDictionary *titles = [NSMutableDictionary new];
     for (NSDictionary *row in result) {
     id parent = row[@"parent"];
     if (parent) {
     titles[parent] = row[@"title"];
     }
     }
     for (NSDictionary *row in result) {
     id rowParent = row[@"parent"];
     if (![rowParent isEqual:parent]) {
     id groupTitle = titles[rowParent];
     group = [NSMutableArray new];
     [groups addObject:@{ @"sectionTitle": groupTitle, @"sectionData": group }];
     parent = rowParent;
     }
     [group addObject:row];
     }
     result = groups;
     }
     */
    return result;
}

- (id)searchPostsForText:(NSString *)text searchMode:(NSString *)searchMode postTypes:(NSArray *)postTypes parentPost:(NSString *)parentID {
    id postData = nil;
    NSString *tables = @"posts";
    NSString *where = nil;
    NSMutableArray *params = [NSMutableArray new];
    text = [NSString stringWithFormat:@"%%%@%%", text];
    if ([@"exact" isEqualToString:searchMode]) {
        where = @"title LIKE ? OR content LIKE ?";
        [params addObject:text];
        [params addObject:text];
    }
    else {
        NSMutableArray *terms = [NSMutableArray new];
        NSArray *tokens = [text componentsSeparatedByString:@" "];
        for (NSString *token in tokens) {
            // TODO: Trim the token, check for empty tokens.
            NSString *param = [NSString stringWithFormat:@"%%%@%%", token];
            [terms addObject:@"(title LIKE ? OR content LIKE ?)"];
            [params addObject:param];
            [params addObject:param];
        }
        if ([@"any" isEqualToString:searchMode]) {
            where = [terms componentsJoinedByString:@" OR "];
        }
        else if ([@"all" isEqualToString:searchMode]) {
            where = [terms componentsJoinedByString:@" AND "];
        }
    }
    if (postTypes && [postTypes count] > 0) {
        NSString *typeClause;
        if ([postTypes count] == 1) {
            typeClause = [NSString stringWithFormat:@"type='%@'", [postTypes firstObject]];
        }
        else {
            typeClause = [NSString stringWithFormat:@"type IN ('%@')", [postTypes componentsJoinedByString:@"','"]];
        }
        if (where) {
            where = [NSString stringWithFormat:@"(%@) AND %@", where, typeClause];
        }
        else {
            where = typeClause;
        }
    }
    if( !where ) {
        where = @"1=1";
    }
    if ([parentID length] > 0) {
        // If a parent post ID is specified then add a join to, and filter on, the closures table.
        tables = [tables stringByAppendingString:@", closures"];
        where = [where stringByAppendingString:@" AND closures.parent=? AND closures.child=posts.id"];
        [params addObject:parentID];
    }
    NSString *sql = [NSString stringWithFormat:@"SELECT posts.* FROM %@ WHERE %@ LIMIT %ld", tables, where, (long)_container.searchResultLimit];
    postData = [_postDB performQuery:sql withParams:params];
    // TODO: Filters?
    id<IFDataFormatter> formatter = _container.listFormats[@"search"];
    if (!formatter) {
        formatter = _container.listFormats[@"table"];
    }
    if (formatter) {
        postData = [formatter formatData:postData];
    }
    return postData;
}

- (NSDictionary *)renderPostContent:(NSDictionary *)postData {
    id context = [_container.clientTemplateContext templateContext];
    NSString *contentHTML = [self renderTemplate:postData[@"content"] withData:context];
    return [postData dictionaryWithAddedObject:contentHTML forKey:@"content"];
}

#pragma mark = IFIOCContainerAware

- (void)setIocContainer:(IFContainer *)iocContainer {
    _container = (IFWPContentContainer *)iocContainer;
}

- (IFContainer *)iocContainer {
    return _container;
}

- (void)beforeIOCConfiguration:(IFConfiguration *)configuration {}

- (void)afterIOCConfiguration:(IFConfiguration *)configuration {};

#pragma mark - Private methods

- (NSString *)renderTemplate:(NSString *)template withData:(id)data {
    NSError *error;
    // TODO: Investigate using template repositories to load templates
    // https://github.com/groue/GRMustache/blob/master/Guides/template_repositories.md
    // as they should allow partials to be used within templates, whilst supporting the two
    // use cases of loading templates from file (i.e. for full post html) or evaluating
    // a template from a string (i.e. for post content only).
    NSString *result = [GRMustacheTemplate renderObject:data fromString:template error:&error];
    if (error) {
        result = [NSString stringWithFormat:@"<h1>Template error</h1><pre>%@</pre>", error];
    }
    return result;
}

@end
