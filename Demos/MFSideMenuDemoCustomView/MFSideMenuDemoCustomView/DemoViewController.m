//
//  DemoViewController.m
//  MFSideMenuDemoCustomView
//
//  Created by Aleksejs Sinicins on 21/07/13.
//  Copyright (c) 2013 MFSideMenuDemo. All rights reserved.
//

#import "DemoViewController.h"

@interface DemoViewController ()
@property (nonatomic, strong) IBOutlet UIButton *sideMenuButton;
@end

@implementation DemoViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (MFSideMenuContainerViewController *)menuContainerViewController {
    return (MFSideMenuContainerViewController *)self.navigationController.parentViewController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if(!self.title) self.title = @"Demo!";
    [self.menuContainerViewController setCustomPanningView:self.sideMenuButton];
}

- (IBAction)leftSideMenuButtonPressed:(id)sender {
    [self.menuContainerViewController toggleLeftSideMenuCompletion:nil];
}

@end
