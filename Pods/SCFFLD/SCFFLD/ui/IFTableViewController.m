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

#import "IFTableViewController.h"
#import "IFContainer.h"
#import "IFAppContainer.h"
#import "UIViewController+Toast.h"
#import "NSDictionary+IFValues.h"
#import "UIImage+CropScale.h"
#import "IFTypeConversions.h"
#import "IFLogger.h"

#define SectionHeaderHeight     (22.0f)
#define SectionHeaderViewHeight (18.0f)
#define SectionHeaderFontSize   (14.0f)

@interface IFTableViewController()

// Hide the search bar.
- (void)hideSearchBar;
// Get the table cell factory for the specified row position.
- (IFTableViewCellFactory *)cellFactoryForIndexPath:(NSIndexPath *)indexPath;
// Get the display mode for the table row at the specified position.
- (NSString *)displayModeForIndexPath:(NSIndexPath *)indexPath;
// Get the position of the first table row with the specified display mode.
- (NSIndexPath *)indexPathForFirstRowWithDisplayMode:(NSString *)displayMode;

@end

@implementation IFTableViewController

@synthesize iocContainer = _iocContainer;

#pragma mark - IFIOCConfigurationInitable

- (id)initWithConfiguration:(IFConfiguration *)configuration {
    UITableViewStyle style;
    NSString *value = [configuration getValueAsString:@"tableStyle" defaultValue:@"Plain"];
    if ([value isEqualToString:@"Grouped"]) {
        style = UITableViewStyleGrouped;
    }
    else {
        style = UITableViewStylePlain;
    }
    self = [super initWithStyle:style];
    if (self) {
        _tableData = [[IFTableData alloc] init];
        UIColor *backgroundColor = [configuration getValueAsColor:@"backgroundColor"];
        if (backgroundColor) {
            self.tableView.backgroundView = nil;
            self.tableView.backgroundColor = backgroundColor;
        }
        _hideTitleBar = NO;
        _actionProxyLookup = [NSMutableDictionary new];
        // Hide empty rows.
        self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    }
    return self;
}

#pragma mark - IFIOCTypeInspectable
/*
- (BOOL)isDataCollection:(NSString *)propertyName {
    if ([@"content" isEqualToString:propertyName]) {
        return YES;
    }
    return NO;
}
*/
- (Class)memberClassForCollection:(NSString *)propertyName {
    if ([@"cellFactoriesByDisplayMode" isEqualToString:propertyName]) {
        return [IFTableViewCellFactory class];
    }
    return nil;
}

#pragma mark - IFIOCConfigurationAware

- (void)beforeIOCConfiguration:(IFConfiguration *)configuration {}

- (void)afterIOCConfiguration:(IFConfiguration *)configuration {
    defaultFactory = (IFTableViewCellFactory *)[_cellFactoriesByDisplayMode objectForKey:@"default"];
    if (!defaultFactory) {
         defaultFactory = [[IFTableViewCellFactory alloc] init];
        [_iocContainer configureObject:defaultFactory withConfiguration:configuration identifier:@"IFTableViewController.defaultFactory"];
         defaultFactory.tableData = _tableData;
    }
}

#pragma mark - configuration properties

- (void)setCellFactoriesByDisplayMode:(NSDictionary *)cellFactoriesByDisplayMode {
    _cellFactoriesByDisplayMode = cellFactoriesByDisplayMode;
    for (id name in [cellFactoriesByDisplayMode keyEnumerator]) {
        IFTableViewCellFactory *cellFactory = [cellFactoriesByDisplayMode objectForKey:name];
        cellFactory.tableData = _tableData;
    }
}

- (void)setContent:(id)content {
    _content = content;
    NSArray *data = nil;
    if ([content isKindOfClass:[NSArray class]]) {
        data = (NSArray *)content;
    }
    else if ([content isKindOfClass:[IFResource class]]) {
        // TODO Data which potentially contains relative URI refs (e.g. row image refs in table data)
        // should probably be processed within an IFConfiguration wrapper, which has the necessary
        // functionality to resolve such refs properly; downside is the potential efficiency overhead
        // for large data sets.
        IFResource *resource = (IFResource *)content;
        id jsonData = [resource asJSONData];
        if ([jsonData isKindOfClass:[NSArray class]]) {
            data = (NSArray *)jsonData;
        }
        _tableData.uriHandler = resource.uriHandler;
    }
    else {
        [IFLogger withTag:@"IFTableViewController" error:@"Unable to set content of type %@", [[content class] description]];
    }
    if (data) {
        _tableData.data = [self formatData:data];
        // Reset the filter name to apply any active filter & reload the table view.
        self.filterName = _filterName;
    }
}

