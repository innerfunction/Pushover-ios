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
#import "IFCMSContentAuthority.h"
#import "IFCMSFileset.h"
#import "IFDBORM.h"

@implementation IFCMSFilesetCategoryPathRoot

- (id)initWithFileset:(IFCMSFileset *)fileset container:(IFCMSContentAuthority *)container {
    self = [super init];
    if (self) {
        self.fileset = fileset;
        self.container = container;
    }
    return self;
}

- (void)setContainer:(IFCMSContentAuthority *)container {
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
    // TODO post query processing by type derived from path extension.
    [response respondWithJSONData:content cachePolicy:NSURLCacheStorageNotAllowed];
}

- (void)writeEntryContent:(NSDictionary *)content asType:(NSString *)type toResponse:(id<IFContentAuthorityResponse>)response {
    
    // NOTE Pushover CMS operation seems to be quite different to WP. Firstly, Pushover is
    // foremost a file-based CMS, and the file DB is a list of available files (see the
    // feed at http://semop.innerfunction.com/semop/0.1/updates/jloriente/gvg-test). This
    // suggests that posts be treated quite differently; the post html file should possibly
    // be generated completely server side, i.e. no client side template (this works with
    // Jekyll because of the nature of its operation; a theme change results in all post
    // files being modified, unlike with WP); and a posts table should be added as a 1:1
    // relation with the files table, holding information like post title etc.. However
    // note that this approach has a disadvantage - post content can't so easily be presented
    // within a list without the page surround - so the question instead is whether there
    // is an extensable, filesets-based method to add posts functionality to the basic
    // file database.
    
    // NOTE an ambiguity with the .json type; if the file entry is for an actual JSON file,
    // then should the contents of that file be returned (YES) or database record (NO). It
    // means that a separate type is needed for the actual data results (.data? .podata?)
    
    // NOTE it would be useful to allow certain JSON data formats - e.g. configuration formats
    // suitable for configuring a web view - to be specified with a content file extension -
    // they could then be defined as formatters on the container - question is what extension
    // names to use - and does this share any similarity with the previous point?
    
    // Return the result.
    if (!type) {
        [response respondWithJSONData:content cachePolicy:NSURLCacheStorageNotAllowed];
    }
    else {
        NSString *path = content[@"path"];
        if ([type isEqualToString:[path pathExtension]]) {
            NSString *status = content[@"status"];
            // Is file downloaded? -> return file contents
            // Else -> download file, cache if appropriate, return file contents
        }
        else {
            // Other conversions
        }
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
