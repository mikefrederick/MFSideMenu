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

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Demo!";
    
    // this isn't needed on the rootViewController of the navigation controller
    [self.navigationController.sideMenu setupSideMenuBarButtonItem];
    
    __weak DemoViewController *weakSelf = self;
    // if you want to listen for menu open/close events
    // this is useful, for example, if you want to change a UIBarButtonItem when the menu closes
    self.navigationController.sideMenu.menuStateEventBlock = ^(MFSideMenuStateEvent event) {
        switch (event) {
            case MFSideMenuStateEventMenuWillOpen:
                // the menu will open
                weakSelf.navigationItem.title = @"Menu Will Open!";
                break;
            case MFSideMenuStateEventMenuDidOpen:
                // the menu finished opening
                weakSelf.navigationItem.title = @"Menu Opened!";
                break;
            case MFSideMenuStateEventMenuWillClose:
                // the menu will close
                weakSelf.navigationItem.title = @"Menu Will Close!";
                break;
            case MFSideMenuStateEventMenuDidClose:
                // the menu finished closing
                weakSelf.navigationItem.title = @"Menu Closed!";
                break;
        }
    };
}

- (IBAction)pushAnotherPressed:(id)sender {
    DemoViewController *demoController = [[DemoViewController alloc]
                                          initWithNibName:@"DemoViewController"
                                          bundle:nil];
    
    [self.navigationController pushViewController:demoController animated:YES];
}

@end
