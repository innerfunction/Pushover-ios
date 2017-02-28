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

#import <Foundation/Foundation.h>
#import "IFURIHandling.h"

/**
 * The _s:_ scheme handler.
 * The _string_ scheme is one of the simplest possible scheme implementations, which just returns
 * the name part of an internal URI as the URIs referenced value.
 * The scheme also supports slightly more complex behaviour if one or more URI parameters are specified.
 * In this case, the name part is treated as a string template (using @see <IFStringTemplate>) which is
 * evaluated using the provided parameters as its data context.
 * All string values returned by the scheme have any URI encoding removed (via a call to
 * _[NSString stringByRemovingPercentEncoding]_).
 */
@interface IFStringSchemeHandler : NSObject <IFSchemeHandler>

@end
