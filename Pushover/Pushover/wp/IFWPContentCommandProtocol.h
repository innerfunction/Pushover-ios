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
//  Created by Julian Goacher on 09/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFCommandProtocol.h"
#import "IFDB.h"

@interface IFWPContentCommandProtocol : IFCommandProtocol {
    // The file manager.
    NSFileManager *_fileManager;
    // Path to file used to store downloaded feed result.
    NSString *_feedFile;
    // Path to file used to store downloaded base content zip.
    NSString *_baseContentFile;
    // Path to store downloaded content prior to deployment.
    NSString *_stagedContentPath;
    // A flag indicating that a refresh is in progress.
    BOOL _refreshInProgress;
}

/** The WP feed URL. Note that query parameters will be appened to the URL. */
@property (nonatomic, strong) NSString *feedURL;
/** A URL for doing a bulk-download of initial image content. */
@property (nonatomic, strong) NSString *imagePackURL;
/** The local database used to store post and content data. */
@property (nonatomic, strong) IFDB *postDB;
/** Path to directory holding staged content. */
@property (nonatomic, strong) NSString *stagingPath;
/** Path to directory holding base content. */
@property (nonatomic, strong) NSString *baseContentPath;
/** Path to directory containing pre-packaged content. */
@property (nonatomic, strong) NSString *packagedContentPath;
/** Path to directory hosting downloaded content. */
@property (nonatomic, strong) NSString *contentPath;

@end
