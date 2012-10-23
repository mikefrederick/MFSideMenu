//
//  MFSideMenu.m
//  MFSideMenuDemo
//
//  Created by Michael Frederick on 10/22/12.
//  Copyright (c) 2012 University of Wisconsin - Madison. All rights reserved.
//

#import "MFSideMenu.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

@interface MFSideMenu() {
    CGPoint panGestureOrigin;
}
@end

@implementation MFSideMenu

@synthesize navigationController;
@synthesize sideMenuController;
@synthesize menuSide;
@synthesize options;
@synthesize panMode;

static char menuStateKey;
static char velocityKey;

+ (MFSideMenu *) sharedMenu {
    static dispatch_once_t once;
    static MFSideMenu *sharedMenu;
    dispatch_once(&once, ^ { sharedMenu = [[MFSideMenu alloc] init]; });
    return sharedMenu;
}

+ (void) menuWithNavigationController:(UINavigationController *)controller
                        sideMenuController:(id)menuController {
    MFSideMenuOptions options = MFSideMenuOptionMenuButtonEnabled|MFSideMenuOptionBackButtonEnabled;
    
    [MFSideMenu menuWithNavigationController:controller
                          sideMenuController:menuController
                                    location:MFSideMenuLocationLeft
                                     options:options];
}

+ (void) menuWithNavigationController:(UINavigationController *)controller
                        sideMenuController:(id)menuController
                                  location:(MFSideMenuLocation)side
                                   options:(MFSideMenuOptions)options {
    MFSideMenuPanMode panMode = MFSideMenuPanModeNavigationBar|MFSideMenuPanModeNavigationController;
    
    [MFSideMenu menuWithNavigationController:controller
                          sideMenuController:menuController
                                    location:MFSideMenuLocationLeft
                                     options:options
                                     panMode:panMode];
}

