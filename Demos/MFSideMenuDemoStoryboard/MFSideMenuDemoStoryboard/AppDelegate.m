//
//  AppDelegate.m
//  MFSideMenuDemoStoryboard
//
//  Created by Michael Frederick on 3/15/13.
//  Copyright (c) 2013 Michael Frederick. All rights reserved.
//

#import "AppDelegate.h"
#import "MFSideMenuContainerViewController.h"

@implementation AppDelegate

@synthesize window;

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
