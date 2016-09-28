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
@class IFCMSFilesPathRoot;

@interface IFCMSContentAuthority : IFAbstractContentAuthority <IFIOCConfigurationAware>

@property (nonatomic, strong) NSString *dbName;
@property (nonatomic, strong) IFCMSFileDB *db;
@property (nonatomic, strong) IFCMSPostsPathRoot *postsPathRoot;
@property (nonatomic, strong) IFCMSPostsPathRoot *pagesPathRoot;

@end