+ (void) menuWithNavigationController:(UINavigationController *)controller
                   sideMenuController:(id)menuController
                             location:(MFSideMenuLocation)side
                              options:(MFSideMenuOptions)options
                              panMode:(MFSideMenuPanMode)panMode {
    MFSideMenu *menu = [MFSideMenu sharedMenu];
    menu.navigationController = controller;
    menu.sideMenuController = menuController;
    menu.menuSide = side;
    menu.options = options;
    menu.panMode = panMode;
    
    [menu setMenuState:MFSideMenuStateHidden animated:NO];
    
    if(controller.viewControllers && controller.viewControllers.count) {
        // we need to do this b/c the options to show the barButtonItem
        // weren't set yet when viewDidLoad of the topViewController was called
        [menu setupSideMenuBarButtonItem];
    }
    
    UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc]
                                          initWithTarget:menu action:@selector(navigationBarPanned:)];
    [recognizer setMinimumNumberOfTouches:1];
	[recognizer setMaximumNumberOfTouches:1];
    [recognizer setDelegate:menu];
    [controller.navigationBar addGestureRecognizer:recognizer];
    
    recognizer = [[UIPanGestureRecognizer alloc]
                  initWithTarget:menu action:@selector(navigationControllerPanned:)];
    [recognizer setMinimumNumberOfTouches:1];
	[recognizer setMaximumNumberOfTouches:1];
    [recognizer setDelegate:menu];
    [controller.view addGestureRecognizer:recognizer];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc]
                                             initWithTarget:menu action:@selector(navigationControllerTapped:)];
    [tapRecognizer setDelegate:menu];
    [controller.view addGestureRecognizer:tapRecognizer];
    
    [[NSNotificationCenter defaultCenter] addObserver:menu
                                             selector:@selector(statusBarOrientationDidChange:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    
    if(side == MFSideMenuLocationRight) {
        // on the right hand side the shadowpath doesn't start at 0 so we have to redraw it when the device flips
        [[NSNotificationCenter defaultCenter] addObserver:menu
                                                 selector:@selector(drawNavigationControllerShadowPath)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
    }
    
    [controller.view.superview insertSubview:[menuController view] belowSubview:controller.view];
    
    // we need to reorient from the status bar here incase the initial orientation is landscape
    [menu orientSideMenuFromStatusBar];
    
    [menu drawNavigationControllerShadowPath];
    controller.view.layer.shadowOpacity = 0.75f;
    controller.view.layer.shadowRadius = kMFSideMenuShadowWidth;
    controller.view.layer.shadowColor = [UIColor blackColor].CGColor;
}

// draw a shadow between the navigation controller and the menu
- (void) drawNavigationControllerShadowPath {
    CGRect pathRect = self.navigationController.view.bounds;
    if(self.menuSide == MFSideMenuLocationRight) {
        // draw the shadow on the right hand side of the navigationController
        pathRect.origin.x = pathRect.size.width - kMFSideMenuShadowWidth;
    }
    pathRect.size.width = kMFSideMenuShadowWidth;
    
    self.navigationController.view.layer.shadowPath = [UIBezierPath bezierPathWithRect:pathRect].CGPath;
}


#pragma mark -
#pragma mark - MFSideMenuOptions

- (BOOL) menuButtonEnabled {
    return ((self.options & MFSideMenuOptionMenuButtonEnabled) == MFSideMenuOptionMenuButtonEnabled);
}

- (BOOL) backButtonEnabled {
    return ((self.options & MFSideMenuOptionBackButtonEnabled) == MFSideMenuOptionBackButtonEnabled);
}


#pragma mark -
#pragma mark - MFSideMenuPanMode

- (BOOL) navigationControllerPanEnabled {
    return ((self.panMode & MFSideMenuPanModeNavigationController) == MFSideMenuPanModeNavigationController);
}

- (BOOL) navigationBarPanEnabled {
    return ((self.panMode & MFSideMenuPanModeNavigationBar) == MFSideMenuPanModeNavigationBar);
}


#pragma mark - 
#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:[UIControl class]]) return NO;
    if ([touch.view isKindOfClass:[UITableViewCell class]] ||
        [touch.view.superview isKindOfClass:[UITableViewCell class]]) return NO;
    
    if([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] &&
       self.menuState != MFSideMenuStateHidden) return YES;
    
    if([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        if([gestureRecognizer.view isEqual:self.navigationController.view] &&
           [self navigationControllerPanEnabled]) return YES;
        
        if([gestureRecognizer.view isEqual:self.navigationController.navigationBar] &&
           self.menuState == MFSideMenuStateHidden &&
           [self navigationBarPanEnabled]) return YES;
    }
    
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
        shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
	return ![gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]];
}


#pragma mark -
#pragma mark - UIGestureRecognizer callbacks

// this method handles the navigation bar pan event
// and sets the navigation controller's frame as needed
- (void) handleNavigationBarPan:(UIPanGestureRecognizer *)recognizer {
    UIView *view = self.navigationController.view;
    
	if(recognizer.state == UIGestureRecognizerStateBegan) {
        // remember where the pan started
        panGestureOrigin = view.frame.origin;
	}
    
    CGPoint translatedPoint = [recognizer translationInView:view];
    CGPoint adjustedOrigin = [self pointAdjustedForInterfaceOrientation:panGestureOrigin];
    translatedPoint = CGPointMake(adjustedOrigin.x + translatedPoint.x,
                                  adjustedOrigin.y + translatedPoint.y);
    
    if(self.menuSide == MFSideMenuLocationLeft) {
        translatedPoint.x = MIN(translatedPoint.x, kMFSideMenuSidebarWidth);
        translatedPoint.x = MAX(translatedPoint.x, 0);
    } else {
        translatedPoint.x = MAX(translatedPoint.x, -1*kMFSideMenuSidebarWidth);
        translatedPoint.x = MIN(translatedPoint.x, 0);
    }
    
    [self setNavigationControllerOffset:translatedPoint.x];
    
	if(recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [recognizer velocityInView:view];
        CGFloat finalX = translatedPoint.x + (.35*velocity.x);
        CGFloat viewWidth = [self widthAdjustedForInterfaceOrientation:view];
        
        if(self.menuState == MFSideMenuStateHidden) {
            BOOL showMenu = (self.menuSide == MFSideMenuLocationLeft) ? (finalX > viewWidth/2) : (finalX < -1*viewWidth/2);
            if(showMenu) {
                self.velocity = velocity.x;
                [self setMenuState:MFSideMenuStateVisible animated:YES];
            } else {
                self.velocity = 0;
                [UIView beginAnimations:nil context:NULL];
                [self setNavigationControllerOffset:0];
                [UIView commitAnimations];
            }
        } else if(self.menuState == MFSideMenuStateVisible) {
            BOOL hideMenu = (self.menuSide == MFSideMenuLocationLeft) ? (finalX < adjustedOrigin.x) : (finalX > adjustedOrigin.x);
            if(hideMenu) {
                self.velocity = velocity.x;
                [self setMenuState:MFSideMenuStateHidden animated:YES];
            } else {
                self.velocity = 0;
                [UIView beginAnimations:nil context:NULL];
                [self setNavigationControllerOffset:adjustedOrigin.x];
                [UIView commitAnimations];
            }
        }
	}
}

- (void) navigationControllerTapped:(id)sender {
    if(self.menuState != MFSideMenuStateHidden) {
        [self setMenuState:MFSideMenuStateHidden animated:YES];
    }
}

- (void) navigationControllerPanned:(id)sender {
    // if(self.menuState == MFSideMenuStateHidden) return;
    
    [self handleNavigationBarPan:sender];
}

- (void) navigationBarPanned:(id)sender {
    if(self.menuState != MFSideMenuStateHidden) return;
    
    [self handleNavigationBarPan:sender];
}


#pragma mark -
#pragma mark - Gesture Recognizer Helpers

- (CGPoint) pointAdjustedForInterfaceOrientation:(CGPoint)point {
    switch (self.navigationController.interfaceOrientation)
    {
        case UIInterfaceOrientationPortrait:
            return CGPointMake(point.x, point.y);
            break;
            
        case UIInterfaceOrientationPortraitUpsideDown:
            return CGPointMake(-1*point.x, -1*point.y);
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
            return CGPointMake(-1*point.y, -1*point.x);
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            return CGPointMake(point.y, point.x);
            break;
    }
}

- (CGFloat) widthAdjustedForInterfaceOrientation:(UIView *)view {
    if(UIInterfaceOrientationIsPortrait(self.navigationController.interfaceOrientation)) {
        return view.frame.size.width;
    } else {
        return view.frame.size.height;
    }
}


#pragma mark -
#pragma mark - Side Menu Rotation

- (void) orientSideMenuFromStatusBar {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    CGFloat angle = 0.0;
    CGRect newFrame = self.sideMenuController.view.window.bounds;
    CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
    
    switch (orientation) {
        case UIInterfaceOrientationPortraitUpsideDown:
            angle = M_PI;
            newFrame.size.height -= statusBarSize.height;
            if(self.menuSide == MFSideMenuLocationRight) {
                newFrame.origin.x = -1*newFrame.size.width + kMFSideMenuSidebarWidth;
            }
            break;
        case UIInterfaceOrientationLandscapeLeft:
            angle = - M_PI / 2.0f;
            newFrame.origin.x += statusBarSize.width;
            newFrame.size.width -= statusBarSize.width;
            if(self.menuSide == MFSideMenuLocationRight) {
                newFrame.origin.y = -1*newFrame.size.height + kMFSideMenuSidebarWidth;
            }
            break;
        case UIInterfaceOrientationLandscapeRight:
            angle = M_PI / 2.0f;
            newFrame.size.width -= statusBarSize.width;
            if(self.menuSide == MFSideMenuLocationRight) {
                newFrame.origin.y = newFrame.size.height - kMFSideMenuSidebarWidth;
            }
            break;
        default: // as UIInterfaceOrientationPortrait
            angle = 0.0;
            newFrame.origin.y += statusBarSize.height;
            newFrame.size.height -= statusBarSize.height;
            if(self.menuSide == MFSideMenuLocationRight) {
                newFrame.origin.x = newFrame.size.width - kMFSideMenuSidebarWidth;
            }
            break;
    }
    
    self.sideMenuController.view.transform = CGAffineTransformMakeRotation(angle);
    self.sideMenuController.view.frame = newFrame;
}

- (void)statusBarOrientationDidChange:(NSNotification *)notification {
    [self orientSideMenuFromStatusBar];
    
    if(self.menuState == MFSideMenuStateVisible) {
        [self setMenuState:MFSideMenuStateHidden animated:YES];
    }
}


#pragma mark -
#pragma mark - UIBarButtonItems

+ (UIBarButtonItem *)menuBarButtonItem {
    return [[UIBarButtonItem alloc]
            initWithImage:[UIImage imageNamed:@"menu-icon.png"] style:UIBarButtonItemStyleBordered
            target:[MFSideMenu sharedMenu]
            action:@selector(toggleSideMenuPressed:)];
}

+ (UIBarButtonItem *)backBarButtonItem {
    return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back-arrow"]
                                            style:UIBarButtonItemStyleBordered
                                           target:[MFSideMenu sharedMenu]
                                           action:@selector(backButtonPressed:)];
}

