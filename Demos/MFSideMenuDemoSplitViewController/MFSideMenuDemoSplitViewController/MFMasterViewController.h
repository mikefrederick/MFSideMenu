//
//  MFMasterViewController.h
//  MFSideMenuDemoSplitViewController
//
//  Created by Michael Frederick on 3/29/13.
//  Copyright (c) 2013 Frederick Development. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MFDetailViewController;

@interface MFMasterViewController : UITableViewController

@property (strong, nonatomic) MFDetailViewController *detailViewController;

@end
