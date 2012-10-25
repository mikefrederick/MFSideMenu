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

@property (nonatomic, assign, readwrite) UINavigationController *navigationController;
@property (nonatomic, strong, readwrite) UITableViewController *sideMenuController;

@property (nonatomic, assign) MFSideMenuLocation menuSide;
@property (nonatomic, assign) MFSideMenuOptions options;

// layout constraints for the sideMenuController
@property (nonatomic, strong) NSLayoutConstraint *topConstraint;
@property (nonatomic, strong) NSLayoutConstraint *rightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *bottomConstraint;
@property (nonatomic, strong) NSLayoutConstraint *leftConstraint;

@property (nonatomic, assign) CGFloat panGestureVelocity;

@end


@implementation MFSideMenu

@synthesize navigationController;
@synthesize sideMenuController;
@synthesize menuSide;
@synthesize options;
@synthesize panMode;
@synthesize topConstraint;
@synthesize rightConstraint;
@synthesize bottomConstraint;
@synthesize leftConstraint;
@synthesize panGestureVelocity;
@synthesize menuState = _menuState;
@synthesize menuStateEventBlock;


#pragma mark -
#pragma mark - Menu Creation

+ (MFSideMenu *) menuWithNavigationController:(UINavigationController *)controller
                        sideMenuController:(id)menuController {
    MFSideMenuOptions options = MFSideMenuOptionMenuButtonEnabled|MFSideMenuOptionBackButtonEnabled|MFSideMenuOptionShadowEnabled;
    
    return [MFSideMenu menuWithNavigationController:controller
                          sideMenuController:menuController
                                    location:MFSideMenuLocationLeft
                                     options:options];
}

+ (MFSideMenu *) menuWithNavigationController:(UINavigationController *)controller
                        sideMenuController:(id)menuController
                                  location:(MFSideMenuLocation)side
                                   options:(MFSideMenuOptions)options {
    MFSideMenuPanMode panMode = MFSideMenuPanModeNavigationBar|MFSideMenuPanModeNavigationController;
    
    return [MFSideMenu menuWithNavigationController:controller
                          sideMenuController:menuController
                                    location:MFSideMenuLocationLeft
                                     options:options
                                     panMode:panMode];
}

+ (MFSideMenu *) menuWithNavigationController:(UINavigationController *)controller
                   sideMenuController:(id)menuController
                             location:(MFSideMenuLocation)side
                              options:(MFSideMenuOptions)options
                              panMode:(MFSideMenuPanMode)panMode {
    MFSideMenu *menu = [[MFSideMenu alloc] init];
    menu.navigationController = controller;
    menu.sideMenuController = menuController;
    menu.menuSide = side;
    menu.options = options;
    menu.panMode = panMode;
    controller.sideMenu = menu;
    
    UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc]
                                          initWithTarget:menu action:@selector(navigationBarPanned:)];
	[recognizer setMaximumNumberOfTouches:1];
    [recognizer setDelegate:menu];
    [controller.navigationBar addGestureRecognizer:recognizer];
    
    recognizer = [[UIPanGestureRecognizer alloc]
                  initWithTarget:menu action:@selector(navigationControllerPanned:)];
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
    
    return menu;
}

#pragma mark -
#pragma mark - Navigation Controller View Lifecycle

- (void) navigationControllerWillAppear {
    [self setMenuState:MFSideMenuStateHidden];
    
    if(self.navigationController.viewControllers && self.navigationController.viewControllers.count) {
        // we need to do this b/c the options to show the barButtonItem
        // weren't set yet when viewDidLoad of the topViewController was called
        [self setupSideMenuBarButtonItem];
    }
}

