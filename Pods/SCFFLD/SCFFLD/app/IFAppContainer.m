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

#import "IFAppContainer.h"
#import "IFConfiguration.h"
#import "IFViewController.h"
#import "IFNewScheme.h"
#import "IFMakeScheme.h"
#import "IFPostScheme.h"
#import "IFCoreTypes.h"
#import "IFI18nMap.h"
#import "NSString+IF.h"
#import "IFWebViewController.h"

@interface IFAppContainer ()

- (NSMutableDictionary *)makeDefaultGlobalModelValues:(IFConfiguration *)configuration;

@end

@implementation IFAppContainer

- (id)init {
    self = [super init];
    if (self) {
        _appURIHandler = [[IFStandardURIHandler alloc] init];
        self.uriHandler = _appURIHandler;
        // Core names which should be built before processing the rest of the container's configuration.
        self.priorityNames = @[ @"types", @"formats", @"schemes", @"aliases", @"makes" ];
        
        _logger = [[IFLogger alloc] initWithTag:@"IFAppContainer"];

    }
    return self;
}

- (void)setWindow:(UIWindow *)window {
    _window = window;
    _window.rootViewController = [self getRootView];
    _window.backgroundColor = _appBackgroundColor;
}

- (void)loadConfiguration:(id)configSource {
    IFConfiguration *configuration = nil;
    if ([configSource isKindOfClass:[IFConfiguration class]]) {
        // Configuration source is already a configuration.
        configuration = (IFConfiguration *)configSource;
    }
    else {
        // Test if config source specifies a URI.
        IFCompoundURI *uri = nil;
        if ([configSource isKindOfClass:[IFCompoundURI class]]) {
            uri = (IFCompoundURI *)configSource;
        }
        else if ([configSource isKindOfClass:[NSString class]]) {
            NSError *error = nil;
            uri = [IFCompoundURI parse:(NSString *)configSource error:&error];
            if (error) {
                [_logger error:@"Error parsing app container configuration URI: %@", error];
                return;
            }
        }
        id configData = nil;
        if (uri) {
            // If a configuration source URI has been resolved then attempt loading the configuration from the URI.
            [_logger info:@"Loading app container configuration from %@", uri ];
            configData = [self.uriHandler dereference:uri];
        }
        else {
            configData = configSource;
        }
        // Create configuration from data.
        if ([configData isKindOfClass:[IFResource class]]) {
            IFResource *configRsc =(IFResource *)configData;
            id data = [configRsc asJSONData];
            configuration = [[IFConfiguration alloc] initWithData:data uriHandler:configRsc.uriHandler];
            // Use the configuration's URI handler instead from this point on, to ensure relative URI's
            // resolve properly and also so that additional URI schemes added to this container are
            // available within the configuration.
            self.uriHandler = configuration.uriHandler;
        }
        else {
            configuration = [[IFConfiguration alloc] initWithData:configSource];
        }
    }
    if (configuration) {
        [self configureWith:configuration];
    }
    else {
        [_logger warn:@"Unable to resolve configuration from %@", configSource ];
    }
}

- (void)setFormats:(NSDictionary *)formats {
    _appURIHandler.formats = formats;
}

- (NSDictionary *)formats {
    return _appURIHandler.formats;
}

- (void)setAliases:(NSDictionary *)aliases {
    _appURIHandler.aliases = aliases;
}

- (NSDictionary *)aliases {
    return _appURIHandler.aliases;
}

- (void)setSchemes:(NSDictionary *)schemes {
    // Map any additional schemes to the URI handler.
    for (id schemeName in schemes) {
        id scheme = schemes[schemeName];
        if ([scheme conformsToProtocol:@protocol(IFSchemeHandler)]) {
            [_appURIHandler addHandler:scheme forScheme:schemeName];
        }
    }
    // Note that schemes aren't stored on the container to avoid retain cycles.
}

- (void)configureWith:(IFConfiguration *)configuration {
    
    // Setup template context.
    _globals = [self makeDefaultGlobalModelValues:configuration];
    configuration.context = _globals;
    
    // Set object type mappings.
    [self addTypes:[configuration getValueAsConfiguration:@"types"]];
    
    // Add additional schemes to the resolver/dispatcher.
    [_appURIHandler addHandler:[[IFNewScheme alloc] initWithContainer:self] forScheme:@"new"];
    [_appURIHandler addHandler:[[IFMakeScheme alloc] initWithAppContainer:self] forScheme:@"make"];
    [_appURIHandler addHandler:[[IFNamedSchemeHandler alloc] initWithContainer:self] forScheme:@"named"];
    [_appURIHandler addHandler:[[IFPostScheme alloc] init] forScheme:@"post"];
    
    // Default local settings.
    _locals = [[IFLocals alloc] initWithPrefix:@"semo"];
    NSDictionary *settings = (NSDictionary *)[configuration getValue:@"settings"];
    if (settings) {
        [_locals setValues:settings forceReset:ForceResetDefaultSettings];
    }
    
    [_named setObject:_appURIHandler forKey:@"uriHandler"];
    [_named setObject:_globals forKey:@"globals"];
    [_named setObject:_locals forKey:@"locals"];
    [_named setObject:self forKey:@"app"];


    // Perform default container configuration.
    [super configureWith:configuration];
}

