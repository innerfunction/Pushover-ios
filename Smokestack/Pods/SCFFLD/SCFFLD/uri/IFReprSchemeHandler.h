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
//  Created by Julian Goacher on 11/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFURIHandling.h"

/**
 * An internal URI handler for the _repr:_ scheme.
 * This scheme allows URI resources to be coerced to a specific representation within a URI.
 * Scheme URIs are in the form:
 *
 *     <scheme name>:<representation name>+value@<uri>
 *
 * That is, each URI should have a _value_ parameter specifying the value to be coerced, and a URI
 * name part that identifies the name of the required representation.
 * This scheme is useful only in very particular cases, e.g. where the default resolved representation
 * isn't what is actually needed.
 */
@interface IFReprSchemeHandler : NSObject <IFSchemeHandler>

@end