- (void) navigationControllerDidAppear {
    UIView *menuView = self.sideMenuController.view;
    if(menuView.superview) return;
    
    UIView *windowRootView = self.rootViewController.view;
    UIView *containerView = windowRootView.superview;
    
    [containerView insertSubview:menuView belowSubview:windowRootView];
    
    [menuView setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.topConstraint = [[self class] edgeConstraint:NSLayoutAttributeTop subview:menuView];
    self.rightConstraint = [[self class] edgeConstraint:NSLayoutAttributeRight subview:menuView];
    self.bottomConstraint = [[self class] edgeConstraint:NSLayoutAttributeBottom subview:menuView];
    self.leftConstraint = [[self class] edgeConstraint:NSLayoutAttributeLeft subview:menuView];
    
    [containerView addConstraint:self.topConstraint];
    [containerView addConstraint:self.rightConstraint];
    [containerView addConstraint:self.bottomConstraint];
    [containerView addConstraint:self.leftConstraint];
    
    // we need to reorient from the status bar here incase the initial orientation is landscape
    [self orientSideMenuFromStatusBar];
    
    if([self shadowEnabled]) {
        // we have to redraw the shadow when the device flips
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(drawRootControllerShadowPath)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
        
        [self drawRootControllerShadowPath];
        self.rootViewController.view.layer.shadowOpacity = 0.75f;
        self.rootViewController.view.layer.shadowRadius = kMFSideMenuShadowWidth;
        self.rootViewController.view.layer.shadowColor = [UIColor blackColor].CGColor;
    }
}

- (void) navigationControllerDidDisappear {
    // we don't want the menu to be visible if the navigation controller is gone
    if(self.sideMenuController.view && self.sideMenuController.view.superview) {
        [self.sideMenuController.view removeFromSuperview];
    }
    
    NSArray *constraints = [NSArray arrayWithObjects:self.topConstraint, self.bottomConstraint,
                            self.leftConstraint, self.rightConstraint, nil];
    [self.rootViewController.view.superview removeConstraints:constraints];
}

+ (NSLayoutConstraint *)edgeConstraint:(NSLayoutAttribute)edge subview:(UIView *)subview {
    return [NSLayoutConstraint constraintWithItem:subview
                                        attribute:edge
                                        relatedBy:NSLayoutRelationEqual
                                           toItem:subview.superview
                                        attribute:edge
                                       multiplier:1
                                         constant:0];
}


#pragma mark -
#pragma mark - MFSideMenuOptions

- (BOOL) menuButtonEnabled {
    return ((self.options & MFSideMenuOptionMenuButtonEnabled) == MFSideMenuOptionMenuButtonEnabled);
}

- (BOOL) backButtonEnabled {
    return ((self.options & MFSideMenuOptionBackButtonEnabled) == MFSideMenuOptionBackButtonEnabled);
}

- (BOOL) shadowEnabled {
    return ((self.options & MFSideMenuOptionShadowEnabled) == MFSideMenuOptionShadowEnabled);
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
#pragma mark - UIBarButtonItems & Callbacks

- (UIBarButtonItem *)menuBarButtonItem {
    return [[UIBarButtonItem alloc]
            initWithImage:[UIImage imageNamed:@"menu-icon.png"] style:UIBarButtonItemStyleBordered
            target:self
            action:@selector(toggleSideMenuPressed:)];
}

- (UIBarButtonItem *)backBarButtonItem {
    return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back-arrow"]
                                            style:UIBarButtonItemStyleBordered
                                           target:self
                                           action:@selector(backButtonPressed:)];
}

- (void) setupSideMenuBarButtonItem {
    UINavigationItem *navigationItem = self.navigationController.topViewController.navigationItem;
    if([self menuButtonEnabled]) {
        if(self.menuSide == MFSideMenuLocationRight && !navigationItem.rightBarButtonItem) {
            navigationItem.rightBarButtonItem = [self menuBarButtonItem];
        } else if(self.menuSide == MFSideMenuLocationLeft &&
                  (self.menuState == MFSideMenuStateVisible || self.navigationController.viewControllers.count == 1)) {
            // show the menu button on the root view controller or if the menu is open
            navigationItem.leftBarButtonItem = [self menuBarButtonItem];
        }
    }
    
    if([self backButtonEnabled] && self.navigationController.viewControllers.count > 1
       && self.menuState == MFSideMenuStateHidden) {
        navigationItem.leftBarButtonItem = [self backBarButtonItem];
    }
}

- (void) toggleSideMenuPressed:(id)sender {
    if(self.menuState == MFSideMenuStateVisible) {
        [self setMenuState:MFSideMenuStateHidden];
    } else {
        [self setMenuState:MFSideMenuStateVisible];
    }
}

- (void) backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - 
#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:[UIControl class]]) return NO;
    
    if([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] &&
       self.menuState != MFSideMenuStateHidden) return YES;
    
    if([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        // we don't want to override UITableViewCell swipes
        if ([touch.view isKindOfClass:[UITableViewCell class]] ||
            [touch.view.superview isKindOfClass:[UITableViewCell class]]) return NO;
        
        if([gestureRecognizer.view isEqual:self.navigationController.view] &&
           [self navigationControllerPanEnabled]) return YES;
        
        if([gestureRecognizer.view isEqual:self.navigationController.navigationBar] &&
           self.menuState == MFSideMenuStateHidden &&
           [self navigationBarPanEnabled]) return YES;
    }
    
    return NO;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
        shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
	return NO;
}


#pragma mark -
#pragma mark - UIGestureRecognizer Callbacks

// this method handles the navigation bar pan event
// and sets the navigation controller's frame as needed
- (void) handleNavigationBarPan:(UIPanGestureRecognizer *)recognizer {
    UIView *view = self.rootViewController.view;
    
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
    
    [self setRootControllerOffset:translatedPoint.x];
    
	if(recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [recognizer velocityInView:view];
        CGFloat finalX = translatedPoint.x + (.35*velocity.x);
        CGFloat viewWidth = [self widthAdjustedForInterfaceOrientation:view];
        
        if(self.menuState == MFSideMenuStateHidden) {
            BOOL showMenu = (self.menuSide == MFSideMenuLocationLeft) ? (finalX > viewWidth/2) : (finalX < -1*viewWidth/2);
            if(showMenu) {
                self.panGestureVelocity = velocity.x;
                [self setMenuState:MFSideMenuStateVisible];
            } else {
                self.panGestureVelocity = 0;
                [UIView beginAnimations:nil context:NULL];
                [self setRootControllerOffset:0];
                [UIView commitAnimations];
            }
        } else if(self.menuState == MFSideMenuStateVisible) {
            BOOL hideMenu = (self.menuSide == MFSideMenuLocationLeft) ? (finalX < adjustedOrigin.x) : (finalX > adjustedOrigin.x);
            if(hideMenu) {
                self.panGestureVelocity = velocity.x;
                [self setMenuState:MFSideMenuStateHidden];
            } else {
                self.panGestureVelocity = 0;
                [UIView beginAnimations:nil context:NULL];
                [self setRootControllerOffset:adjustedOrigin.x];
                [UIView commitAnimations];
            }
        }
	}
}

- (void) navigationControllerTapped:(id)sender {
    if(self.menuState != MFSideMenuStateHidden) {
        [self setMenuState:MFSideMenuStateHidden];
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
#pragma mark - UIGestureRecognizer Helpers

- (CGPoint) pointAdjustedForInterfaceOrientation:(CGPoint)point {
    switch (self.rootViewController.interfaceOrientation)
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
    if(UIInterfaceOrientationIsPortrait(self.rootViewController.interfaceOrientation)) {
        return view.frame.size.width;
    } else {
        return view.frame.size.height;
    }
}


#pragma mark -
#pragma mark - Menu Rotation

- (void) orientSideMenuFromStatusBar {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
    CGSize windowSize = self.navigationController.view.window.bounds.size;
    CGFloat angle = 0.0;
    
    CGFloat portraitPadding = (windowSize.width - kMFSideMenuSidebarWidth);
    CGFloat portraitLeft, portraitRight;
    CGFloat landscapePadding = (windowSize.height - kMFSideMenuSidebarWidth);
    CGFloat landscapeTop, landscapeBottom;
    
    // we clear these here so that we don't create any unsatisfiable constraints below
    [self.topConstraint setConstant:0.0];
    [self.rightConstraint setConstant:0.0];
    [self.bottomConstraint setConstant:0.0];
    [self.leftConstraint setConstant:0.0];
    
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            angle = 0.0;
            
            portraitLeft = (self.menuSide == MFSideMenuLocationLeft) ? 0.0 : portraitPadding;
            portraitRight = (self.menuSide == MFSideMenuLocationLeft) ? -1*portraitPadding : 0.0;
            
            [self.topConstraint setConstant:statusBarSize.height];
            [self.rightConstraint setConstant:portraitRight];
            [self.leftConstraint setConstant:portraitLeft];
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            angle = M_PI;
            
            portraitLeft = (self.menuSide == MFSideMenuLocationLeft) ? portraitPadding : 0.0;
            portraitRight = (self.menuSide == MFSideMenuLocationLeft) ? 0.0 : -1*portraitPadding;
            
            [self.rightConstraint setConstant:portraitRight];
            [self.bottomConstraint setConstant:-1*statusBarSize.height];
            [self.leftConstraint setConstant:portraitLeft];
            break;
        case UIInterfaceOrientationLandscapeLeft:
            angle = - M_PI / 2.0f;
            
            landscapeTop = (self.menuSide == MFSideMenuLocationLeft) ? landscapePadding : 0.0;
            landscapeBottom = (self.menuSide == MFSideMenuLocationLeft) ? 0.0 : -1*landscapePadding;
            
            [self.topConstraint setConstant:landscapeTop];
            [self.bottomConstraint setConstant:landscapeBottom];
            [self.leftConstraint setConstant:statusBarSize.width];
            break;
        case UIInterfaceOrientationLandscapeRight:
            angle = M_PI / 2.0f;
            
            landscapeTop = (self.menuSide == MFSideMenuLocationLeft) ? 0.0 : landscapePadding;
            landscapeBottom = (self.menuSide == MFSideMenuLocationLeft) ? -1*landscapePadding : 0.0;
            
            [self.topConstraint setConstant:landscapeTop];
            [self.rightConstraint setConstant:-1*statusBarSize.width];
            [self.bottomConstraint setConstant:landscapeBottom];
            break;
    }
    
    CGAffineTransform transform = CGAffineTransformMakeRotation(angle);
    self.sideMenuController.view.transform = transform;
}

- (void)statusBarOrientationDidChange:(NSNotification *)notification {
    [self orientSideMenuFromStatusBar];
    
    if(self.menuState == MFSideMenuStateVisible) {
        [self setMenuState:MFSideMenuStateHidden];
    }
}


#pragma mark -
#pragma mark - Menu State & Open/Close Animation

- (void)setMenuState:(MFSideMenuState)menuState {
    MFSideMenuState currentState = _menuState;
    _menuState = menuState;
    
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

// menu open/close animation
- (void) toggleSideMenuHidden:(BOOL)hidden {
    // notify that the menu state event is starting
    [self sendMenuStateEventNotification:(hidden ? MFSideMenuStateEventMenuWillClose : MFSideMenuStateEventMenuWillOpen)];
    
    CGFloat x = ABS([self pointAdjustedForInterfaceOrientation:self.rootViewController.view.frame.origin].x);
    
    CGFloat navigationControllerXPosition = (self.menuSide == MFSideMenuLocationLeft) ? kMFSideMenuSidebarWidth : -1*kMFSideMenuSidebarWidth;
    CGFloat animationPositionDelta = (hidden) ? x : (navigationControllerXPosition  - x);
    
    CGFloat duration;
    
    if(ABS(self.panGestureVelocity) > 1.0) {
        // try to continue the animation at the speed the user was swiping
        duration = animationPositionDelta / ABS(self.panGestureVelocity);
    } else {
        // no swipe was used, user tapped the bar button item
        CGFloat animationDurationPerPixel = kMFSideMenuAnimationDuration / navigationControllerXPosition;
        duration = animationDurationPerPixel * animationPositionDelta;
    }
    
    if(duration > kMFSideMenuAnimationMaxDuration) duration = kMFSideMenuAnimationMaxDuration;
    
    [UIView animateWithDuration:duration animations:^{
        CGFloat xPosition = (hidden) ? 0 : navigationControllerXPosition;
        [self setRootControllerOffset:xPosition];
    } completion:^(BOOL finished) {
        [self setupSideMenuBarButtonItem];
        
        // disable user interaction on the current view controller if the menu is visible
        self.navigationController.topViewController.view.userInteractionEnabled = (self.menuState == MFSideMenuStateHidden);
        
        // notify that the menu state event is done
        [self sendMenuStateEventNotification:(hidden ? MFSideMenuStateEventMenuDidClose : MFSideMenuStateEventMenuDidOpen)];
    }];
}

- (void) sendMenuStateEventNotification:(MFSideMenuStateEvent)event {
    //[[NSNotificationCenter defaultCenter] postNotificationName:MFSideMenuStateEventDidOccurNotification
    //                                                    object:[NSNumber numberWithInt:event]];
    if(self.menuStateEventBlock) self.menuStateEventBlock(event);
}

#pragma mark -
#pragma mark - Root Controller

- (UIViewController *) rootViewController {
    return self.navigationController.view.window.rootViewController;
}

- (void) setRootControllerOffset:(CGFloat)xOffset {
    UIViewController *rootController = self.rootViewController;
    CGRect frame = rootController.view.frame;
    frame.origin = CGPointZero;
    
    // need to account for the controller's transform
    switch (rootController.interfaceOrientation)
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
    
    rootController.view.frame = frame;
}

// draw a shadow between the navigation controller and the menu
- (void) drawRootControllerShadowPath {
    CGRect pathRect = self.rootViewController.view.bounds;
    if(self.menuSide == MFSideMenuLocationRight) {
        // draw the shadow on the right hand side of the navigationController
        pathRect.origin.x = pathRect.size.width - kMFSideMenuShadowWidth;
    }
    pathRect.size.width = kMFSideMenuShadowWidth;
    
    self.rootViewController.view.layer.shadowPath = [UIBezierPath bezierPathWithRect:pathRect].CGPath;
}

@end