- (void) setupSideMenuBarButtonItem {
    UINavigationItem *navigationItem = self.navigationController.topViewController.navigationItem;
    if(self.menuSide == MFSideMenuLocationRight
       && [self menuButtonEnabled]) {
        navigationItem.rightBarButtonItem = [MFSideMenu menuBarButtonItem];
        return;
    }
    
    if(self.menuState == MFSideMenuStateVisible || self.navigationController.viewControllers.count == 1) {
        // we are dealing with the root view controller
        if([self menuButtonEnabled]) {
            navigationItem.leftBarButtonItem = [MFSideMenu menuBarButtonItem];
        }
    } else {
        if(self.menuSide == MFSideMenuLocationLeft) {
            if([self backButtonEnabled]) {
                navigationItem.leftBarButtonItem = [MFSideMenu backBarButtonItem];
            }
        }
    }
}

- (void) toggleSideMenuPressed:(id)sender {
    if(self.menuState == MFSideMenuStateVisible) {
        [self setMenuState:MFSideMenuStateHidden animated:YES];
    } else {
        [self setMenuState:MFSideMenuStateVisible animated:YES];
    }
}

- (void) backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark - Menu State

- (void)setMenuState:(MFSideMenuState)menuState animated:(BOOL)animated {
    [self setMenuState:menuState animationDuration:(animated) ? kMenuAnimationDuration : 0];
}

