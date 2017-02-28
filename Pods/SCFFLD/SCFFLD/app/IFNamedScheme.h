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

@class IFContainer;

/**
 * An internal URI handler for the _named:_ scheme.
 * The _named:_ scheme allows named components of the app container to be accessed via URI.
 * The scheme handler forwards requests to the [getNamed:] method of the app container.
 */
@interface IFNamedSchemeHandler : NSObject <IFSchemeHandler> {
    IFContainer *_container;
}

- (id)initWithContainer:(IFContainer *)container;

@end
