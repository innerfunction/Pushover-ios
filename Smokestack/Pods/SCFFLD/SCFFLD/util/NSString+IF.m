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
//  Created by Julian Goacher on 28/06/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import "NSString+IF.h"
#import "IFRegExp.h"

@implementation NSString (IF)

- (NSInteger)indexOf:(NSString *)str {
    NSRange range = [self rangeOfString:str];
    return range.location == NSNotFound ? -1 : range.location;
}

- (NSString *)substringFromIndex:(NSUInteger)from toIndex:(NSUInteger)to {
    return [[self substringToIndex:to] substringFromIndex:from];
}

- (NSArray *)split:(NSString *)pattern {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    IFRegExp *re = [[IFRegExp alloc] initWithPattern:pattern];
    NSString *string = self;
    NSRange range = [re rangeOfFirstMatch:string];
    // Use range.length > 0 instead of range.location != NSNotFound here
    // See http://stackoverflow.com/questions/9210337/nscheckingresult-range-property-not-set-to-nsnotfound-0
    while (range.length > 0 && [string length]) {
        [result addObject:[string substringToIndex:range.location]];
        string = [string substringFromIndex:range.location + range.length];
        range = [re rangeOfFirstMatch:string];
    }
    [result addObject:string];
    return result;
}

- (NSString *)replaceAllOccurrences:(NSString *)pattern with:(NSString *)replacement {
    IFRegExp *re = [[IFRegExp alloc] initWithPattern:pattern];
    NSString *string = self;
    NSString *result = @"";
    NSRange range = [re rangeOfFirstMatch:string];
    while (range.length > 0 && [string length]) {
        result = [result stringByAppendingString:[string substringToIndex:range.location]];
        result = [result stringByAppendingString:replacement];
        string = [string substringFromIndex:(range.location + range.length)];
        range = [re rangeOfFirstMatch:string];
    }
    result = [result stringByAppendingString:string];
    return result;
}

- (id)parseJSON:(NSError *)error {
    return [NSJSONSerialization JSONObjectWithData:[self dataUsingEncoding:NSUTF8StringEncoding]
                                           options:0
                                             error:&error];
}

@end
