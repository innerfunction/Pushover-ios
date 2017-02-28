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
//  Created by Julian Goacher on 23/10/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFViewController.h"
#import "IFMessageReceiver.h"

/**
 * A configurable web view for display HTML etc.
 * The class implements the _IFMessageReceiver_ protocol and responds to the following message:
 * - _load_: Load new content into the web view. The message must have a _content_ parameter.
 * See the component's _content_ property.
 */
@interface IFWebViewController : IFViewController <UIWebViewDelegate, IFMessageReceiver> {
    /// The underlying web view.
    UIWebView *webView;
    /// An image to display whilst the web view content is loading.
    UIImageView *loadingImageView;
    /// An activity indicator to display whilst loading content.
    UIActivityIndicatorView *loadingIndicatorView;
    /// A flag indicating that an external URL is loading.
    BOOL loadingExternalURL;
    /// A flag indicating that content has loaded.
    BOOL webViewLoaded;
}

/** An image to be displayed whilst the initial page loads. */
@property (nonatomic, strong) UIImage *loadingImage;
/** Whether to display a loading indicator. */
@property (nonatomic, assign) BOOL showLoadingIndicator;
/** A flag indicating whether to load external links within the web view. */
@property (nonatomic, assign) BOOL loadExternalLinks;
/** A flag indicating whether the view controller should use the title of the loaded HTML page as its title. */
@property (nonatomic, assign) BOOL useHTMLTitle;
/** The view background colour. */
@property (nonatomic, strong) UIColor *backgroundColor;
/** Whether the webview is opaque. iOS only property. */
@property (nonatomic, assign) BOOL opaque;
/** Whether the webview bounces during scroll. iOS only property. */
@property (nonatomic, assign) BOOL scrollViewBounces;
/** A list of allowed external URLs. */
@property (nonatomic, strong) NSArray *allowedExternalURLs;
/** A URL to load content from. Only called if no content is directly specified. */
@property (nonatomic, strong) NSString *contentURL;
/** The web view content. May be specified using a string or a URI resource. */
@property (nonatomic, strong) id content;

@end
