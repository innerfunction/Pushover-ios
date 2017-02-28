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
//  Created by Julian Goacher on 28/03/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import "UIColor+IF.h"

@implementation UIColor (IF)

+ (UIColor *)colorForHex:(NSString *)hex {
	hex = [hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    hex = [hex uppercaseString];
    if ([hex hasPrefix:@"#"]) {
        hex = [hex substringFromIndex:1];
    }
    if ([hex length] < 6) {
        return [UIColor clearColor];
    }
    // Separate into r, g, b substrings
    NSRange range;
    range.length = 2;
    range.location = 0;
    NSString *red = [hex substringWithRange:range];
    range.location = 2;
    NSString *green = [hex substringWithRange:range];
    range.location = 4;
    NSString *blue = [hex substringWithRange:range];
    unsigned int a = 1;
    if (hex.length == 8) {
        range.location = 6;
        [[NSScanner scannerWithString:[hex substringWithRange:range]] scanHexInt:&a];
    }
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:red] scanHexInt:&r];
    [[NSScanner scannerWithString:green] scanHexInt:&g];
    [[NSScanner scannerWithString:blue] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float)r / 255.0f)
                           green:((float)g / 255.0f)
                            blue:((float)b / 255.0f)
                           alpha:(float)a];
}

@end
