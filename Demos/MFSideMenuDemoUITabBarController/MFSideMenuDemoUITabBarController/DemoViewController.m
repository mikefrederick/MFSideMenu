//
//  DemoViewController.m
//  MFSideMenuDemo
//
//  Created by Michael Frederick on 3/19/12.
//

#import "DemoViewController.h"
#import "MFSideMenu.h"

@interface DemoViewController ()

@end

@implementation DemoViewController

- (void) dealloc {
    self.navigationController.sideMenu.menuStateEventBlock = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Demo!";
    
    [self setupMenuBarButtonItems];
    
    __weak DemoViewController *weakSelf = self;
    // if you want to listen for menu open/close events
    // this is useful, for example, if you want to change a UIBarButtonItem when the menu closes
    self.navigationController.sideMenu.menuStateEventBlock = ^(MFSideMenuStateEvent event) {
        switch (event) {
            case MFSideMenuStateEventMenuWillOpen:
                // the menu will open
                weakSelf.navigationItem.title = @"Menu Will Open!";
                break;
            case MFSideMenuStateEventMenuDidOpen: {
                // the menu finished opening
                weakSelf.navigationItem.title = @"Menu Opened!";
                break;
            }
            case MFSideMenuStateEventMenuWillClose:
                // the menu will close
                weakSelf.navigationItem.title = @"Menu Will Close!";
                break;
            case MFSideMenuStateEventMenuDidClose:
                // the menu finished closing
                weakSelf.navigationItem.title = @"Menu Closed!";
                break;
        }
        NSLog(@"event occurred: %@", weakSelf.navigationItem.title);
        [weakSelf setupMenuBarButtonItems];  
    };
}

- (void)setupMenuBarButtonItems {
    switch (self.navigationController.sideMenu.menuState) {
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
            target:self.navigationController.sideMenu
            action:@selector(toggleLeftSideMenu)];
}

- (UIBarButtonItem *)rightMenuBarButtonItem {
    return [[UIBarButtonItem alloc]
            initWithImage:[UIImage imageNamed:@"menu-icon.png"] style:UIBarButtonItemStyleBordered
            target:self.navigationController.sideMenu
            action:@selector(toggleRightSideMenu)];
}

- (UIBarButtonItem *)backBarButtonItem {
    return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back-arrow"]
                                            style:UIBarButtonItemStyleBordered
                                           target:self
                                           action:@selector(backButtonPressed:)];
}

- (void)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)pushAnotherPressed:(id)sender {
    DemoViewController *demoController = [[DemoViewController alloc]
                                          initWithNibName:@"DemoViewController"
                                          bundle:nil];
    
    [self.navigationController pushViewController:demoController animated:YES];
}

@end
