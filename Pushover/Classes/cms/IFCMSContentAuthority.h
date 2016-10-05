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
#import "IFAbstractContentAuthority.h"
#import "IFCMSFileDB.h"
#import "IFCMSFilesetCategoryPathRoot.h"
#import "IFIOCConfigurationAware.h"

@class IFCMSPostsPathRoot;

/**
 * A content authority which sources its content from a Pushover CMS
 */
@interface IFCMSContentAuthority : IFAbstractContentAuthority <IFIOCConfigurationAware>

/// The name of the file database.
@property (nonatomic, strong) NSString *fileDBName;
/// The file database.
@property (nonatomic, strong) IFCMSFileDB *fileDB;
/// The path root for 'posts'.
@property (nonatomic, strong) IFCMSPostsPathRoot *postsPathRoot;
/// The filesets defined for this authority.
@property (nonatomic, strong, readonly) NSDictionary *filesets;
/// The CMS base URL.
@property (nonatomic, strong) NSString *cmsBaseURL;
/// A map of available content record type converters.
@property (nonatomic, strong) NSDictionary *recordTypes;
/// A map of available content query type converters.
@property (nonatomic, strong) NSDictionary *queryTypes;

@end
