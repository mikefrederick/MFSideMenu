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
@property (nonatomic, assign) CGFloat velocity;

- (void)setMenuState:(MFSideMenuState)menuState animationDuration:(NSTimeInterval)duration;

// view controllers should call this on viewDidLoad in order to setup the proper UIBarButtonItem
- (void) setupSideMenuBarButtonItem;

@end
