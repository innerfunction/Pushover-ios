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
//  Created by Julian Goacher on 22/10/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFURIHandling.h"
#import "IFAppContainer.h"

/**
 * An internal URI handler for the _make:_ scheme.
 * The _make:_ scheme allows new components to be instantiated from a pre-defined configuration.
 * The set of pre-defined configurations must be declared in a top-level property of the app
 * container named _makes_. The _name_ part of the _make:_ URI then refers to a key within
 * the makes map. Make configurations can be parameterized, with parameter values provided
 * via the _make:_ URI's parameters.
 */
@interface IFMakeScheme : NSObject <IFSchemeHandler> {
    IFAppContainer *_container;
}

- (id)initWithAppContainer:(IFAppContainer *)container;


@end