- (NSMutableDictionary *)makeDefaultGlobalModelValues:(IFConfiguration *)configuration {
    
    NSMutableDictionary *values = [[NSMutableDictionary alloc] init];
    float scale = [UIScreen mainScreen].scale;
    NSString *display = scale > 1.0 ? [NSString stringWithFormat:@"%f.0x", scale] : @"";
    NSDictionary *platformValues = @{
        @"name":            Platform,
        @"dispay":          display,
        @"defaultDisplay":  @"2x",
        @"full":            [NSString stringWithFormat:@"ios%@", display]
    };
    [values setObject:platformValues forKey:@"platform"];
    
    NSString *mode = [configuration getValueAsString:@"mode" defaultValue:@"LIVE"];
    [_logger info:@"Configuration mode: %@", mode];
    [values setObject:mode forKey:@"mode"];
    
    NSLocale *locale = [NSLocale currentLocale];
    NSString *lang = nil;
    [_logger info:@"Current locale is %@", locale.localeIdentifier];
    
    // The 'supportedLocales' setting can be used to declare a list of the locales that app assets are
    // available in. If the platform's default locale (above) isn't on this list then the code below
    // will attempt to find a supported locale that uses the same language; if no match is found then
    // the first locale on the list is used as the default.
    if ([configuration hasValue:@"supportedLocales"]) {
        NSArray *assetLocales = [configuration getValue:@"supportedLocales"];
        if ([assetLocales count] > 0 && ![assetLocales containsObject:locale.localeIdentifier]) {
            // Attempt to find a matching locale.
            // Always assigns the first item on the list (as the default option); if a later
            // item has a matching language then that is assigned and the loop is exited.
            NSString *lang = [locale objectForKey:NSLocaleLanguageCode];
            BOOL langMatch = NO, assignDefault;
            for (NSInteger i = 0; i < [assetLocales count] && !langMatch; i++) {
                NSString *assetLocale = [assetLocales objectAtIndex:0];
                NSArray *localeParts = [assetLocale split:@"_"];
                assignDefault = (i == 0);
                langMatch = [[localeParts objectAtIndex:0] isEqualToString:lang];
                if (assignDefault||langMatch) {
                    locale = [NSLocale localeWithLocaleIdentifier:assetLocale];
                }
            }
        }
        // Handle the case where the user's selected language is different from the locale.
        // See http://stackoverflow.com/questions/3910244/getting-current-device-language-in-ios
        NSString *preferredLang = [[NSLocale preferredLanguages] objectAtIndex:0];
        if (![[locale objectForKey:NSLocaleLanguageCode] isEqualToString:preferredLang]) {
            // Use the user's selected language if listed in assetLocales.
            for (NSString *assetLocale in assetLocales) {
                NSArray *localeParts = [assetLocale split:@"_"];
                if ([[localeParts objectAtIndex:0] isEqualToString:preferredLang]) {
                    lang = preferredLang;
                    break;
                }
            }
        }
    }
    
    if (!lang) {
        // If the user's preferred language hasn't been selected, then use the current locale's.
        lang = [locale objectForKey:NSLocaleLanguageCode];
    }
    [_logger info:@"Using language %@", lang];
    
    NSDictionary *localeValues = @{
        @"id":       [locale objectForKey:NSLocaleIdentifier],
        @"lang":     lang,
        @"variant":  [locale objectForKey:NSLocaleCountryCode]
    };
    [values setObject:localeValues forKey:@"locale"];
    [values setObject:[IFI18nMap instance] forKey:@"i18n"];
    
    return values;
}

- (UIViewController *)getRootView {
    id rootView = [self.uriHandler dereference:@"make:RootView"];
    if (!rootView) {
        [_logger error:@"Root view not found, check that a RootView make configuration exists"];
    }
    else if ([rootView isKindOfClass:[UIView class]]) {
        // Promote UIView to a view controller.
        IFViewController *viewController = [[IFViewController alloc] initWithView:(UIView *)rootView];
        rootView = viewController;
    }
    else if (![rootView isKindOfClass:[UIViewController class]]) {
        [_logger error:@"The component named 'rootView' is not an instance of UIView or UIViewController"];
        rootView = nil;
    }
    // If unable to resolve a root view then use a blank view displaying an error message.
    if (!rootView) {
        IFWebViewController *webView = [[IFWebViewController alloc] init];
        webView.content = @"<p>Root view not found, check that a RootView make configuration exists and defines a view instance</p>";
        rootView = webView;
    }
    return rootView;
}

