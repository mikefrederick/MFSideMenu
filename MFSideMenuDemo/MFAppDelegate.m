//
//  MFAppDelegate.m
//  MFSideMenuDemo
//
//  Created by Michael Frederick on 3/19/12.

#import "MFAppDelegate.h"
#import "MFSideMenu.h"
#import "DemoViewController.h"
#import "SideMenuViewController.h"

@implementation MFAppDelegate

@synthesize window = _window;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    DemoViewController *demoViewController = [[DemoViewController alloc] initWithNibName:@"DemoViewController" bundle:nil];
    demoViewController.title = @"Drag Me To The Right";
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:demoViewController];
    
    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];
    
    SideMenuViewController *sideMenuViewController = [[SideMenuViewController alloc] init];
    
    [MFSideMenu menuWithNavigationController:navigationController
                          sideMenuController:sideMenuViewController];
    
    
    return YES;
}

@end
