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
//  Created by Julian Goacher on 06/04/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//
//
//  IFJSONData.h
//  SemoCore
//
//  Created by Julian Goacher on 30/07/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Interface for representing JSON object data.
 * The purpose of this interface is to act as a marker on properties that
 * will accept raw, unprocessed JSON data from a configuration. The class
 * is a direct subclass of NSDictionary and provides no additional
 * functionality.
 */
@interface IFJSONObject : NSDictionary {
    NSDictionary *_properties;
}

- (id)initWithDictionary:(NSDictionary *)otherDictionary;

@end

/**
 * Interface for representing JSON array data.
 * The purpose of this interface is to act as a marker on properties that
 * will accept raw, unprocessed JSON data from a configuration. The class
 * is a direct subclass of NSArray and provides no additional functionality.
 */
@interface IFJSONArray : NSArray {
    NSArray *_items;
}

- (id)initWithArray:(NSArray *)array;

@end