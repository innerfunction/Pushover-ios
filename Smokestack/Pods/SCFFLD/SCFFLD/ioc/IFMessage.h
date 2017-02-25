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
//  Created by Julian Goacher on 28/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * A message sent between two components within a container.
 */
@interface IFMessage : NSObject {
    /// The message target.
    NSString *_target;
    /// The message's target path split into path components.
    NSArray *_targetPath;
}

/// The message name.
@property (nonatomic, strong) NSString *name;
/// The message's parameters.
@property (nonatomic, strong) NSDictionary *parameters;

- (id)initWithTarget:(NSString *)target name:(NSString *)name parameters:(NSDictionary *)parameters;
- (id)initWithTargetPath:(NSArray *)targetPath name:(NSString *)name parameters:(NSDictionary *)parameters;
/** Test whether the message has an empty target. */
- (BOOL)hasEmptyTarget;
/** Test if the (entire) target matches the specified string. */
- (BOOL)hasTarget:(NSString *)target;
/** Get the target name at the head of the target path. */
- (NSString *)targetHead;
/**
 * Pop the head name from the target path and return a new message whose target path is the remainder.
 * Return nil if there is no trailing target path.
 */
- (IFMessage *)popTargetHead;
/** Test if the message has the specified name. */
- (BOOL)hasName:(NSString *)name;
/** Get a named action parameter value. */
- (id)parameterValue:(NSString *)name;

@end
