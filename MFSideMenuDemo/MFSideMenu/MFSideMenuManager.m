//
//  MFSideMenuManager.m
//
//  Created by Michael Frederick on 3/18/12.
//

#import "MFSideMenuManager.h"
#import "UIViewController+MFSideMenu.h"
#import <QuartzCore/QuartzCore.h>

@implementation MFSideMenuManager

@synthesize navigationController;
@synthesize sideMenuController;

+ (MFSideMenuManager *) sharedManager {
    static dispatch_once_t once;
    static MFSideMenuManager *sharedManager;
    dispatch_once(&once, ^ { sharedManager = [[MFSideMenuManager alloc] init]; });
    return sharedManager;
}

+ (void) configureWithNavigationController:(UINavigationController *)controller 
                        sideMenuController:(id)menuController {
    MFSideMenuManager *manager = [MFSideMenuManager sharedManager];
    manager.navigationController = controller;
    manager.sideMenuController = menuController;
    
    [controller setMenuState:MFSideMenuStateHidden];
    
    UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc] 
                                          initWithTarget:manager action:@selector(navigationBarPanned:)];
    [recognizer setMinimumNumberOfTouches:1];
	[recognizer setMaximumNumberOfTouches:1];
    [recognizer setDelegate:manager];
    [controller.navigationBar addGestureRecognizer:recognizer];
    [recognizer release];
    
    recognizer = [[UIPanGestureRecognizer alloc] 
                  initWithTarget:manager action:@selector(navigationControllerPanned:)];
    [recognizer setMinimumNumberOfTouches:1];
	[recognizer setMaximumNumberOfTouches:1];
    [recognizer setDelegate:manager];
    [controller.view addGestureRecognizer:recognizer];
    [recognizer release];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] 
                                             initWithTarget:manager action:@selector(navigationControllerTapped:)];
    [tapRecognizer setDelegate:manager];
    [controller.view addGestureRecognizer:tapRecognizer];
    [tapRecognizer release];
    
    [controller.view.superview insertSubview:[menuController view] belowSubview:controller.view];
    
    controller.view.layer.shadowOpacity = 0.75f;
    controller.view.layer.shadowRadius = 10.0f;
    controller.view.layer.shadowColor = [UIColor blackColor].CGColor;
}


#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] && 
       self.navigationController.menuState != MFSideMenuStateHidden) return YES;
    
    if([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        if([gestureRecognizer.view isEqual:self.navigationController.view] && 
           self.navigationController.menuState != MFSideMenuStateHidden) return YES;
        
        if([gestureRecognizer.view isEqual:self.navigationController.navigationBar] && 
           self.navigationController.menuState == MFSideMenuStateHidden) return YES;
    }
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer 
    shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
	return ![gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]];
}

- (void) navigationControllerTapped:(id)sender {
    if(self.navigationController.menuState != MFSideMenuStateHidden) {
        [self.navigationController setMenuState:MFSideMenuStateHidden];
    }
}

- (void) handlePan:(UIPanGestureRecognizer *)recognizer {    
    UIView *view = self.navigationController.view;
    
	if(recognizer.state == UIGestureRecognizerStateBegan) {
		originalCenter = view.center;
	}
    
    CGPoint translatedPoint = [recognizer translationInView:view];
    translatedPoint = CGPointMake(originalCenter.x+translatedPoint.x, originalCenter.y+translatedPoint.y);
    
    translatedPoint.x = MIN(translatedPoint.x, kSidebarWidth + view.frame.size.width/2);
    translatedPoint.x = MAX(translatedPoint.x, 0 + view.frame.size.width/2);
    
    view.center = CGPointMake(translatedPoint.x, view.center.y);
    
	if(recognizer.state == UIGestureRecognizerStateEnded) {
        CGFloat finalX = translatedPoint.x + (.35*[recognizer velocityInView:view].x);
        
        if(self.navigationController.menuState == MFSideMenuStateHidden) {
            if(finalX - view.frame.size.width/2 > view.frame.size.width/2) {
                [self.navigationController setMenuState:MFSideMenuStateVisible];
            } else {
                [UIView beginAnimations:nil context:NULL];
                view.center = originalCenter;
                [UIView commitAnimations];
            }
        } else if(self.navigationController.menuState == MFSideMenuStateVisible) {
            if(finalX < originalCenter.x) {
                [self.navigationController setMenuState:MFSideMenuStateHidden];
            } else {
                [UIView beginAnimations:nil context:NULL];
                view.center = originalCenter;
                [UIView commitAnimations];
            }
        }
	}
}

- (void) navigationControllerPanned:(id)sender {
    if(self.navigationController.menuState == MFSideMenuStateHidden) return;
    
    [self handlePan:sender];
}

- (void) navigationBarPanned:(id)sender {
    if(self.navigationController.menuState != MFSideMenuStateHidden) return;
    
    [self handlePan:sender];
}

@end
