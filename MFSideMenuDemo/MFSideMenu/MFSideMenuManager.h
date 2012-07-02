//
//  MFSideMenuManager.h
//
//  Created by Michael Frederick on 3/18/12.
//

#import <Foundation/Foundation.h>

#define kSidebarWidth 270

@interface MFSideMenuManager : NSObject<UIGestureRecognizerDelegate> {
    CGPoint originalOrigin;
}

@property (nonatomic, strong) UINavigationController *navigationController;
@property (nonatomic, strong) UITableViewController *sideMenuController;

+ (MFSideMenuManager *) sharedManager;

// this is all you should need to setup your app
+ (void) configureWithNavigationController:(UINavigationController *)controller 
                        sideMenuController:(id)menuController;

@end
