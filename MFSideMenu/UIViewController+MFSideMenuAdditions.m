//
//  UIViewController+MFSideMenuAdditions.m
//  MFSideMenuDemoBasic
//
//  Created by Robin Chou on 7/11/13.
//  Copyright (c) 2013 University of Wisconsin - Madison. All rights reserved.
//

#import "UIViewController+MFSideMenuAdditions.h"
#import "MFSideMenuContainerViewController.h"

@implementation UIViewController (MFSideMenuAdditions)

@dynamic menuContainerViewController;

- (MFSideMenuContainerViewController *)menuContainerViewController {
    id containerView = self;
    while (![containerView isKindOfClass:[MFSideMenuContainerViewController class]] && containerView) {
        if ([containerView respondsToSelector:@selector(parentViewController)])
            containerView = [containerView parentViewController];
        if ([containerView respondsToSelector:@selector(splitViewController)] && !containerView)
            containerView = [containerView splitViewController];
    }
    return containerView;
}

@end