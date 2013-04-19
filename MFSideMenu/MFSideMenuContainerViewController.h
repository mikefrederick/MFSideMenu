//
//  MFSideMenuContainerViewController.h
//  MFSideMenuDemoSplitViewController
//
//  Created by Michael Frederick on 4/2/13.
//  Copyright (c) 2013 Frederick Development. All rights reserved.
//

#import <UIKit/UIKit.h>

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


@interface MFSideMenuContainerViewController : UIViewController<UIGestureRecognizerDelegate>

+ (MFSideMenuContainerViewController *)controllerWithLeftSideMenuViewController:(id)leftSideMenuViewController
                                                           centerViewController:(id)centerViewController
                                                    rightSideMenuViewController:(id)rightSideMenuViewController;

@property (nonatomic, assign) MFSideMenuState menuState;
@property (nonatomic, assign) MFSideMenuPanMode panMode;

@property (nonatomic, assign) CGFloat menuAnimationDefaultDuration; // default duration for the open/close animation
@property (nonatomic, assign) CGFloat menuAnimationMaxDuration; // maximum duration for the open/close animation

@property (nonatomic, assign) CGFloat menuWidth; // size of the side menu(s)

@property (nonatomic, assign) BOOL shadowEnabled;
@property (nonatomic, assign) CGFloat shadowRadius;
@property (nonatomic, assign) CGFloat shadowOpacity;
@property (nonatomic, strong) UIColor *shadowColor;

@property (nonatomic, assign) BOOL menuSlideAnimationEnabled; // should the menus slide in/out with the root controller?
@property (nonatomic, assign) CGFloat menuSlideFactor; // higher = less menu movement on animation (only applicable if menuSlideAnimationEnabled is YES)

- (void)toggleLeftSideMenuCompletion:(void (^)(void))completion;
- (void)toggleRightSideMenuCompletion:(void (^)(void))completion;
- (void)setMenuState:(MFSideMenuState)menuState completion:(void (^)(void))completion;
- (void)setMenuWidth:(CGFloat)menuWidth animated:(BOOL)animated;

@end
