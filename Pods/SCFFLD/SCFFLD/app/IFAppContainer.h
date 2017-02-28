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
//  Created by Julian Goacher on 23/04/2015.
//  Copyright (c) 2015 InnerFunction. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IFContainer.h"
#import "IFStandardURIHandler.h"
#import "IFLocals.h"
#import "IFNamedScheme.h"
#import "IFJSONData.h"
#import "IFIOCTypeInspectable.h"
#import "IFLogger.h"

#define ForceResetDefaultSettings   (NO)
#define Platform                    (@"ios")
#define IOSVersion                  ([[UIDevice currentDevice] systemVersion])

/**
 * An IOC container encapsulating an app's UI and functionality.
 */
@interface IFAppContainer : IFContainer <IFIOCTypeInspectable> {
    /**
     * Global values available to the container's configuration. Can be referenced from within templated
     * configuration values.
     * Available values include the following:
     * - *platform*: Information about the container platform. Has the following values:
     *   - _name_: Always "ios" on iOS systems.
     *   - _display_: The display scale, e.g. 2x, 3x.
     * - *locale*: Information about the device's default locale. Has the following values:
     *   - _id_: The locale identifier, e.g. en_US
     *   - _lang_: The locale's language code, e.g. en
     *   - _variant_: The locale's varianet, e.g. US
     */
    NSMutableDictionary *_globals;
    /// Access to the app's local storage.
    IFLocals *_locals;
    /// The URI handler instantiated by this container.
    IFStandardURIHandler *_appURIHandler;
}

/// The app's default background colour.
@property (nonatomic, strong) UIColor *appBackgroundColor;
/// The app's window.
@property (nonatomic, weak) UIWindow *window;
/// Map of additional scheme configurations.
@property (nonatomic, strong) NSDictionary *schemes;
/// Make configurations.
@property (nonatomic, strong) IFConfiguration *makes;
/// URI formatters.
@property (nonatomic) NSDictionary *formats;
/// URI aliases.
@property (nonatomic) IFJSONObject *aliases;

/** Load the app configuration. */
- (void)loadConfiguration:(id)configSource;
/** Return the app's root view. */
- (UIViewController *)getRootView;
/** Post a message URI. */
- (void)postMessage:(NSString *)messageURI sender:(id)sender;
/** Test whether a URI scheme name belongs to an internal URI scheme. */
- (BOOL)isInternalURISchemeName:(NSString *)schemeName;

/** Return the app container singleton instance. */
+ (IFAppContainer *)getAppContainer;

/**
 * Utility method to load configuration from a standard location and bind to an app window.
 * Assumes app configuration is in a file named config.json.
 * Binds the container's root view to the windows rootViewController.
 * Returns the app container configured with the files contents.
 */
+ (IFAppContainer *)bindToWindow:(UIWindow *)window;

/** Post a message URI. */
+ (void)postMessage:(NSString *)messageURI sender:(id)sender;

@end
