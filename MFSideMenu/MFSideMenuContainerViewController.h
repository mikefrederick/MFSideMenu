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
    MFSideMenuPanModeCenterViewController = 1 << 0, // enable panning on the centerViewController
    MFSideMenuPanModeSideMenu = 1 << 1, // enable panning on side menus
    MFSideMenuPanModeDefault = MFSideMenuPanModeCenterViewController | MFSideMenuPanModeSideMenu
} MFSideMenuPanMode;

typedef enum {
    MFSideMenuStateClosed, // the menu is closed
    MFSideMenuStateLeftMenuOpen, // the left-hand menu is open
    MFSideMenuStateRightMenuOpen // the right-hand menu is open
} MFSideMenuState;


@interface MFSideMenuContainerViewController : UIViewController<UIGestureRecognizerDelegate>

+ (MFSideMenuContainerViewController *)containerWithCenterViewController:(id)centerViewController
                                                  leftMenuViewController:(id)leftMenuViewController
                                                 rightMenuViewController:(id)rightMenuViewController;

@property (nonatomic, strong) UIViewController *centerViewController;
@property (nonatomic, strong) UIViewController *leftMenuViewController;
@property (nonatomic, strong) UIViewController *rightMenuViewController;

@property (nonatomic, assign) MFSideMenuState menuState;
@property (nonatomic, assign) MFSideMenuPanMode panMode;

// menu open/close animation duration -- user can pan faster than default duration, max duration sets the limit
@property (nonatomic, assign) CGFloat menuAnimationDefaultDuration;
@property (nonatomic, assign) CGFloat menuAnimationMaxDuration;

// width of the side menus
@property (nonatomic, assign) CGFloat menuWidth;

// shadow
@property (nonatomic, assign) BOOL shadowEnabled;
@property (nonatomic, assign) CGFloat shadowRadius;
@property (nonatomic, assign) CGFloat shadowOpacity;
@property (nonatomic, strong) UIColor *shadowColor;

// menu slide-in animation
@property (nonatomic, assign) BOOL menuSlideAnimationEnabled;
@property (nonatomic, assign) CGFloat menuSlideAnimationFactor; // higher = less menu movement on animation


- (void)toggleLeftSideMenuCompletion:(void (^)(void))completion;
- (void)toggleRightSideMenuCompletion:(void (^)(void))completion;
- (void)setMenuState:(MFSideMenuState)menuState completion:(void (^)(void))completion;
- (void)setMenuWidth:(CGFloat)menuWidth animated:(BOOL)animated;

@end
