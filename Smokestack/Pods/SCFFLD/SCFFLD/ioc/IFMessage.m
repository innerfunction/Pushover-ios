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

#import "IFMessage.h"

@implementation IFMessage

- (id)initWithTarget:(NSString *)target name:(NSString *)name parameters:(NSDictionary *)parameters {
    self = [super init];
    if (self) {
        _target = target;
        _targetPath = [target componentsSeparatedByString:@"/"];
        if ([_targetPath count] > 0 && [[_targetPath objectAtIndex:0] isEqualToString:@""]) {
            _targetPath = [_targetPath subarrayWithRange:NSMakeRange(1, [_targetPath count] - 1)];
        }
        _name = name;
        _parameters = parameters;
    }
    return self;
}

- (id)initWithTargetPath:(NSArray *)targetPath name:(NSString *)name parameters:(NSDictionary *)parameters {
    self = [super init];
    if (self) {
        _target = [targetPath componentsJoinedByString:@"/"];
        _targetPath = targetPath;
        _name = name;
        _parameters = parameters;
    }
    return self;
}

- (BOOL)hasEmptyTarget {
    return [_targetPath count] == 0;
}

- (BOOL)hasTarget:(NSString *)target {
    return [_target isEqualToString:target];
}

- (NSString *)targetHead {
    return [_targetPath count] > 0 ? [_targetPath firstObject] : nil;
}

- (IFMessage *)popTargetHead {
    if ([_targetPath count] > 0) {
        NSRange subpathRange = NSMakeRange(1, [_targetPath count] - 1);
        NSArray * subpath = [_targetPath subarrayWithRange:subpathRange];
        return [[IFMessage alloc] initWithTargetPath:subpath name:_name parameters:_parameters];
    }
    return nil;
}

- (BOOL)hasName:(NSString *)name {
    return [_name isEqualToString:name];
}

- (id)parameterValue:(NSString *)name {
    return [_parameters valueForKey:name];
}

@end
