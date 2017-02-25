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
//  Created by Julian Goacher on 10/03/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import "IFRegExp.h"

@implementation IFRegExp

- (id)initWithPattern:(NSString *)pattern {
    if (self = [super init]) {
        regex = [NSRegularExpression regularExpressionWithPattern:pattern 
                                                          options:0
                                                            error:nil];
    }
    return self;
}

- (id)initWithPattern:(NSString *)pattern options:(NSRegularExpressionOptions)options {
    if (self = [super init]) {
        regex = [NSRegularExpression regularExpressionWithPattern:pattern 
                                                          options:options
                                                            error:nil];
    }
    return self;
}

- (NSArray *)match:(NSString *)string {
    NSMutableArray *groups = nil;
    NSArray *matches = [regex matchesInString:string options:0 range:NSMakeRange(0, [string length])];
    if ([matches count] > 0) {
        NSTextCheckingResult *match = [matches objectAtIndex:0];
        NSUInteger groupCount = match.numberOfRanges;
        groups = [NSMutableArray arrayWithCapacity:groupCount];
        for (NSUInteger g = 0; g < groupCount; g++) {
            NSRange groupRange = [match rangeAtIndex:g];
            // NSRegularExpressions seems to behave oddly sometimes when returning optional groups - in one
            // case it was found when a group didn't match that the length was 0 but the offset was 2^32 -
            // which obviously caused an error - so only extract the matching substring if length is > 0,
            // otherwise just insert an empty string for the matching group.
            if (groupRange.length > 0) {
                [groups addObject:[string substringWithRange:[match rangeAtIndex:g]]];
            }
            else {
                [groups addObject:@""];
            }
        }
    }
    return groups;
}

- (NSRange)rangeOfFirstMatch:(NSString *)string {
    return [regex firstMatchInString:string options:0 range:NSMakeRange(0, [string length])].range;
}

- (BOOL)matches:(NSString *)string {
    NSRange range = [self rangeOfFirstMatch:string];
    return range.location != NSNotFound && range.length > 0;
}

+ (BOOL)pattern:(NSString *)pattern matches:(NSString *)string {
    IFRegExp *re = [[IFRegExp alloc] initWithPattern:pattern];
    return [re matches:string];
}

@end
