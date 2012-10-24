//
//  MFSideMenu.h
//
//  Created by Michael Frederick on 3/17/12.
//

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

@property (nonatomic, strong) UINavigationController *navigationController;
@property (nonatomic, strong) UITableViewController *sideMenuController;
@property (nonatomic, assign) MFSideMenuLocation menuSide;
@property (nonatomic, assign) MFSideMenuOptions options;
@property (nonatomic, assign) MFSideMenuPanMode panMode;

+ (MFSideMenu *) sharedMenu;

+ (void) menuWithNavigationController:(UINavigationController *)controller
                        sideMenuController:(id)menuController;

+ (void) menuWithNavigationController:(UINavigationController *)controller
                        sideMenuController:(id)menuController
                                  location:(MFSideMenuLocation)side
                                   options:(MFSideMenuOptions)options;

+ (void) menuWithNavigationController:(UINavigationController *)controller
                   sideMenuController:(id)menuController
                             location:(MFSideMenuLocation)side
                              options:(MFSideMenuOptions)options
                              panMode:(MFSideMenuPanMode)panMode;

+ (UIBarButtonItem *) menuBarButtonItem;
+ (UIBarButtonItem *) backBarButtonItem;
- (void) setupSideMenuBarButtonItem;

- (void) setMenuState:(MFSideMenuState)menuState animated:(BOOL)animated;


@end
