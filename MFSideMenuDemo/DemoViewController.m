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

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Demo!";
    
    [self.navigationController.sideMenu setupSideMenuBarButtonItem];
    
    // if you want to listen for menu open/close events
    [self addSideMenuStateEventObserver];
}

- (IBAction)pushAnotherPressed:(id)sender {
    DemoViewController *demoController = [[DemoViewController alloc]
                                          initWithNibName:@"DemoViewController"
                                          bundle:nil];
    
    [self.navigationController pushViewController:demoController animated:YES];
}


/** 
 Optional: listen for menu state events
 This is useful, for example, if you want to change the UIBarButtonItem when the menu closes
 **/

- (void) addSideMenuStateEventObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sideMenuStateEventOccurred:)
                                                 name:MFSideMenuStateEventDidOccurNotification
                                               object:nil];
}

- (void) sideMenuStateEventOccurred:(NSNotification *)notification {
    MFSideMenuStateEvent event = (MFSideMenuStateEvent)[notification.object intValue];
    switch (event) {
        case MFSideMenuStateEventMenuWillOpen:
            // the menu will open
            self.navigationItem.title = @"Menu Will Open!";
            break;
        case MFSideMenuStateEventMenuDidOpen:
            // the menu finished opening
            self.navigationItem.title = @"Menu Opened!";
            break;
        case MFSideMenuStateEventMenuWillClose:
            // the menu will close
            self.navigationItem.title = @"Menu Will Close!";
            break;
        case MFSideMenuStateEventMenuDidClose:
            // the menu finished closing
            self.navigationItem.title = @"Menu Closed!";
            break;
    }
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
