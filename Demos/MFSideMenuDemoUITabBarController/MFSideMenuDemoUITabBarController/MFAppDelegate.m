//
//  MFAppDelegate.m
//  MFSideMenuDemoUITabBarController
//
//  Created by Michael Frederick on 3/19/13.
//  Copyright (c) 2013 Michael Frederick. All rights reserved.
//

#import "MFAppDelegate.h"
#import "MFSideMenuContainerViewController.h"
#import "DemoViewController.h"
#import "SideMenuViewController.h"

@implementation MFAppDelegate

@synthesize window = _window;

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
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    [tabBarController setViewControllers:[NSArray arrayWithObjects:[self navigationController],
                                          [self navigationController], nil]];
    
    SideMenuViewController *leftSideMenuController = [[SideMenuViewController alloc] init];
    SideMenuViewController *rightSideMenuController = [[SideMenuViewController alloc] init];
    MFSideMenuContainerViewController *container = [MFSideMenuContainerViewController
                                                    containerWithCenterViewController:tabBarController
                                                    leftMenuViewController:leftSideMenuController
                                                    rightMenuViewController:rightSideMenuController];
    
    self.window.rootViewController = container;
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
