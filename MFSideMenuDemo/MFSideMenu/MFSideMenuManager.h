//
//  MFSideMenuManager.h
//
//  Created by Michael Frederick on 3/18/12.
//

#import <Foundation/Foundation.h>

#define kSidebarWidth 270

typedef enum {
    MenuLeftHandSide, // show the menu on the left hand side
    MenuRightHandSide // show the menu on the right hand side
} MenuSide;

typedef enum {
    MenuButtonEnabled = 1 << 0, // enable the 'menu' UIBarButtonItem
    BackButtonEnabled = 1 << 1 // enable the 'back' UIBarButtonItem
} MenuOptions;


@interface MFSideMenuManager : NSObject<UIGestureRecognizerDelegate> {
    CGPoint originalOrigin;
}

@property (nonatomic, strong) UINavigationController *navigationController;
@property (nonatomic, strong) UITableViewController *sideMenuController;
@property (nonatomic, assign) MenuSide menuSide;
@property (nonatomic, assign) MenuOptions options;

+ (MFSideMenuManager *) sharedManager;

+ (void) configureWithNavigationController:(UINavigationController *)controller 
                        sideMenuController:(id)menuController;

+ (void) configureWithNavigationController:(UINavigationController *)controller
                        sideMenuController:(id)menuController
                                  menuSide:(MenuSide)side
                                   options:(MenuOptions)options;

// the x position of the nav controller when the menu is shown
+ (CGFloat) menuVisibleNavigationControllerXPosition;

+ (BOOL) menuButtonEnabled;
+ (BOOL) backButtonEnabled;

@end
