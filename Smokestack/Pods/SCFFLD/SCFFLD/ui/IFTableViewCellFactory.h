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

#import <UIKit/UIKit.h>
#import "IFTableData.h"
#import "IFConfiguration.h"

@class IFTableViewController;
@class IFTableViewCellFactory;

@protocol IFTableViewCellDecorator <NSObject>

- (UITableViewCell *)decorateCell:(UITableViewCell *)cell data:(NSDictionary *)data factory:(IFTableViewCellFactory *)factory;

@end

/**
 * A factory class for generating table view cell instances.
 * (Note that this class is _not_ an @see <IFIOCObjectFactory> instance).
 */
@interface IFTableViewCellFactory : NSObject {
}

@property (nonatomic, strong) id<IFTableViewCellDecorator> decorator;
/// The parent table's data.
@property (nonatomic, strong) IFTableData *tableData;

/// The cell display style.
@property (nonatomic, strong) NSString *style;
/// The default main text colour.
@property (nonatomic, strong) UIColor *textColor;
/// The default text colour for a selected cell.
@property (nonatomic, strong) UIColor *selectedTextColor;
/// The default detail text colour.
@property (nonatomic, strong) UIColor *detailTextColor;
/// The default detail text colour for a selected cell.
@property (nonatomic, strong) UIColor *selectedDetailTextColor;
/// The cell's default background colour.
@property (nonatomic, strong) UIColor *backgroundColor;
/// The default background colour for a selected cell.
@property (nonatomic, strong) UIColor *selectedBackgroundColor;
/// The default cell height.
@property (nonatomic, strong) NSNumber *height;
/// The default width of the cell's image.
@property (nonatomic, strong) NSNumber *imageWidth;
/// The default height of the cell's image.
@property (nonatomic, strong) NSNumber *imageHeight;
/// The cell's default accessory style.
@property (nonatomic, strong) NSString *accessory;
/// The cell's default image.
@property (nonatomic, strong) UIImage *image;
/// A background image for the cell.
@property (nonatomic, strong) UIImage *backgroundImage;
/// A background image for a selected cell.
@property (nonatomic, strong) UIImage *selectedBackgroundImage;

- (UITableViewCell *)resolveCellForTable:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath;
- (CGFloat)heightForRowAtIndexPath:(NSIndexPath *)indexPath;

@end
