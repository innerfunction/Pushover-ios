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
//  Created by Julian Goacher on 11/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFWPContentContainer.h"
#import "IFAppContainer.h"
#import "IFNamedScheme.h"
#import "IFDataTableFormatter.h"
#import "IFDataWebviewFormatter.h"
#import "IFGetURLCommand.h"
#import "IFDownloadZipCommand.h"
#import "IFStringTemplate.h"
#import "IFLogger.h"
#import "NSDictionary+IF.h"

static IFLogger *Logger;

@implementation IFWPContentContainer

@synthesize iocContainer=_iocContainer;

+ (void)initialize {
    Logger = [[IFLogger alloc] initWithTag:@"IFWPContentContainer"];
}

- (id)init {
    self = [super init];
    if (self) {
        _postDBName = @"com.innerfunction.semo.content";
        _feedURL = @"";
        _packagedContentPath = @"";
        _uriSchemeName = @"wp";
        _wpRealm = @"semo";
        _listFormats = @{
            @"table": [[IFDataTableFormatter alloc] init]
        };
        _postFormats = @{
            @"webview": [[IFDataWebviewFormatter alloc] init]
        };
        _postURITemplate = @"{uriSchemeName}:/post/{postID}";
        
        // Configuration template. Note that the top-level property types are inferred from the
        // corresponding properties on the container object (i.e. self).
        id template = @{
            @"postDB": @{
                @"name":                    @"$postDBName",
                @"version":                 @1,
                @"resetDatabase":           @"$resetPostDB",
                @"tables": @{
                    // Table of wordpress posts.
                    @"posts": @{
                        @"columns": @{
                            @"id":          @{ @"type": @"INTEGER", @"tag": @"id" },    // Post ID
                            @"title":       @{ @"type": @"TEXT" },
                            @"type":        @{ @"type": @"TEXT" },
                            @"status":      @{ @"type": @"TEXT" },      // i.e. WP post status
                            @"modified":    @{ @"type": @"TEXT" },      // Modification date/time; ISO 8601 format string.
                            @"content":     @{ @"type": @"TEXT" },
                            @"imageid":     @{ @"type": @"INTEGER" },   // ID of the post's featured image.
                            @"location":    @{ @"type": @"STRING" },    // The post's location; packaged, downloaded or server.
                            @"url":         @{ @"type": @"STRING" },    // The post's WP URL.
                            @"filename":    @{ @"type": @"TEXT" },      // Name of associated media file (i.e. for attachments)
                            @"parent":      @{ @"type": @"INTEGER" },   // ID of parent page/post.
                            @"menu_order":  @{ @"type": @"INTEGER" }    // Sort order; mapped to post.menu_order.
                        }
                    },
                    // Table of parent/child post closures. Used to efficiently map descendant post relationships.
                    // See http://dirtsimple.org/2010/11/simplest-way-to-do-tree-based-queries.html for a simple description.
                    @"closures": @{
                        @"columns": @{
                            @"parent":      @{ @"type": @"INTEGER" },
                            @"child":       @{ @"type": @"INTEGER" },
                            @"depth":       @{ @"type": @"INTEGER" }
                        }
                    }
                }
            },
            @"contentCommandProtocol": @{
                @"feedURL":                 @"$feedURL",
                @"imagePackURL":            @"$imagePackURL",
                @"postDB":                  @"@named:postDB",
                @"stagingPath":             @"$stagingPath",
                @"packagedContentPath":     @"$packagedContentPath",
                @"baseContentPath":         @"$baseContentPath",
                @"contentPath":             @"$contentPath"
            },
            @"postDBAdapter": @{
                @"postDB":                  @"@named:postDB"
            },
            @"clientTemplateContext": @{
                @"*ios-class":              @"IFWPClientTemplateContext",
            },
            @"packagedContentPath":         @"$packagedContentPath",
            @"contentPath":                 @"$contentPath"
        };
        _configTemplate = [[IFConfiguration alloc] initWithData:template];

        // TODO: Is there a way for the command scheduler to use the same DB as the post DB? This would
        //       require the ability for the scheduler to merge its table schema over the schema above;
        //       May also complicate schema versioning.
        //       Note that currently there is a potential problem if more than one content container is
        //       used (or if more than one command scheduler is used) as every command scheduler instance
        //       currently uses the same named database. (Perhaps this isn't a problem? just needs proper
        //       management).
        _commandScheduler = [[IFCommandScheduler alloc] init];
        //_commandScheduler.deleteExecutedQueueRecords = NO; // DEBUG setting.
        // Command scheduler is manually instantiated, so has to be manually added to the services list.
        // TODO: This is another aspect that needs to be considered when formalizing the configuration
        //       template pattern used by this container.
        //       (Could just add @"commandScheduler": @{ @"*ios-class": @"IFCommandScheduler" } to the
        //       above).
        [self->_services addObject:_commandScheduler];
        
        // NOTES on staging and content paths:
        // * Freshly downloaded content is stored under the staging path until the download is complete, after which
        //   it is deployed to the content path and deleted from the staging location. The staging path is placed
        //   under NSApplicationSupportDirectory to avoid it being deleted by the system mid-download, if the system
        //   needs to free up disk space.
        // * Base content is deployed under NSApplicationSupportDirectory to avoid it being cleared by the system.
        // * All other content is deployed under NSCachesDirectory, where the system may remove it if it needs to
        //   recover disk space. If this happens then Semo will attempt to re-downloaded the content again, if needed.
        // See:
        // http://developer.apple.com/library/ios/#documentation/FileManagement/Conceptual/FileSystemProgrammingGUide/FileSystemOverview/FileSystemOverview.html
        // https://developer.apple.com/library/ios/#documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/PerformanceTuning/PerformanceTuning.html#//apple_ref/doc/uid/TP40007072-CH8-SW8
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        NSString *cachePath = [paths objectAtIndex:0];
        _stagingPath = [cachePath stringByAppendingPathComponent:@"com.innerfunction.semo.staging"];
        _baseContentPath = [cachePath stringByAppendingPathComponent:@"com.innerfunction.semo.base"];
        
        // Switch cache path for content location.
        paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        cachePath = [paths objectAtIndex:0];
        _contentPath = [cachePath stringByAppendingPathComponent:@"com.innerfunction.semo.content"];
        
        // Factory for producing login + account management forms.
        _formFactory = [[IFWPContentContainerFormFactory alloc] initWithContainer:self];

        _httpClient = [[IFHTTPClient alloc] init];
        
        _authManager = [[IFWPAuthManager alloc] initWithContainer:self];
        _httpClient.authenticationDelegate = _authManager;
        
        _searchResultLimit = 100;
    }
    return self;
}

