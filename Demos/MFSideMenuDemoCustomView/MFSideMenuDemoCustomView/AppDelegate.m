//
//  AppDelegate.m
//  MFSideMenuDemoCustomView
//
//  Created by Aleksejs Sinicins on 21/07/13.
//  Copyright (c) 2013 MFSideMenuDemo. All rights reserved.
//

#import "AppDelegate.h"
#import "DemoViewController.h"
#import "SideMenuViewController.h"

@implementation AppDelegate

- (DemoViewController *)demoController {
    return [[DemoViewController alloc] initWithNibName:@"DemoViewController" bundle:nil];
}

- (UINavigationController *)navigationController {
    return [[UINavigationController alloc]
            initWithRootViewController:[self demoController]];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    SideMenuViewController *leftMenuViewController = [[SideMenuViewController alloc] init];
    SideMenuViewController *rightMenuViewController = [[SideMenuViewController alloc] init];
    MFSideMenuContainerViewController *container = [MFSideMenuContainerViewController
                                                    containerWithCenterViewController:[self navigationController]
                                                    leftMenuViewController:leftMenuViewController
                                                    rightMenuViewController:rightMenuViewController];
    [container setPanMode:MFSideMenuPanModeCustomView];
    self.window.rootViewController = container;
    [self.window makeKeyAndVisible];

    return YES;
}

@end
