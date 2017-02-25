//
//  IFURIValueFormatter.h
//  SemoCore
//
//  Created by Julian Goacher on 13/04/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFCompoundURI.h"

@protocol IFURIValueFormatter <NSObject>

/** Format a value deferenced from a URI. */
- (id)formatValue:(id)value fromURI:(IFCompoundURI *)uri;

@end
