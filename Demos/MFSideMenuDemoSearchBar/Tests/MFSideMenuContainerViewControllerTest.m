//
//  MFSideMenuContainerViewControllerTest.m
//  MFSideMenuDemoSearchBar
//
//  Created by Michael Frederick on 5/3/13.
//  Copyright (c) 2013 Frederick Development. All rights reserved.
//

#import <GHUnitIOS/GHUnit.h>
#import <OCMock/OCMock.h>
#import "MFSideMenuContainerViewController.h"
#import "SideMenuViewController.h"
#import "DemoViewController.h"

typedef enum {
    MFSideMenuPanDirectionNone,
    MFSideMenuPanDirectionLeft,
    MFSideMenuPanDirectionRight
} MFSideMenuPanDirection;

@interface MFSideMenuContainerViewController()
@property (nonatomic, strong) UIViewController *leftMenuViewController;
@property (nonatomic, strong) UIViewController *centerViewController;
@property (nonatomic, strong) UIViewController *rightMenuViewController;
@property (nonatomic, strong) UIView *menuContainerView;
@property (nonatomic, assign) CGPoint panGestureOrigin;
@property (nonatomic, assign) CGFloat panGestureVelocity;
@property (nonatomic, assign) MFSideMenuPanDirection panDirection;
@end

@interface MFSideMenuContainerViewControllerTest : GHTestCase
@property (nonatomic, strong) MFSideMenuContainerViewController *container;
@end


@implementation MFSideMenuContainerViewControllerTest

- (BOOL)shouldRunOnMainThread {
    // By default NO, but if you have a UI test or test dependent on running on the main thread return YES.
    // Also an async test that calls back on the main thread, you'll probably want to return YES.
    return NO;
}

- (void)setUpClass {
    SideMenuViewController *leftSideMenuController = [[SideMenuViewController alloc] init];
    SideMenuViewController *rightSideMenuController = [[SideMenuViewController alloc] init];
    DemoViewController *demoViewController = [[DemoViewController alloc] initWithNibName:@"DemoViewController"
                                                                                  bundle:nil];
    UINavigationController *navigationController = [[UINavigationController alloc]
                                                    initWithRootViewController:demoViewController];
    self.container = [MFSideMenuContainerViewController
                      containerWithCenterViewController:leftSideMenuController
                      leftMenuViewController:navigationController
                      rightMenuViewController:rightSideMenuController];
}

- (void)tearDownClass {
    // Run at end of all tests in the class
}

- (void)setUp {
    // Run before each test method
}

- (void)tearDown {
    // Run after each test method
}

- (void)testInitialize {

}


@end
