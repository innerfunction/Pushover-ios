//
//  IFMIMETypes.m
//  Pushover
//
//  Created by Julian Goacher on 30/09/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFMIMETypes.h"

static NSDictionary *IFMIMETypes_lookup;

@implementation IFMIMETypes

+  (void)initialize {
    IFMIMETypes_lookup = @{
        @"html":    @"text/html",
        @"json":    @"application/json",
        @"png":     @"image/png",
        @"jpg":     @"image/jpg",
        @"jpeg":    @"image/jpeg",
        @"gif":     @"image/gif"
    };
}

+ (NSString *)mimeTypeForType:(NSString *)type {
    NSString *mimeType = IFMIMETypes_lookup[type];
    if (!mimeType) {
        mimeType = @"application/octet-stream";
    }
    return mimeType;
}

@end
