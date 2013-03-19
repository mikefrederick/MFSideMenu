//
//  AppDelegate.m
//  MFSideMenuDemoStoryboard
//
//  Created by Michael Frederick on 3/15/13.
//  Copyright (c) 2013 Michael Frederick. All rights reserved.
//

#import "AppDelegate.h"
#import "MFSideMenu.h"

@implementation AppDelegate

@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
    UIViewController *leftSideMenuViewController = [storyboard instantiateViewControllerWithIdentifier:@"leftSideMenuViewController"];
    [MFSideMenu menuWithNavigationController:navigationController
                                             leftSideMenuController:leftSideMenuViewController
                                            rightSideMenuController:nil];
    return YES;
}

@end
