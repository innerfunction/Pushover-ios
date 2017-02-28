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
//  Created by Julian Goacher on 13/03/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import "IFLocalSchemeHandler.h"

@implementation IFLocalResource

- (id)data {
    return [_storage objectForKey:_key];
}

- (void)setData:(id)data {
    // TODO: It's not clear whether NSUserDefaults will perform correct type conversions when a value
    // set using setObject: is read back out using a type specific method.
    // For example, is an NSNumber is passed here, representing either a bool or a float, will a read
    // using the corresponding floatForKey: or bookForKey: methods return the correct value?
    // Testing is necessary to find out.
    [_storage setObject:data forKey:_key];
    
    // Send notification of the update.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"IFNotificationLocalDataUpdate" object:_key];
}

- (NSString *)asString {
    return [_storage stringForKey:_key];
}

@end

@implementation IFLocalSchemeHandler

- (id)init {
    self = [super init];
    if (self) {
        _storage = [NSUserDefaults standardUserDefaults];
    }
    return self;
}

- (id)dereference:(IFCompoundURI *)uri parameters:(NSDictionary *)params {
    // Init resource with nil data - data will be resolved when data property is requested.
    IFLocalResource *resource = [[IFLocalResource alloc] initWithData:nil uri:uri];
    resource.key = uri.name;
    resource.storage = _storage;
    return resource;
}

@end
