//
//  UIViewController+MFSideMenu.h
//
//  Created by Michael Frederick on 3/18/12.
//

#import <UIKit/UIKit.h>

#define kMenuAnimationDuration 0.2
#define kMenuAnimationMaxDuration 0.4

typedef enum {
    MFSideMenuStateHidden,
    MFSideMenuStateVisible
} MFSideMenuState;

@interface UIViewController (MFSideMenu)

@property (nonatomic, assign) MFSideMenuState menuState;

// velocity is used in attempt to animate the menu at the speed at which the user swipes it open/closed
@property (nonatomic, assign) CGFloat velocity;

- (void)setMenuState:(MFSideMenuState)menuState animationDuration:(NSTimeInterval)duration;

// view controllers can call this in order to setup the proper UIBarButtonItem
- (void) setupSideMenuBarButtonItem;

@end
