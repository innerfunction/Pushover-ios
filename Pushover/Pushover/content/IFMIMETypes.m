//
//  IFMIMETypes.m
//  Pushover
//
//  Created by Julian Goacher on 30/09/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFMIMETypes.h"

@implementation IFMIMETypes

+ (NSString *)mimeTypeForType:(NSString *)type {
    if ([@"html" isEqualToString:type]) {
        return @"text/html";
    }
    if ([@"json" isEqualToString:type]) {
        return @"application/json";
    }
    if ([@"png" isEqualToString:type]) {
        return @"image/png";
    }
    if ([@"jpg" isEqualToString:type] || [@"jpeg" isEqualToString:type]) {
        return @"image/jpeg";
    }
    if ([@"gif" isEqualToString:type]) {
        return @"image/gif";
    }
    return @"application/octet-stream";
}

@end
