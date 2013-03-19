//
//  SideMenuViewController.h
//  MFSideMenuDemo
//
//  Created by Michael Frederick on 3/19/12.

#import <UIKit/UIKit.h>
#import "MFSideMenu.h"

@interface SideMenuViewController : UITableViewController<UISearchBarDelegate>

@property (nonatomic, assign) MFSideMenu *sideMenu;

@end