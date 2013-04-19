//
//  MFAppDelegate.m
//  MFSideMenuDemoSplitViewController
//
//  Created by Michael Frederick on 3/29/13.
//  Copyright (c) 2013 Frederick Development. All rights reserved.
//

#import "MFAppDelegate.h"
#import "MFMasterViewController.h"
#import "MFDetailViewController.h"
#import "MFSideMenu.h"
#import "SideMenuViewController.h"

@implementation MFAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.

    MFMasterViewController *masterViewController = [[MFMasterViewController alloc] initWithNibName:@"MFMasterViewController" bundle:nil];
    UINavigationController *masterNavigationController = [[UINavigationController alloc] initWithRootViewController:masterViewController];

    MFDetailViewController *detailViewController = [[MFDetailViewController alloc] initWithNibName:@"MFDetailViewController" bundle:nil];
    UINavigationController *detailNavigationController = [[UINavigationController alloc] initWithRootViewController:detailViewController];

    masterViewController.detailViewController = detailViewController;

    self.splitViewController = [[UISplitViewController alloc] init];
    self.splitViewController.delegate = detailViewController;
    self.splitViewController.viewControllers = @[masterNavigationController, detailNavigationController];
    
    SideMenuViewController *leftSideMenuController = [[SideMenuViewController alloc] init];
    SideMenuViewController *rightSideMenuController = [[SideMenuViewController alloc] init];
    [MFSideMenu menuWithNavigationController:masterNavigationController
                      leftSideMenuController:leftSideMenuController
                     rightSideMenuController:rightSideMenuController];
    
    self.window.rootViewController = self.splitViewController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
