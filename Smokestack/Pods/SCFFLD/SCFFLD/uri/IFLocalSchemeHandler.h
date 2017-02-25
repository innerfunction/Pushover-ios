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
// limitations under the License
//
//  Created by Julian Goacher on 13/03/2013.
//  Copyright (c) 2013 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFResource.h"

/**
 * A resource type used to represent values from the app's local storage.
 * On iOS, this represents values stored and accessed using _NSUserDefaults_.
 */
@interface IFLocalResource : IFResource {
}

/// The key used to access the resource value.
@property (nonatomic, strong) NSString *key;
/// The app's local storage, i.e. _[NSUserDefaults standardUserDefaults]_.
@property (nonatomic, strong) NSUserDefaults *storage;

@end

/**
 * A URI scheme handler for mapping internal URIs to items in local storage.
 * The URI name part is used as the local storage key. All other parts of the URI are ignored.
 */
@interface IFLocalSchemeHandler : NSObject <IFSchemeHandler> {
    NSUserDefaults *_storage;
}

@end