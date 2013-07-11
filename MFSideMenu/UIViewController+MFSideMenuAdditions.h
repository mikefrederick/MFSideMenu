//
//  UIViewController+MFSideMenuAdditions.h
//  MFSideMenuDemoBasic
//
//  Created by Robin Chou on 7/11/13.
//  Copyright (c) 2013 University of Wisconsin - Madison. All rights reserved.
//

#import <UIKit/UIKit.h>
@class MFSideMenuContainerViewController;

// category on UIViewController to provide reference to the menuContainerViewController in any of the contained View Controllers
@interface UIViewController (MFSideMenuAdditions)

@property(nonatomic,readonly,retain) MFSideMenuContainerViewController *menuContainerViewController;

@end