- (void)setFilterName:(NSString *)filterName {
    _filterName = filterName;
    if (_filterName) {
        IFTableDataFilterBlock filterBlock = [self filterBlockForName:_filterName];
        if (filterBlock) {
            [_tableData filterWithBlock:filterBlock];
        }
    }
    else {
        [_tableData clearFilter];
    }
    // Refresh the list view.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark - view lifecycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    if (_hasSearchBar) {
        searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
        searchBar.delegate = self;
        searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
        searchDisplayController.delegate = self;
        searchDisplayController.searchResultsDataSource = self;
        self.tableView.tableHeaderView = searchBar;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = _hideTitleBar;
    [super viewWillAppear:animated];

    if (_backButtonTitle) {
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:_backButtonTitle
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:nil
                                                                                action:nil];
    }

    if (_leftTitleBarButton) {
        self.navigationItem.leftBarButtonItem = _leftTitleBarButton;
    }
    if (_rightTitleBarButton) {
        self.navigationItem.rightBarButtonItem = _rightTitleBarButton;
    }

    if (_selectedID) {
        NSIndexPath *selectedPath = [_tableData pathForRowWithValue:_selectedID forField:@"id"];
        if (selectedPath) {
            [self.tableView selectRowAtIndexPath:selectedPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            _scrollToSelected = YES;
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (isFirstShow) {
        [self hideSearchBar];
        isFirstShow = NO;
    }
    if (_scrollToSelected) {
        [self.tableView scrollToNearestSelectedRowAtScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }
}

#pragma mark - IFActionProxy

- (void)registerAction:(NSString *)action forObject:(id)object {
    NSValue *key = [NSValue valueWithNonretainedObject:object];
    _actionProxyLookup[key] = action;
}

- (void)postActionForObject:(id)object {
    NSValue *key = [NSValue valueWithNonretainedObject:object];
    NSString *action = _actionProxyLookup[key];
    if (action) {
        [self postMessage:action];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [_tableData sectionCount];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_tableData sectionSize:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [_tableData sectionTitle:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    IFTableViewCellFactory *cellFactory = [self cellFactoryForIndexPath:indexPath];
    return [cellFactory resolveCellForTable:tableView indexPath:indexPath];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *action = [[_tableData rowDataForIndexPath:indexPath] getValueAsString:@"action"];
    if (action) {
        [self postMessage:action];
    }
    [_tableData clearFilter];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    IFTableViewCellFactory *cellFactory = [self cellFactoryForIndexPath:indexPath];
    return [cellFactory heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [_tableData isGrouped] ? SectionHeaderHeight : 0;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (![_tableData isGrouped]) {
        return nil;
    }
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, SectionHeaderViewHeight)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 1, tableView.frame.size.width, SectionHeaderViewHeight)];
    [label setFont:[UIFont boldSystemFontOfSize:SectionHeaderFontSize]];
    NSString *title = [self tableView:tableView titleForHeaderInSection:section];
    [label setText:title];
    label.backgroundColor = [UIColor clearColor];
    if (_sectionTitleColor) {
        label.textColor = _sectionTitleColor;
    }
    [view addSubview:label];
    if (_sectionTitleBackgroundColor) {
        view.backgroundColor = _sectionTitleBackgroundColor;
    }
    return view;
}

#pragma mark - public methods

- (void)clearFilter {
    [_tableData clearFilter];
    [self.tableView reloadData];
    if (_clearFilterMessage) {
        [self showToastMessage:_clearFilterMessage];
    }
}

- (NSArray *)formatData:(NSArray *)data {
    return data;
}

- (void)postMessage:(NSString *)message {
    [IFAppContainer postMessage:message sender:self];
}

- (IFTableDataFilterBlock)filterBlockForName:(NSString *)filterName {
    return nil;
}

#pragma mark - private methods

- (IFTableViewCellFactory *)cellFactoryForIndexPath:(NSIndexPath *)indexPath {
    NSString *displayMode = [self displayModeForIndexPath:indexPath];
    IFTableViewCellFactory *cellFactory = (IFTableViewCellFactory *)[_cellFactoriesByDisplayMode valueForKey:displayMode];
    if (!cellFactory) {
        cellFactory = defaultFactory;
    }
    return cellFactory;
}

- (NSString *)displayModeForIndexPath:(NSIndexPath *)indexPath {
    return @"default";
}

- (NSIndexPath *)indexPathForFirstRowWithDisplayMode:(NSString *)displayMode {
    for (NSInteger section = 0; section < [self.tableView numberOfSections]; section++) {
        for (NSInteger row = 0; row < [self.tableView numberOfRowsInSection:section]; row++) {
            NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:section];
            if ([displayMode isEqualToString:[self displayModeForIndexPath:path]]) {
                return path;
            }
        }
    }
    return nil;
}

- (void)hideSearchBar {
    if (![_tableData isEmpty]) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                              atScrollPosition:UITableViewScrollPositionTop
                                      animated:NO];
    }
}

