//
//  MFSideMenu.h
//
//  Created by Michael Frederick on 3/17/12.
//

#import "UINavigationController+MFSideMenu.h"

static CGFloat const kMFSideMenuSidebarWidth = 270.0f;
static CGFloat const kMFSideMenuShadowWidth = 10.0f;
static CGFloat const kMenuAnimationDuration = 0.2f;
static CGFloat const kMenuAnimationMaxDuration = 0.4f;

typedef enum {
    MFSideMenuLocationLeft, // show the menu on the left hand side
    MFSideMenuLocationRight // show the menu on the right hand side
} MFSideMenuLocation;

typedef enum {
    MFSideMenuStateHidden, // the menu is hidden
    MFSideMenuStateVisible // the menu is shown
} MFSideMenuState;

typedef enum {
    MFSideMenuOptionMenuButtonEnabled = 1 << 0, // enable the 'menu' UIBarButtonItem
    MFSideMenuOptionBackButtonEnabled = 1 << 1, // enable the 'back' UIBarButtonItem
    MFSideMenuOptionShadowEnabled = 1 << 2
} MFSideMenuOptions;

typedef enum {
    MFSideMenuPanModeNavigationBar = 1 << 0, // enable panning on the navigation bar
    MFSideMenuPanModeNavigationController = 1 << 1 // enable panning on the body of the navigation controller
} MFSideMenuPanMode;


@interface MFSideMenu : NSObject<UIGestureRecognizerDelegate>

@property (nonatomic, assign) UINavigationController *navigationController;
@property (nonatomic, strong) UITableViewController *sideMenuController;
@property (nonatomic, assign) MFSideMenuState menuState;
@property (nonatomic, assign) MFSideMenuPanMode panMode;

+ (MFSideMenu *) menuWithNavigationController:(UINavigationController *)controller
                        sideMenuController:(id)menuController;

+ (MFSideMenu *) menuWithNavigationController:(UINavigationController *)controller
                        sideMenuController:(id)menuController
                                  location:(MFSideMenuLocation)side
                                   options:(MFSideMenuOptions)options;

+ (MFSideMenu *) menuWithNavigationController:(UINavigationController *)controller
                   sideMenuController:(id)menuController
                             location:(MFSideMenuLocation)side
                              options:(MFSideMenuOptions)options
                              panMode:(MFSideMenuPanMode)panMode;

- (UIBarButtonItem *) menuBarButtonItem;
- (UIBarButtonItem *) backBarButtonItem;
- (void) setupSideMenuBarButtonItem;

@end
