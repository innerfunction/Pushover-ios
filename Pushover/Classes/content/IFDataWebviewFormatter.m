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
//  Created by Julian Goacher on 14/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFDataWebviewFormatter.h"

@implementation IFDataWebviewFormatter

- (id)formatData:(id)data {
    // TODO: Should return a dictionary in format suitable for configuring a web view
    //return data;
    NSDictionary *_data = (NSDictionary *)data;
    return @{
        @"contentURL":  [_data valueForKey:@"contentURL"],
        // TODO: Should just modify wp: handler to return content instead of postHTML?
        // That way no filter is required.
        @"content":     [_data valueForKey:@"postHTML"]
    };
}

@end
