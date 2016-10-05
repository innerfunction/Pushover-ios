//
//  IFMIMETypes.h
//  Pushover
//
//  Created by Julian Goacher on 30/09/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Utility class providing mappings from standard file types to MIME type descriptors.
@interface IFMIMETypes : NSObject

/// Return the full MIME type of the specified file type.
+ (NSString *)mimeTypeForType:(NSString *)type;

@end
