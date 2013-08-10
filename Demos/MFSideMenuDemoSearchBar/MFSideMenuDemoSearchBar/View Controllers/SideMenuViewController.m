//
//  SideMenuViewController.m
//  MFSideMenuDemo
//
//  Created by Michael Frederick on 3/19/12.

#import "SideMenuViewController.h"
#import "MFSideMenu.h"
#import "DemoViewController.h"

@interface SideMenuViewController()
@property(nonatomic, strong) UISearchBar *searchBar;
@end

@implementation SideMenuViewController

@synthesize searchBar;

- (void) viewDidLoad {
    [super viewDidLoad];
    
    CGRect searchBarFrame = CGRectMake(0, 0, self.tableView.frame.size.width, 45.0);
    self.searchBar = [[UISearchBar alloc] initWithFrame:searchBarFrame];
    self.searchBar.delegate = self;
    
    self.tableView.tableHeaderView = self.searchBar;
}

#pragma mark -
#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [NSString stringWithFormat:@"Section %d", section];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"Item %d", indexPath.row];
    
    return cell;
}


#pragma mark -
#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    DemoViewController *demoController = [[DemoViewController alloc] initWithNibName:@"DemoViewController" bundle:nil];
    demoController.title = [NSString stringWithFormat:@"Demo #%d-%d", indexPath.section, indexPath.row];
    
    UINavigationController *navigationController = self.menuContainerViewController.centerViewController;
    NSArray *controllers = [NSArray arrayWithObject:demoController];
    navigationController.viewControllers = controllers;
    [self.menuContainerViewController setMenuState:MFSideMenuStateClosed];
    
    if(self.searchBar.isFirstResponder) [self.searchBar resignFirstResponder];
}


#pragma mark - 
#pragma mark - UISearchBarDelegate

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    return YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self.searchBar resignFirstResponder];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [UIView beginAnimations:nil context:NULL];
    [self.menuContainerViewController setMenuWidth:320.0f animated:NO];
    [self.searchBar layoutSubviews];
    [UIView commitAnimations];
    
    [self.searchBar setShowsCancelButton:YES animated:YES];
    
    self.menuContainerViewController.panMode = MFSideMenuPanModeNone;
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [UIView beginAnimations:nil context:NULL];
    [self.menuContainerViewController setMenuWidth:280.0f animated:NO];
    [self.searchBar layoutSubviews];
    [UIView commitAnimations];
    
    [self.searchBar setShowsCancelButton:NO animated:YES];
    
    self.menuContainerViewController.panMode = MFSideMenuPanModeDefault;
}

@end
