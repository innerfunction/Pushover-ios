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
//  Created by Julian Goacher on 12/04/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * A class for parsing HTML strings. The class can be used to generate an attributed string which
 * shows a simplified version of the text formatting contained within HTML markup. The class
 * recognizes the following HTML elements:
 * - B: Bold text
 * - I: Italic text
 * - U: Underlined text
 * The class recognizes P elements which it will display as paragraph blocks, unless the
 * _inlineParagraphs_ property is set to _true_ in which case the element contents are displayed
 * inline.
 * All other elements are ignored and are stripped from the result.
 * The class can also be used to strip HTML elements from text input.
 */
@interface IFHTMLString : NSObject <NSXMLParserDelegate> {
    /// The original HTML.
    NSString *_htmlString;
    /// An attributed string generated from the HTML.
    NSMutableAttributedString *_attrString;
    /// Text-only content derived from the HTML.
    NSMutableString *_string;
    /// A map of HTML tag handlers.
    NSDictionary *_tagHandlers;
    /// While parsing the HTML, the in-scope text style.
    NSDictionary *_style;
    /// While parsing, a stack of the in-scope text styles.
    NSMutableArray *_styleStack;
}

/** Flag indicating whether HTML P elements should be inlined, i.e. displayed as non-block elements. */
@property (nonatomic, assign) BOOL inlineParagraphs;
/** The font size to generate attributed text as. Defaults to 12pt. */
@property (nonatomic, assign) CGFloat fontSize;
/** The font colour to use for attributed text. */
@property (nonatomic, strong) UIColor *fontColor;

/** Initialize with an HTML string. */
- (id)initWithString:(NSString *)string;
/** Parse the HTML string. */
- (void)parse;
/** Return an attributed string representation of the HTML contents. */
- (NSAttributedString *)asAttributedString;
/** Return a plain-text representation of the HTML contents. */
- (NSString *)asString;

@end