- (void)setListFormats:(NSDictionary *)listFormats {
    _listFormats = [_listFormats extendWith:listFormats];
}

- (void)setPostFormats:(NSDictionary *)postFormats {
    _postFormats = [_postFormats extendWith:postFormats];
}

#pragma mark - Instance methods

- (void)unpackPackagedContent {
    NSInteger count = [_postDB countInTable:@"posts" where:@"1 = 1"];
    if (count == 0) {
        [_commandScheduler appendCommand:@"content.unpack"];// -packagedContentPath %@", _packagedContentPath];
    }
}

- (void)refreshContent {
    [_commandScheduler appendCommand:@"content.refresh"];
    [_commandScheduler executeQueue];
}

- (void)getContentFromURL:(NSString *)url writeToFilename:(NSString *)filename {
    NSString *filepath = [_contentPath stringByAppendingPathComponent:filename];
    [_commandScheduler appendCommand:@"get %@ %@", url, filepath];
    [_commandScheduler executeQueue];
}

- (NSString *)uriForPostWithID:(NSString *)postID {
    NSDictionary *context = @{ @"uriSchemeName": _uriSchemeName, @"postID": postID };
    return [IFStringTemplate render:_postURITemplate context:context];
}

- (void)showLoginForm {
    [IFAppContainer postMessage:_showLoginAction sender:self];
}

