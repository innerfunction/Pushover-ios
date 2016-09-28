//
//  IFContentProvider.h
//  Pushover
//
//  Created by Julian Goacher on 28/09/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFContentAuthority.h"
#import "IFCommandScheduler.h"
#import "IFHTTPClient.h"
#import "IFIOCSingleton.h"

@interface IFContentProvider : NSObject <IFIOCSingleton>

/// A command scheduler to be used by the different content authorities.
@property (nonatomic, strong) IFCommandScheduler *commandScheduler;
/// An HTTP client to be used by the different content authorities.
@property (nonatomic, strong) IFHTTPClient *httpClient;
/// A map of content authority instances keyed by authority name.
@property (nonatomic, strong) NSDictionary *authorities;
/// A map of available file record type handlers.
@property (nonatomic, strong) NSDictionary *fileRecordTypes;
/// A map of available file query type handlers.
@property (nonatomic, strong) NSDictionary *fileQueryTypes;

/// Find a content authority by name, or return nil of no match found.
- (id<IFContentAuthority>)contentAuthorityForName:(NSString *)name;

/// Return the singleton instance of this class.
+ (IFContentProvider *)getInstance;

@end
