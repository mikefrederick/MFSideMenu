//
//  DemoViewController.m
//  MFSideMenuDemoStoryboard
//
//  Created by Michael Frederick on 4/9/13.
//  Copyright (c) 2013 Michael Frederick. All rights reserved.
//

#import "DemoViewController.h"
#import "MFSideMenu.h"

@interface DemoViewController ()

@end

@implementation DemoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (IBAction)showLeftMenuPressed:(id)sender {
    [self.navigationController.sideMenu performSelector:@selector(toggleLeftSideMenu)];
}

- (IBAction)showRightMenuPressed:(id)sender {
    [self.navigationController.sideMenu performSelector:@selector(toggleRightSideMenu)];
}

@end
