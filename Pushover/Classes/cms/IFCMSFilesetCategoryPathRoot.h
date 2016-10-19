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
//  Created by Julian Goacher on 23/09/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFContentAuthority.h"
#import "IFCMSFileDB.h"

@class IFCMSFileset;
@class IFCMSContentAuthority;

/**
 * A default path root implementation for access to a single category of fileset contents.
 */
@interface IFCMSFilesetCategoryPathRoot : NSObject <IFContentAuthorityPathRoot>

/// The fileset being accessed.
@property (nonatomic, weak) IFCMSFileset *fileset;
/// The content authority.
@property (nonatomic, weak) IFCMSContentAuthority *authority;
/// The file database.
@property (nonatomic, weak) IFCMSFileDB *fileDB;

/// Initialize the path root with the specified fileset and content container.
- (id)initWithFileset:(IFCMSFileset *)fileset container:(IFCMSContentAuthority *)container;
/// Query the file database for entries in the current fileset.
- (NSArray *)queryWithParameters:(NSDictionary *)parameters;
/// Read a single entry from the file database by key (i.e. file ID).
- (NSDictionary *)entryWithKey:(NSString *)key;
/// Read a single entry from the file database by file path.
- (NSDictionary *)entryWithPath:(NSString *)path;
/// Write a query response.
- (void)writeQueryContent:(NSArray *)content asType:(NSString *)type toResponse:(id<IFContentAuthorityResponse>)response;
/// Write an entry response.
- (void)writeEntryContent:(NSDictionary *)content asType:(NSString *)type toResponse:(id<IFContentAuthorityResponse>)response;

@end
