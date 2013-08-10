//
//  UIViewController+MFSideMenuAdditions.h
//  MFSideMenuDemoBasic
//
//  Created by Michael Frederick on 4/2/13.
//  Copyright (c) 2013 Frederick Development. All rights reserved.
//

#import <UIKit/UIKit.h>
@class MFSideMenuContainerViewController;

// category on UIViewController to provide reference to the menuContainerViewController in any of the contained View Controllers
@interface UIViewController (MFSideMenuAdditions)

@property(nonatomic,readonly,retain) MFSideMenuContainerViewController *menuContainerViewController;

@end