- (void)postMessage:(NSString *)messageURI sender:(id)sender {
    // Try parsing the action URI.
    IFCompoundURI *uri = [IFCompoundURI parse:messageURI];
    // If URI doesn't parse then it may be a bare message, try prepending post: and parsing again.
    if (!uri) {
        messageURI = [@"post:" stringByAppendingString:messageURI];
        uri = [IFCompoundURI parse:messageURI];
    }
    if (uri) {
        // Process the message on the main thread. This is because the URI may dereference to a view,
        // and some views (e.g. web views) have to be instantiated on the UI thread.
        dispatch_async(dispatch_get_main_queue(), ^{
            // See if the URI resolves to a post message object.
            id message = [_appURIHandler dereference:uri];
            if (![message isKindOfClass:[IFMessage class]]) {
                // Automatically promote views to 'show' messages.
                if ([message isKindOfClass:[UIViewController class]]) {
                    message = [[IFMessage alloc] initWithTargetPath:@[] name:@"show" parameters:@{ @"view": message }];
                }
                else if ([message isKindOfClass:[NSString class]]) {
                    // Assume a simple name only message with no parameters.
                    message = [[IFMessage alloc] initWithTarget:nil name:message parameters:nil];
                }
                else return; // Can't promote the message, so can't dispatch it.
            }
            // message is always a Message instance by this point.
            [self routeMessage:(IFMessage *)message sender:sender];
        });
    }
}

- (BOOL)isInternalURISchemeName:(NSString *)schemeName {
    return [_appURIHandler hasHandlerForURIScheme:schemeName];
}

#pragma mark - IFIOCTypeInspectable
/*
- (BOOL)isDataCollection:(NSString *)propertyName {
    if ([@"makes" isEqualToString:propertyName]) {
        return YES;
    }
    if ([@"aliases" isEqualToString:propertyName]) {
        return YES;
    }
    return NO;
}
*/
- (__unsafe_unretained Class)memberClassForCollection:(NSString *)propertyName {
    return nil;
}

#pragma mark - IFMessageRouter

- (BOOL)routeMessage:(IFMessage *)message sender:(id)sender {
    BOOL routed = NO;
    // If the sender is within the UI then search the view hierarchy for a message receiver.
    id target = sender;
    // Evaluate actions with relative target paths against the sender.
    while (target && !routed) {
        // See if the current target can take the message.
        if ([message hasEmptyTarget]) {
            // Message has no target info so looking for a message receiver.
            if ([target conformsToProtocol:@protocol(IFMessageReceiver)]) {
                routed = [(id<IFMessageReceiver>)target receiveMessage:message sender:sender];
            }
        }
        else if ([target conformsToProtocol:@protocol(IFMessageRouter)]) {
            // Message does have target info so looking for a message router.
            routed = [(id<IFMessageRouter>)target routeMessage:message sender:sender];
        }
        if (!routed) {
            // Message not dispatched, so try moving up the view hierarchy.
            if ([target isKindOfClass:[UIViewController class]]) {
                UIViewController *currentTarget = (UIViewController *)target;
                // If message sender is a view controller then bubble the message up through the
                // view controller hierarchy until a receiver is found.
                if (currentTarget.presentingViewController) {
                    target = currentTarget.presentingViewController;
                }
                else {
                    target = currentTarget.parentViewController;
                }
            }
            else if ([target isKindOfClass:[UIView class]]) {
                // If message sender is a view then bubble the message up through the view hierarchy.
                // TODO: This may not work...
                target = [(UIView *)target nextResponder];
            }
            else {
                // Can't process the message any further, so leave the loop.
                break;
            }
        }
    }
    // If message not dispatched then let this container try routing it to one of its named components.
    if (!routed) {
        routed = [super routeMessage:message sender:sender];
    }
    return routed;
}

#pragma mark - IFMessageReceiver

- (BOOL)receiveMessage:(IFMessage *)message sender:(id)sender {
    if ([message hasName:@"open-url"]) {
        NSString *url = (NSString *)[message parameterValue:@"url"];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    }
    else if ([message hasName:@"show"]) {
        id view = [message parameterValue:@"view"];
        if ([view isKindOfClass:[UIViewController class]]) {
            [UIView transitionWithView: self.window
                              duration: 0.5
                               options: UIViewAnimationOptionTransitionFlipFromLeft
                            animations: ^{
                                self.window.rootViewController = view;
                            }
                            completion:nil];
        }
    }
    return YES;
}

#pragma mark - Overrides

- (void)configureObject:(id)object withConfiguration:(IFConfiguration *)configuration identifier:(NSString *)identifier {
    [super configureObject:object withConfiguration:configuration identifier:identifier];
}

#pragma mark - Class statics

static IFAppContainer *IFAppContainer_instance;

+ (void)initialize {
    IFAppContainer_instance = [[IFAppContainer alloc] init];
    [IFAppContainer_instance addTypes:[IFCoreTypes types]];
}

+ (IFAppContainer *)getAppContainer {
    return IFAppContainer_instance;
}

+ (IFAppContainer *)bindToWindow:(UIWindow *)window {
    IFAppContainer *container = [IFAppContainer getAppContainer];
    [container loadConfiguration:@"app:config.json"];
    [container startService];
    container.window = window;
    return container;
}

+ (void)postMessage:(NSString *)messageURI sender:(id)sender {
    [IFAppContainer_instance postMessage:messageURI sender:sender];
}

@end
