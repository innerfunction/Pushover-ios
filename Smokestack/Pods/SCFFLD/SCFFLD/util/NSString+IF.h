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

#import <Foundation/Foundation.h>

@interface NSString (IF)

- (NSInteger)indexOf:(NSString *)str;

- (NSString *)substringFromIndex:(NSUInteger)from toIndex:(NSUInteger)to;

- (NSArray *)split:(NSString *)pattern;

- (NSString *)replaceAllOccurrences:(NSString *)pattern with:(NSString *)string;

- (id)parseJSON:(NSError *)error;

@end