- (void)setMenuState:(MFSideMenuState)menuState animationDuration:(NSTimeInterval)duration {
    MFSideMenuState currentState = self.menuState;
    
    objc_setAssociatedObject(self, &menuStateKey, [NSNumber numberWithInt:menuState], OBJC_ASSOCIATION_RETAIN);
    
    switch (currentState) {
        case MFSideMenuStateHidden:
            if (menuState == MFSideMenuStateVisible) {
                [self toggleSideMenuHidden:NO];
            }
            break;
        case MFSideMenuStateVisible:
            if (menuState == MFSideMenuStateHidden) {
                [self toggleSideMenuHidden:YES];
            }
            break;
        default:
            break;
    }
}

- (MFSideMenuState)menuState {
    return (MFSideMenuState)[objc_getAssociatedObject(self, &menuStateKey) intValue];
}

- (void)setVelocity:(CGFloat)velocity {
    objc_setAssociatedObject(self, &velocityKey, [NSNumber numberWithFloat:velocity], OBJC_ASSOCIATION_RETAIN);
}

- (CGFloat)velocity {
    return (CGFloat)[objc_getAssociatedObject(self, &velocityKey) floatValue];
}


#pragma mark -
#pragma mark - Navigation Controller Movement

- (void) setNavigationControllerOffset:(CGFloat)xOffset {
    CGRect frame = self.navigationController.view.frame;
    frame.origin = CGPointZero;
    switch (self.navigationController.interfaceOrientation)
    {
        case UIInterfaceOrientationPortrait:
            frame.origin.x = xOffset;
            break;
            
        case UIInterfaceOrientationPortraitUpsideDown:
            frame.origin.x = -1*xOffset;
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
            frame.origin.y = -1*xOffset;
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            frame.origin.y = xOffset;
            break;
    }
    
    self.navigationController.view.frame = frame;
}

- (void) toggleSideMenuHidden:(BOOL)hidden {
    CGFloat x = ABS([self pointAdjustedForInterfaceOrientation:self.navigationController.view.frame.origin].x);
    
    CGFloat navigationControllerXPosition = ([MFSideMenu sharedMenu].menuSide == MFSideMenuLocationLeft) ? kMFSideMenuSidebarWidth : -1*kMFSideMenuSidebarWidth;
    CGFloat animationPositionDelta = (hidden) ? x : (navigationControllerXPosition  - x);
    
    CGFloat duration;
    
    if(ABS(self.velocity) > 1.0) {
        // try to continue the animation at the speed the user was swiping
        duration = animationPositionDelta / ABS(self.velocity);
    } else {
        // no swipe was used, user tapped the bar button item
        CGFloat animationDurationPerPixel = kMenuAnimationDuration / navigationControllerXPosition;
        duration = animationDurationPerPixel * animationPositionDelta;
    }
    
    if(duration > kMenuAnimationMaxDuration) duration = kMenuAnimationMaxDuration;
    
    [UIView animateWithDuration:duration animations:^{
        CGFloat xPosition = (hidden) ? 0 : navigationControllerXPosition;
        [self setNavigationControllerOffset:xPosition];
    } completion:^(BOOL finished) {
        [self setupSideMenuBarButtonItem];
        
        // disable user interaction on the current view controller if the menu is visible
        self.navigationController.visibleViewController.view.userInteractionEnabled = (self.menuState == MFSideMenuStateHidden);
    }];
}

@end
