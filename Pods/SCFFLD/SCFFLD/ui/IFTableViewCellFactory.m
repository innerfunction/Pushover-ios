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
//  Created by Julian Goacher on 24/10/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFTableViewCellFactory.h"
#import "IFTableViewController.h"
#import "UIColor+IF.h"
#import "NSDictionary+IFValues.h"
#import "IFTypeConversions.h"

#define DefaultRowHeight        [NSNumber numberWithFloat:44.0]
#define DefaultRowImageWidth    [NSNumber numberWithFloat:40.0]

@implementation IFTableViewCellFactory

- (id)init {
    self = [super init];
    if (self) {
        _height = DefaultRowHeight;
    }
    return self;
}

- (UITableViewCell *)resolveCellForTable:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath {
    IFTableViewController *ifTableView = nil;
    if ([tableView isKindOfClass:[IFTableViewController class]]) {
        ifTableView = (IFTableViewController *)tableView;
    }
    
    NSDictionary *rowData = [_tableData rowDataForIndexPath:indexPath];
    
    NSString *style = [rowData getValueAsString:@"style" defaultValue:_style];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:style];
    
    if (!cell) {
        UITableViewCellStyle cellStyle = UITableViewCellStyleDefault;
        if ([style isEqualToString:@"Style1"]) {
            cellStyle = UITableViewCellStyleValue1;
        }
        else if ([style isEqualToString:@"Style2"]) {
            cellStyle = UITableViewCellStyleValue2;
        }
        else if ([style isEqualToString:@"Subtitle"]) {
            cellStyle = UITableViewCellStyleSubtitle;
        }
        cell = [[UITableViewCell alloc] initWithStyle:cellStyle reuseIdentifier:style];
    }
    
    NSString *title       = [rowData getValueAsString:@"title" defaultValue:@""];
    NSString *description = [rowData getValueAsString:@"description" defaultValue:@""];
    
    cell.textLabel.text = title;
    if (description) {
        cell.detailTextLabel.text = description;
    }
    
    cell.textLabel.textColor = [rowData getValueAsColor:@"textColor" defaultValue:_textColor];
    cell.textLabel.highlightedTextColor = [rowData getValueAsColor:@"selectedTextColor" defaultValue:_selectedTextColor];
    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.detailTextLabel.textColor = [rowData getValueAsColor:@"detailTextColor" defaultValue:_detailTextColor];
    cell.detailTextLabel.highlightedTextColor = [rowData getValueAsColor:@"selectedDetailTextColor" defaultValue:_selectedDetailTextColor];
    cell.detailTextLabel.backgroundColor = [UIColor clearColor];
    cell.backgroundColor = [rowData getValueAsColor:@"backgroundColor" defaultValue:_backgroundColor];
    
    UIColor *selectedBackgroundColor = [rowData getValueAsColor:@"selectedBackgroundColor" defaultValue:_selectedBackgroundColor];
    // NOTE: This won't work correctly on grouped lists with rounded corners:
    if (selectedBackgroundColor) {
        UIView *bgColorView = [[UIView alloc] init];
        bgColorView.backgroundColor = selectedBackgroundColor;
        bgColorView.layer.masksToBounds = YES;
        [cell setSelectedBackgroundView:bgColorView];
    }
    
    CGFloat imageHeight = [[rowData getValueAsNumber:@"imageHeight" defaultValue:_imageHeight] floatValue];
    if (!imageHeight) {
        imageHeight = [[rowData getValueAsNumber:@"height" defaultValue:_height] floatValue];
    }
    CGFloat imageWidth = imageHeight;
    if ([rowData hasValue:@"imageWidth"]) {
        imageWidth = [[rowData getValueAsNumber:@"imageWidth" defaultValue:_imageWidth] floatValue];
    }
    UIImage *image = [ifTableView loadImageWithRowData:rowData dataName:@"image" width:imageWidth height:imageHeight defaultImage:_image];
    if (image) {
        cell.imageView.image = image;
        // Add rounded corners to image.
        cell.imageView.layer.masksToBounds = YES;
        cell.imageView.layer.cornerRadius = 3.0;
    }
    else {
        cell.imageView.image = nil;
    }
    
    NSString *accessory = [rowData getValueAsString:@"accessory" defaultValue:_accessory];
    if ([accessory isEqualToString:@"None"]) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else if ([accessory isEqualToString:@"DisclosureIndicator"]) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if ([accessory isEqualToString:@"DetailButton"]) {
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
    else if ([accessory isEqualToString:@"Checkmark"]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    UIImage *backgroundImage  = [ifTableView loadImageWithRowData:rowData dataName:@"backgroundImage" defaultImage:_backgroundImage];
    UIImage *selectedImage    = [ifTableView loadImageWithRowData:rowData dataName:@"selectedBackgroundImage" defaultImage:_selectedBackgroundImage];
    
    if (backgroundImage) {
        cell.backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
        cell.backgroundView.contentMode = UIViewContentModeCenter;
    }
    if (selectedImage) {
        cell.selectedBackgroundView = [[UIImageView alloc] initWithImage:selectedImage];
        cell.selectedBackgroundView.contentMode = UIViewContentModeCenter;
    }
    
    if (_decorator) {
        cell = [_decorator decorateCell:cell data:rowData factory:self];
    }
    return cell;
}

- (CGFloat)heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *rowData = [_tableData rowDataForIndexPath:indexPath];
    CGFloat height = [[rowData getValueAsNumber:@"height" defaultValue:_height] floatValue];
    return height;
}

@end
