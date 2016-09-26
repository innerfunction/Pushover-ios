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
//  Created by Julian Goacher on 13/09/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFCommandProtocol.h"
#import "IFCMSFileDB.h"
#import "IFHTTPClient.h"
#import "Q.h"

@interface IFCMSCommandProtocol : IFCommandProtocol {
    QPromise *_promise;
}

/** The CMS feed URL. Note that query parameters will be appened to the URL. */
@property (nonatomic, strong) NSString *feedURL;
/** The local file database. */
@property (nonatomic, strong) IFCMSFileDB *fileDB;
/** Path to directory holding staged content. */
@property (nonatomic, strong) NSString *stagingPath;
/** Path to directory hosting downloaded content. */
@property (nonatomic, strong) NSString *contentPath;
/** An HTTP client instance. */
@property (nonatomic, strong) IFHTTPClient *httpClient;

@end
