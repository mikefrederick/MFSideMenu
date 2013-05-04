//
//  DemoViewController.m
//  MFSideMenuDemo
//
//  Created by Michael Frederick on 3/19/12.
//

#import "DemoViewController.h"
#import "MFSideMenuContainerViewController.h"

@implementation DemoViewController


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Demo!";
    
    [self setupMenuBarButtonItems];
}

- (MFSideMenuContainerViewController *)menuContainerViewController {
    return (MFSideMenuContainerViewController *)self.navigationController.parentViewController;
}


#pragma mark -
#pragma mark - UIBarButtonItems

- (void)setupMenuBarButtonItems {
    switch (self.menuContainerViewController.menuState) {
        case MFSideMenuStateClosed:
            if([[self.navigationController.viewControllers objectAtIndex:0] isEqual:self]) {
                self.navigationItem.leftBarButtonItem = [self leftMenuBarButtonItem];
            } else {
                self.navigationItem.leftBarButtonItem = [self backBarButtonItem];
            }
            self.navigationItem.rightBarButtonItem = [self rightMenuBarButtonItem];
            break;
        case MFSideMenuStateLeftMenuOpen:
            self.navigationItem.leftBarButtonItem = [self leftMenuBarButtonItem];
            break;
        case MFSideMenuStateRightMenuOpen:
            self.navigationItem.rightBarButtonItem = [self rightMenuBarButtonItem];
            break;
    }
}

- (UIBarButtonItem *)leftMenuBarButtonItem {
    return [[UIBarButtonItem alloc]
            initWithImage:[UIImage imageNamed:@"menu-icon.png"] style:UIBarButtonItemStyleBordered
            target:self
            action:@selector(leftSideMenuButtonPressed:)];
}

- (UIBarButtonItem *)rightMenuBarButtonItem {
    return [[UIBarButtonItem alloc]
            initWithImage:[UIImage imageNamed:@"menu-icon.png"] style:UIBarButtonItemStyleBordered
            target:self
            action:@selector(rightSideMenuButtonPressed:)];
}

- (UIBarButtonItem *)backBarButtonItem {
    return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back-arrow"]
                                            style:UIBarButtonItemStyleBordered
                                           target:self
                                           action:@selector(backButtonPressed:)];
}


#pragma mark - 
#pragma mark - UIBarButtonItem Callbacks

- (void)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)leftSideMenuButtonPressed:(id)sender {
    [self.menuContainerViewController toggleLeftSideMenuCompletion:^{
        [self setupMenuBarButtonItems];
    }];
}

- (void)rightSideMenuButtonPressed:(id)sender {
    [self.menuContainerViewController toggleRightSideMenuCompletion:^{
        [self setupMenuBarButtonItems];
    }];
}


#pragma mark -
#pragma mark - IBActions

- (IBAction)pushAnotherPressed:(id)sender {
    DemoViewController *demoController = [[DemoViewController alloc]
                                          initWithNibName:@"DemoViewController"
                                          bundle:nil];
    
    [self.navigationController pushViewController:demoController animated:YES];
}

@end
