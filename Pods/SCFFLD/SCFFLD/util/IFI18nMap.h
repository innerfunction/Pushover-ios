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
//  Created by Julian Goacher on 23/07/2014.
//  Copyright (c) 2014 Julian Goacher. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * An object providing a key-coding type interface for accessing localized strings.
 * Example:
 *
 *     IFI18nMap *i18n = [IFI18nMap instance];
 *     NSString *localizedLabel = i18n[@"labelKey"];
 */
@interface IFI18nMap : NSObject

/**
 * Resolve a key value by returning the localized version of the string _key_.
 * @param key   A localized resource key.
 * @return The string value of the localized resource, or _nil_ if the resource isn't found.
 */
- (id)valueForKey:(NSString *)key;

/**
 * Get the singleton instance of the class.
 */
+ (IFI18nMap *)instance;

@end
