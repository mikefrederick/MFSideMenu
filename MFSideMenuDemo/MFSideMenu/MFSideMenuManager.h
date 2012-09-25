//
//  MFSideMenuManager.h
//
//  Created by Michael Frederick on 3/18/12.
//

#import <Foundation/Foundation.h>

#define kSidebarWidth 270

typedef enum {
    MFSideMenuLocationLeft, // show the menu on the left hand side
    MFSideMenuLocationRight // show the menu on the right hand side
} MFSideMenuLocation;

typedef enum {
    MFSideMenuOptionMenuButtonEnabled = 1 << 0, // enable the 'menu' UIBarButtonItem
    MFSideMenuOptionBackButtonEnabled = 1 << 1 // enable the 'back' UIBarButtonItem
} MFSideMenuOptions;


@interface MFSideMenuManager : NSObject<UIGestureRecognizerDelegate> {
    CGPoint originalOrigin;
}

@property (nonatomic, strong) UINavigationController *navigationController;
@property (nonatomic, strong) UITableViewController *sideMenuController;
@property (nonatomic, assign) MFSideMenuLocation menuSide;
@property (nonatomic, assign) MFSideMenuOptions options;

+ (MFSideMenuManager *) sharedManager;

+ (void) configureWithNavigationController:(UINavigationController *)controller 
                        sideMenuController:(id)menuController;

+ (void) configureWithNavigationController:(UINavigationController *)controller
                        sideMenuController:(id)menuController
                                  menuSide:(MFSideMenuLocation)side
                                   options:(MFSideMenuOptions)options;

// the x position of the nav controller when the menu is shown
+ (CGFloat) menuVisibleNavigationControllerXPosition;

+ (BOOL) menuButtonEnabled;
+ (BOOL) backButtonEnabled;

@end