#pragma mark - IFIOCContainerAware

- (void)beforeIOCConfiguration:(IFConfiguration *)configuration {}

- (void)afterIOCConfiguration:(IFConfiguration *)configuration {
    
    // Packaged content is packaged with the app executable.
    NSString *packagedContentPath = [MainBundlePath stringByAppendingPathComponent:_packagedContentPath];
    
    // Setup configuration parameters.
    id parameters = @{
        @"postDBName":          _postDBName,
        @"resetPostDB":         [NSNumber numberWithBool:_resetPostDB],
        @"feedURL":             _feedURL,
        @"imagePackURL":        _imagePackURL,
        @"stagingPath":         _stagingPath,
        @"packagedContentPath": packagedContentPath,
        @"baseContentPath":     _baseContentPath,
        @"contentPath":         _contentPath,
        @"listFormats":         _listFormats,
        @"postFormats":         _postFormats
    };
    
    // TODO: There should be some standard method for doing the following, but need to consider what
    // the component configuration template pattern is exactly first.
    
    // Resolve a URI handler for the container's components, and add a modified named: scheme handler
    // pointed at this container.
    id<IFURIHandler> uriHandler = configuration.uriHandler;
    IFNamedSchemeHandler *namedScheme = [[IFNamedSchemeHandler alloc] initWithContainer:self];
    uriHandler = [uriHandler replaceURIScheme:@"named" withHandler:namedScheme];
    
    // Create the container's component configuration and setup to use the new URI handler
    IFConfiguration *componentConfig = [_configTemplate extendWithParameters:parameters];
    componentConfig.uriHandler = uriHandler; // This necessary for relative URIs within the config to work.
    componentConfig.root = self;
    
    // Configure the container's components.
    [self configureWith:componentConfig];

    // Configure the command scheduler.
    _commandScheduler.queueDBName = [NSString stringWithFormat:@"%@.scheduler", _postDBName];
    if (_contentCommandProtocol) {
        _commandScheduler.commands = @{ @"content": _contentCommandProtocol };
    }
    
    IFGetURLCommand *getCmd = [[IFGetURLCommand alloc] initWithHTTPClient:_httpClient];
    getCmd.maxRequestsPerMinute = 30.0f;
    IFDownloadZipCommand *dlzipCmd = [[IFDownloadZipCommand alloc] initWithHTTPClient:_httpClient commandScheduler:_commandScheduler];
    _commandScheduler.commands = @{
        @"get": getCmd,
        @"dlzip": dlzipCmd
    };

}

#pragma mark - IFMessageReceiver

- (BOOL)receiveMessage:(IFMessage *)message sender:(id)sender {
    if ([message hasName:@"logout"]) {
        [_authManager logout];
        [self showLoginForm];
        return YES;
    }
    if ([message hasName:@"password-reminder"]) {
        [_authManager showPasswordReminder];
        return YES;
    }
    if ([message hasName:@"show-login"]) {
        [self showLoginForm];
        return YES;
    }
    return NO;
}

#pragma mark - IFService

- (void)startService {
    [super startService];
    [self unpackPackagedContent];
    // Schedule content updates.
    if (_updateCheckInterval > 0) {
        [_commandScheduler appendCommand:@"content.refresh"];
        [NSTimer scheduledTimerWithTimeInterval:(_updateCheckInterval * 60.0f)
                                         target:self
                                       selector:@selector(refreshContent)
                                       userInfo:nil
                                        repeats:YES];
    }
    // Start command queue execution.
    [_commandScheduler executeQueue];
}

#pragma mark - IFIOCTypeInspectable

- (BOOL)isDataCollection:(NSString *)propertyName {
    return [@"postTypeRelations" isEqualToString:propertyName];
}

- (__unsafe_unretained Class)memberClassForCollection:(NSString *)propertyName {
    return nil;
}


@end
