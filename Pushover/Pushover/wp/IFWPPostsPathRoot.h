//
//  IFWPPostsPathRoot.h
//  Pushover
//
//  Created by Julian Goacher on 08/09/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFContentContainer.h"
#import "IFWPContentContainer.h"

@interface IFWPPostsPathRoot : NSObject <IFContentContainerPathRoot> {
    __weak IFWPContentContainer *_contentContainer;
}

- (id)initWithContentContainer:(IFWPContentContainer *)contentContainer;

@end
