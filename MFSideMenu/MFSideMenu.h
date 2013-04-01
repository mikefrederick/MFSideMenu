//
//  MFSideMenu.h
//
//  Created by Michael Frederick on 3/17/12.
//

#import "UINavigationController+MFSideMenu.h"

static const CGFloat kMFSideMenuAnimationDuration = 0.2f; // default duration for the open/close animation
static const CGFloat kMFSideMenuAnimationMaxDuration = 0.4f; // maximum duration for the open/close animation

typedef enum {
    MFSideMenuPanModeNone = 0, // pan disabled
    MFSideMenuPanModeRootViewController = 1 << 0, // enable panning on the root view controller, i.e. the navigation controller
    MFSideMenuPanModeSideMenu = 1 << 2, // enable panning on side menus
    MFSideMenuPanModeDefault = MFSideMenuPanModeRootViewController | MFSideMenuPanModeSideMenu
} MFSideMenuPanMode;

typedef enum {
    MFSideMenuStateClosed, // the menu is closed
    MFSideMenuStateLeftMenuOpen, // the left-hand menu is open
    MFSideMenuStateRightMenuOpen // the right-hand menu is open
} MFSideMenuState;

typedef enum {
    MFSideMenuStateEventMenuWillOpen, // the menu is going to open
    MFSideMenuStateEventMenuDidOpen, // the menu finished opening
    MFSideMenuStateEventMenuWillClose, // the menu is going to close
    MFSideMenuStateEventMenuDidClose // the menu finished closing
} MFSideMenuStateEvent;

typedef void (^MFSideMenuStateEventBlock)(MFSideMenuStateEvent);

@interface MFSideMenu : NSObject<UIGestureRecognizerDelegate>

@property (nonatomic, readonly) UINavigationController *navigationController;

@property (nonatomic, assign) MFSideMenuState menuState;
@property (nonatomic, assign) MFSideMenuPanMode panMode;
@property (nonatomic, assign) BOOL shadowEnabled;
@property (nonatomic, assign) CGFloat menuWidth; // size of the side menu(s)
@property (nonatomic, assign) CGFloat shadowRadius; // radius of the shadow
@property (nonatomic, assign) CGFloat shadowOpacity;
@property (nonatomic, strong) UIColor *shadowColor;
@property (nonatomic, assign) BOOL menuSlideAnimationEnabled; // should the menus slide in/out with the root controller?
@property (nonatomic, assign) CGFloat menuSlideFactor; // higher = less menu movement on the menu slide animation
                                                       // (only applicable if menuSlideAnimationEnabled is YES)

// this can be used to observe all MFSideMenuStateEvents
@property (copy) MFSideMenuStateEventBlock menuStateEventBlock;

+ (MFSideMenu *)menuWithNavigationController:(UINavigationController *)controller
                      leftSideMenuController:(id)leftMenuController
                     rightSideMenuController:(id)rightMenuController;

+ (MFSideMenu *)menuWithNavigationController:(UINavigationController *)controller
                       leftSideMenuController:(id)leftMenuController
                      rightSideMenuController:(id)rightMenuController
                                      panMode:(MFSideMenuPanMode)panMode;


- (void)toggleLeftSideMenu;
- (void)toggleRightSideMenu;
- (void)setMenuWidth:(CGFloat)menuWidth animated:(BOOL)animated;

@end
