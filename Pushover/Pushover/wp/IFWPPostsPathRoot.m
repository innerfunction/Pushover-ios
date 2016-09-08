//
//  IFWPPostsPathRoot.m
//  Pushover
//
//  Created by Julian Goacher on 08/09/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFWPPostsPathRoot.h"
#import "IFAbstractContentContainer.h"

@implementation IFWPPostsPathRoot

- (id)initWithContentContainer:(IFWPContentContainer *)contentContainer {
    self = [super init];
    if (self) {
        _contentContainer = contentContainer;
    }
    return self;
}

#pragma mark - IFContentContainerPathRoot


- (void)writeResponse:(id<IFContentContainerResponse>)response
         forAuthority:(NSString *)authority
                 path:(NSArray *)path
           parameters:(NSDictionary *)parameters {
    
    if ([path count] == 0) {
        [response respondWithError:makeInvalidPathResponseError()];
        return;
    }
    
    id content = nil;
    NSString *resourceID = [path firstObject];
    NSString *modifier;
    switch ([path count]) {
        case 1:
            if ([@"all" isEqualToString:resourceID]) {
                // e.g. content://{authority}/posts/all
                content = [_contentContainer queryPostsUsingFilter:nil params:parameters];
            }
            else {
                // e.g. content://{authority}/posts/{id}
                // TODO extensions, e.g. .html, .json, .url, .png/.jpg or .bin? .data?
                content = [_contentContainer getPost:resourceID withParams:parameters];
            }
            break;
        case 2:
            modifier = path[1];
            if ([@"children" isEqualToString:modifier]) {
                // e.g. content://{authority}/posts/{id}/children
                content = [_contentContainer getPostChildren:resourceID withParams:parameters];
            }
            else if ([@"descendants" isEqualToString:modifier]) {
                // e.g. content://{authority}/posts/{id}/descendants
                content = [_contentContainer getPostDescendants:resourceID withParams:parameters];
            }
            break;
        default:
            [response respondWithError:makeInvalidPathResponseError()];
            return;
    }
}

@end
