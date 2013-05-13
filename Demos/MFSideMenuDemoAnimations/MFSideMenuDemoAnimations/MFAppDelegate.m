//
//  MFAppDelegate.m
//  MFSideMenuDemoAnimations
//
//  Created by Michael Frederick on 5/13/13.
//  Copyright (c) 2013 Frederick Development. All rights reserved.
//

#import "MFAppDelegate.h"
#import "MFSideMenu.h"

@implementation MFAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    MFSideMenuContainerViewController *container = (MFSideMenuContainerViewController *)self.window.rootViewController;
    UINavigationController *navigationController = [storyboard instantiateViewControllerWithIdentifier:@"navigationController"];
    UIViewController *leftSideMenuViewController = [storyboard instantiateViewControllerWithIdentifier:@"leftSideMenuViewController"];
    UIViewController *rightSideMenuViewController = [storyboard instantiateViewControllerWithIdentifier:@"rightSideMenuViewController"];
    
    [container setLeftMenuViewController:leftSideMenuViewController];
    [container setRightMenuViewController:rightSideMenuViewController];
    [container setCenterViewController:navigationController];
    return YES;
}

@end
