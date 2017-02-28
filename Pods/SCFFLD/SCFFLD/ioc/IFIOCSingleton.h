//
//  IFIOCSingleton.h
//  SCFFLD
//
//  Created by Julian Goacher on 28/09/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * A protocol implemented by classes which implement the singleton pattern.
 * Allows the IOC container to detect singleton classes and to access the singleton member
 * rather than insantiating a new class instance.
 */
@protocol IFIOCSingleton

/// Static method returning the singleton instance of the class.
+ (id)iocSingleton;

@end
