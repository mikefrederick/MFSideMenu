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

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    
    DemoViewController *demoViewController = [[DemoViewController alloc] initWithNibName:@"DemoViewController" bundle:nil];
    demoViewController.title = @"Drag Me To The Right";
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:demoViewController];
    
    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];
    
    SideMenuViewController *sideMenuViewController = [[SideMenuViewController alloc] init];
    
    MenuOptions options = MenuButtonEnabled|BackButtonEnabled;
    // make sure to display the navigation controller before calling this
    [MFSideMenuManager configureWithNavigationController:navigationController 
                                      sideMenuController:sideMenuViewController
                                        menuSide:MenuLeftHandSide
                                                 options:options];
    
    [sideMenuViewController release];
    [demoViewController release];
    [navigationController release];
    
    return YES;
}

@end
