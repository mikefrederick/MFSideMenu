//
//  UINavigationController+MFSideMenu.h
//  MFSideMenuDemo
//
//  Created by Michael Frederick on 10/24/12.
//  Copyright (c) 2012 University of Wisconsin - Madison. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MFSideMenu;

@interface UINavigationController (MFSideMenu)

@property (nonatomic, strong) MFSideMenu *sideMenu;

@end