#pragma mark - Content Filtering

- (void)filterContentForSearchText:(NSString *)searchText scope:(NSString *)scope {
    [_tableData filterBy:searchText scope:scope];
}

- (void)reloadDataWithCompletion:(void(^)(void))completionBlock {
    [self.tableView reloadData];
    [self hideSearchBar];
    if (completionBlock) {
        completionBlock();
    }
}

#pragma mark - UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    NSInteger idx = [self.searchDisplayController.searchBar selectedScopeButtonIndex];
    NSString *scope = [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:idx];
    // Tells the table data source to reload when text changes
    [self filterContentForSearchText:searchString scope:scope];
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    NSString *scope = [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption];
    // Tells the table data source to reload when scope bar selection changes
    [self filterContentForSearchText:self.searchDisplayController.searchBar.text scope:scope];
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [_tableData clearFilter];
    [self.tableView reloadData];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hideSearchBar];
    });
}

#pragma mark - IFMessageReceiver

- (BOOL)receiveMessage:(IFMessage *)message sender:(id)sender {
    if ([message hasName:@"load"]) {
        self.content = message.parameters[@"content"];
        return YES;
    }
    if ([message hasName:@"filter"]) {
        self.filterName = message.parameters[@"name"];
        return YES;
    }
    if ([message hasName:@"clear-filter"]) {
        [_tableData clearFilter];
        [self.tableView reloadData];
        return YES;
    }
    return NO;
}

#pragma mark - Image handling methods

- (UIImage *)loadImageWithRowData:(NSDictionary *)rowData dataName:(NSString *)dataName defaultImage:(UIImage *)defaultImage {
    UIImage *image = defaultImage;
    NSString *imageName = [rowData getValueAsString:dataName];
    if (imageName) {
        image = [imageCache objectForKey:imageName];
        if (!image) {
            image = [self dereferenceImage:imageName];
            if (image) {
                [imageCache setObject:image forKey:imageName];
            }
            else {
                [imageCache setObject:[NSNull null] forKey:imageName];
            }
        }
        else if ([[NSNull null] isEqual:image]) {
            // NSNull in the image cache indicates image not found, so return nil.
            image = nil;
        }
    }
    return image;
}

- (UIImage *)loadImageWithRowData:(NSDictionary *)rowData dataName:(NSString *)dataName width:(CGFloat)width height:(CGFloat)height defaultImage:(UIImage *)defaultImage {
    UIImage *image = defaultImage;
    NSString *imageName = [rowData getValueAsString:dataName];
    if (imageName) {
        NSString *cacheName = [NSString stringWithFormat:@"%@-%fx%f", imageName, width, height];
        image = [imageCache objectForKey:cacheName];
        if (!image) {
            image = [self dereferenceImage:imageName];
            // Scale the image if we have an image and width * height is not zero (implying that neither value is zero).
            if (image && (width * height)) {
                image = [[image scaleToWidth:width] cropToHeight:height];
                [imageCache setObject:image forKey:cacheName];
            }
            else {
                [imageCache setObject:[NSNull null] forKey:imageCache];
            }
        }
        else if ([[NSNull null] isEqual:image]) {
            // NSNull in the image cache indicates image not found, so return nil.
            image = nil;
        }
    }
    return image;
}

- (UIImage *)dereferenceImage:(NSString *)imageRef {
    UIImage *image = nil;
    if ([imageRef hasPrefix:@"@"]) {
        NSString* uri = [imageRef substringFromIndex:1];
        IFResource *imageRsc = [_tableData.uriHandler dereference:uri];
        if (imageRsc) {
            image = [imageRsc asImage];
        }
    }
    else {
        image = [IFTypeConversions asImage:imageRef];
    }
    return image;
}

@end
