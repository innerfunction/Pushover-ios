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
//  Created by Julian Goacher on 08/09/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFContentContainer.h"

NSError *makePathNotFoundResponseError(NSString *name) {
    NSString *description = [NSString stringWithFormat:@"Path root %@ not found", name];
    // See http://nshipster.com/nserror/
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                         code:NSURLErrorFileDoesNotExist // Alternatively: NSURLErrorResourceUnavailable
                                     userInfo:@{ NSLocalizedDescriptionKey: description }];
    return error;
}

NSError *makeInvalidPathResponseError() {
    // See http://nshipster.com/nserror/
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                         code:NSURLErrorFileDoesNotExist // Alternatively: NSURLErrorResourceUnavailable
                                     userInfo:@{ NSLocalizedDescriptionKey: @"Invalid path" }];
    return error;
}
