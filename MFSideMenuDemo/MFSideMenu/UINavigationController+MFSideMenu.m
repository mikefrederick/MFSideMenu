//
//  UINavigationController+MFSideMenu.m
//  MFSideMenuDemo
//
//  Created by Michael Frederick on 10/24/12.
//  Copyright (c) 2012 University of Wisconsin - Madison. All rights reserved.
//

#import "UINavigationController+MFSideMenu.h"
#import "MFSideMenu.h"
#import <objc/runtime.h>

@implementation UINavigationController (MFSideMenu)

static char menuKey;

- (void)setSideMenu:(MFSideMenu *)sideMenu {
    objc_setAssociatedObject(self, &menuKey, sideMenu, OBJC_ASSOCIATION_RETAIN);
}

- (MFSideMenu *)sideMenu {
    return (MFSideMenu *)objc_getAssociatedObject(self, &menuKey);
}

- (void) MFSideMenu_viewWillAppear:(BOOL)animated {
    [self MFSideMenu_viewWillAppear:animated]; // Method has been swizzled, call on self
    
    [self.sideMenu performSelector:@selector(navigationControllerWillAppear)];
}

- (void) MFSideMenu_viewDidAppear:(BOOL)animated {
    [self MFSideMenu_viewDidAppear:animated]; // Method has been swizzled, call on self
    
    [self.sideMenu performSelector:@selector(navigationControllerDidAppear)];
}

- (void) MFSideMenu_viewDidDisappear:(BOOL)animated {
    [self MFSideMenu_viewDidDisappear:animated]; // Method has been swizzled, call on self
    
    [self.sideMenu performSelector:@selector(navigationControllerDidDisappear)];
}

@end
