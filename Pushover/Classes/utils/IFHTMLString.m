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

#import "IFHTMLString.h"
#import "NSDictionary+IF.h"

typedef NSDictionary *(^IFHTMLStringTagAttributes)();

@implementation IFHTMLString

- (id)initWithString:(NSString *)string {
    self = [super init];
    
    IFHTMLStringTagAttributes pTag = ^() {
        if (!_inlineParagraphs) {
            NSMutableParagraphStyle *paraStyle = [NSMutableParagraphStyle new];
            paraStyle.paragraphSpacing = 0.25 * [UIFont systemFontOfSize:_fontSize].lineHeight;
            return @{ NSParagraphStyleAttributeName: paraStyle };
        }
        return @{};
    };
    IFHTMLStringTagAttributes bTag = ^() {
        return @{ NSFontAttributeName: [UIFont boldSystemFontOfSize:_fontSize] };
    };
    IFHTMLStringTagAttributes iTag = ^() {
        return @{ NSFontAttributeName: [UIFont italicSystemFontOfSize:_fontSize] };
    };
    IFHTMLStringTagAttributes uTag = ^() {
        return @{ NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle) };
    };
    _tagHandlers = @{ @"P": pTag, @"B": bTag, @"I": iTag, @"U": uTag };
    
    if (![string hasPrefix:@"<html>"]) {
        string = [NSString stringWithFormat:@"<html>%@</html>", string];
    }
    _htmlString = string;
    
    _inlineParagraphs = NO;
    _fontSize = 12.0f;
    _fontColor = [UIColor blackColor];
    
    return self;
}

- (void)parse {
    _attrString = [[NSMutableAttributedString alloc] initWithString:@""
                                                         attributes:@{ NSForegroundColorAttributeName: _fontColor }];
    _string = [NSMutableString new];
    _style = @{};
    _styleStack = [NSMutableArray new];
    
    NSData *strData = [_htmlString dataUsingEncoding:_htmlString.fastestEncoding];
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:strData];
    parser.delegate = self;
    [parser parse];
}

- (NSAttributedString *)asAttributedString {
    return _attrString;
}

- (NSString *)asString {
    return _string;
}

#pragma mark - NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary<NSString *,NSString *> *)attributeDict {
    NSString *tagName = [elementName uppercaseString];
    IFHTMLStringTagAttributes tag = _tagHandlers[tagName];
    if (tag) {
        [_styleStack addObject:_style];
        _style = [_style extendWith:tag()];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    NSString *tagName = [elementName uppercaseString];
    IFHTMLStringTagAttributes tag = _tagHandlers[tagName];
    if (tag && [_styleStack count] > 0) {
        _style = [_styleStack lastObject];
        [_styleStack removeLastObject];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:string attributes:_style];
    [_attrString appendAttributedString:attrStr];
    [_string appendString:string];
}

@end
