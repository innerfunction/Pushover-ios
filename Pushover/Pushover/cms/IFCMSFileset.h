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
//  Created by Julian Goacher on 26/09/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFJSONData.h"
#import "IFIOCObjectAware.h"

/**
 * A class declaring the options available on a fileset database configuration entry.
 */
@interface IFCMSFileset : NSObject

/** A list of the mapping names supported by the fileset. */
@property (nonatomic, strong) IFJSONArray *mappings;

@end

/**
 * A class describing a fileset's local caching policy.
 */
@interface IFCMSFilesetCachePolicy : NSObject <IFIOCObjectAware>

/**
 * The fileset's caching policy. One of the following strings:
 * * NoCache: The content is always downloaded from the server, never cached locally.
 * * ContentCache: The content is downloaded and stored in the content cache. Data
 *   in the content cache may be removed by the OS to free up space, after which the
 *   content needs to be downloaded again if required.
 * * AppCache: The content is downloaded and stored in the app cache. Data in the app
 *   cache will only be removed when the app is uninstalled.
 */
@property (nonatomic, strong) NSString *policy;
/** The fileset's category name. */
@property (nonatomic, strong) NSString *category;
/** The fileset cache's file path root, under which fileset content is stored. */
@property (nonatomic, strong) NSString *path;
/** A flag indicating whether a fileset's content should be downloaded and cached. */
@property (nonatomic, assign) BOOL cachable;

@end