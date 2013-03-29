//
//  MFSideMenu.m
//
//  Created by Michael Frederick on 10/22/12.
//

#import "MFSideMenu.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

typedef enum {
    MFSideMenuPanDirectionNone,
    MFSideMenuPanDirectionLeft,
    MFSideMenuPanDirectionRight
} MFSideMenuPanDirection;


@interface MFSideMenu()
@property (nonatomic, assign, readwrite) UINavigationController *navigationController;
@property (nonatomic, strong) UIViewController *leftSideMenuViewController;
@property (nonatomic, strong) UIViewController *rightSideMenuViewController;
@property (nonatomic, strong) UIView *menuContainerView;

@property (nonatomic, assign) CGPoint panGestureOrigin;
@property (nonatomic, assign) CGFloat panGestureVelocity;
@property (nonatomic, assign) MFSideMenuPanDirection panDirection;
@end


@implementation MFSideMenu

@synthesize navigationController;
@synthesize leftSideMenuViewController;
@synthesize rightSideMenuViewController;
@synthesize menuContainerView;
@synthesize panMode;
@synthesize panGestureOrigin;
@synthesize panGestureVelocity;
@synthesize menuState = _menuState;
@synthesize menuStateEventBlock;
@synthesize panDirection;
@synthesize shadowEnabled = _shadowEnabled;
@synthesize menuWidth = _menuWidth;
@synthesize shadowRadius = _shadowRadius;
@synthesize shadowColor = _shadowColor;
@synthesize shadowOpacity = _shadowOpacity;
@synthesize menuSlideAnimationEnabled;
@synthesize menuSlideFactor;


#pragma mark -
#pragma mark - Menu Creation

- (id) init {
    self = [super init];
    if(self) {
        _shadowEnabled = YES;
        
        CGRect applicationFrame = [[UIApplication sharedApplication].delegate window].screen.applicationFrame;
        self.menuContainerView = [[UIView alloc] initWithFrame:applicationFrame];
        self.menuState = MFSideMenuStateClosed;
        self.menuWidth = 270.0f;
        self.shadowRadius = 10.0f;
        self.shadowOpacity = 0.75f;
        self.shadowColor = [UIColor blackColor];
        self.menuSlideFactor = 3.0f;
        
        [UINavigationController swizzleViewMethods];
    }
    return self;
}

+ (MFSideMenu *)menuWithNavigationController:(UINavigationController *)controller
                      leftSideMenuController:(id)leftMenuController
                     rightSideMenuController:(id)rightMenuController {
    MFSideMenuPanMode panMode = MFSideMenuPanModeNavigationBar|MFSideMenuPanModeNavigationController|MFSideMenuPanModeSideMenu;
    return [MFSideMenu menuWithNavigationController:controller
                             leftSideMenuController:leftMenuController
                            rightSideMenuController:rightMenuController
                                            panMode:panMode];
}

+ (MFSideMenu *) menuWithNavigationController:(UINavigationController *)controller
                           leftSideMenuController:(id)leftMenuController
                      rightSideMenuController:(id)rightMenuController
                                      panMode:(MFSideMenuPanMode)panMode {
    MFSideMenu *menu = [[MFSideMenu alloc] init];
    menu.navigationController = controller;
    menu.leftSideMenuViewController = leftMenuController;
    menu.rightSideMenuViewController = rightMenuController;
    menu.panMode = panMode;
    controller.sideMenu = menu;

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

- (void)setupMenuContainerView {
    if(menuContainerView.superview) return;
    
    if(self.leftSideMenuViewController) [menuContainerView insertSubview:self.leftSideMenuViewController.view atIndex:0];
    if(self.rightSideMenuViewController) [menuContainerView insertSubview:self.rightSideMenuViewController.view atIndex:0];
    
    UIView *windowRootView = self.rootViewController.view;
    UIView *containerView = windowRootView.superview;
    
    [containerView insertSubview:menuContainerView belowSubview:windowRootView];
    
    // we need to reorient from the status bar here incase the initial orientation is landscape
    [self orientSideMenuFromStatusBar];
    
    if(self.shadowEnabled) [self drawMenuShadows];
    
    [self setLeftSideMenuFrameToClosedPosition];
    [self setRightSideMenuFrameToClosedPosition];
}


#pragma mark -
#pragma mark - Navigation Controller View Lifecycle

- (void) navigationControllerDidAppear {
    [self setupMenuContainerView];
    [self addGestureRecognizers];
}

- (void) navigationControllerDidDisappear {
    // we don't want the menu to be visible if the navigation controller is gone
    if(self.menuContainerView && self.menuContainerView.superview) {
        [self.menuContainerView removeFromSuperview];
    }
}


#pragma mark -
#pragma mark - MFSideMenuOptions

- (void)setShadowEnabled:(BOOL)shadowEnabled {
    _shadowEnabled = shadowEnabled;
    
    if(_shadowEnabled) {
        [self drawMenuShadows];
    } else {
        self.rootViewController.view.layer.shadowOpacity = 0.0f;
        self.rootViewController.view.layer.shadowRadius = 0.0f;
    }
}

- (void)setMenuWidth:(CGFloat)menuWidth {
    [self setMenuWidth:menuWidth animated:YES];
}

- (void)setMenuWidth:(CGFloat)menuWidth animated:(BOOL)animated {
    if(animated) [UIView beginAnimations:nil context:NULL];
    
    _menuWidth = menuWidth;
    
    switch (self.menuState) {
        case MFSideMenuStateClosed:
            [self setLeftSideMenuFrameToClosedPosition];
            [self setRightSideMenuFrameToClosedPosition];
            break;
        case MFSideMenuStateLeftMenuOpen:
            [self setRootControllerOffset:_menuWidth];
            [self alignLeftMenuControllerWithRootViewController];
            [self setRightSideMenuFrameToClosedPosition];
            break;
        case MFSideMenuStateRightMenuOpen:
            [self setRootControllerOffset:-1*_menuWidth];
            [self alignRightMenuControllerWithRootViewController];
            [self setLeftSideMenuFrameToClosedPosition];
            break;
    }
    
    if(animated) [UIView commitAnimations];
}

- (void)setShadowRadius:(CGFloat)shadowRadius {
    _shadowRadius = shadowRadius;
    [self drawMenuShadows];
}

- (void)setShadowColor:(UIColor *)shadowColor {
    _shadowColor = shadowColor;
    [self drawMenuShadows];
}

- (void)setShadowOpacity:(CGFloat)shadowOpacity {
    _shadowOpacity = shadowOpacity;
    [self drawMenuShadows];
}

- (void) drawMenuShadows {
    if(_shadowEnabled) {
        // we draw the shadow on the rootViewController, because it might not always be the uinavigationcontroller
        // i.e. it could be a uitabbarcontroller
        [self drawRootControllerShadowPath];
        self.rootViewController.view.layer.shadowOpacity = self.shadowOpacity;
        self.rootViewController.view.layer.shadowRadius = self.shadowRadius;
        self.rootViewController.view.layer.shadowColor = [self.shadowColor CGColor];
    }
}

// draw a shadow between the navigation controller and the menu
- (void) drawRootControllerShadowPath {
    if(_shadowEnabled) {
        CGRect pathRect = self.rootViewController.view.bounds;
        pathRect.size = [self sizeAdjustedForInterfaceOrientation:self.rootViewController.view];
        self.rootViewController.view.layer.shadowPath = [UIBezierPath bezierPathWithRect:pathRect].CGPath;
    }
}


#pragma mark -
#pragma mark - MFSideMenuPanMode

- (BOOL) navigationControllerPanEnabled {
    return ((self.panMode & MFSideMenuPanModeNavigationController) == MFSideMenuPanModeNavigationController);
}

- (BOOL) navigationBarPanEnabled {
    return ((self.panMode & MFSideMenuPanModeNavigationBar) == MFSideMenuPanModeNavigationBar);
}

- (BOOL) sideMenuPanEnabled {
    return ((self.panMode & MFSideMenuPanModeSideMenu) == MFSideMenuPanModeSideMenu);
}


#pragma mark - 
#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] &&
       self.menuState != MFSideMenuStateClosed) return YES;
    
    if([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        if([gestureRecognizer.view isEqual:self.navigationController.view] &&
           [self navigationControllerPanEnabled]) return YES;
        
        if([gestureRecognizer.view isEqual:self.navigationController.navigationBar] &&
           self.menuState == MFSideMenuStateClosed &&
           [self navigationBarPanEnabled]) return YES;
        
        if([gestureRecognizer.view isEqual:self.menuContainerView] &&
           [self sideMenuPanEnabled]) return YES;
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

// this method handles any pan event
// and sets the navigation controller's frame as needed
- (void) handlePan:(UIPanGestureRecognizer *)recognizer {
    UIView *view = self.rootViewController.view;
    
	if(recognizer.state == UIGestureRecognizerStateBegan) {
        // remember where the pan started
        panGestureOrigin = view.frame.origin;
        self.panDirection = MFSideMenuPanDirectionNone;
	}
    
    if(self.panDirection == MFSideMenuPanDirectionNone) {
        CGPoint translatedPoint = [recognizer translationInView:view];
        if(translatedPoint.x > 0) {
            self.panDirection = MFSideMenuPanDirectionRight;
            if(self.leftSideMenuViewController && self.menuState == MFSideMenuStateClosed) {
                [self.menuContainerView bringSubviewToFront:self.leftSideMenuViewController.view];
            }
        }
        else if(translatedPoint.x < 0) {
            self.panDirection = MFSideMenuPanDirectionLeft;
            if(self.rightSideMenuViewController && self.menuState == MFSideMenuStateClosed) {
                [self.menuContainerView bringSubviewToFront:self.rightSideMenuViewController.view];
            }
        }
    }
    
    if((self.menuState == MFSideMenuStateRightMenuOpen && self.panDirection == MFSideMenuPanDirectionLeft)
       || (self.menuState == MFSideMenuStateLeftMenuOpen && self.panDirection == MFSideMenuPanDirectionRight)) {
        self.panDirection = MFSideMenuPanDirectionNone;
        return;
    }
    
    if(self.panDirection == MFSideMenuPanDirectionLeft) {
        [self handleLeftPan:recognizer];
    } else if(self.panDirection == MFSideMenuPanDirectionRight) {
        [self handleRightPan:recognizer];
    }
}

- (void) handleRightPan:(UIPanGestureRecognizer *)recognizer {
    if(!self.leftSideMenuViewController && self.menuState == MFSideMenuStateClosed) return;
    
    UIView *view = self.rootViewController.view;
    
    CGPoint translatedPoint = [recognizer translationInView:view];
    CGPoint adjustedOrigin = [self pointAdjustedForInterfaceOrientation:panGestureOrigin];
    translatedPoint = CGPointMake(adjustedOrigin.x + translatedPoint.x,
                                  adjustedOrigin.y + translatedPoint.y);
    
    translatedPoint.x = MAX(translatedPoint.x, -1*self.menuWidth);
    translatedPoint.x = MIN(translatedPoint.x, self.menuWidth);
    if(self.menuState == MFSideMenuStateRightMenuOpen) {
        // menu is already open, the most the user can do is close it in this gesture
        translatedPoint.x = MIN(translatedPoint.x, 0);
    } else {
        // we are opening the menu
        translatedPoint.x = MAX(translatedPoint.x, 0);
    }
    
    [self setRootControllerOffset:translatedPoint.x];
    
    if(recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [recognizer velocityInView:view];
        CGFloat finalX = translatedPoint.x + (.35*velocity.x);
        CGFloat viewWidth = [self widthAdjustedForInterfaceOrientation:view];
        
        if(self.menuState == MFSideMenuStateClosed) {
            BOOL showMenu = (finalX > viewWidth/2);
            if(showMenu) {
                self.panGestureVelocity = velocity.x;
                [self setMenuState:MFSideMenuStateLeftMenuOpen];
            } else {
                self.panGestureVelocity = 0;
                [UIView beginAnimations:nil context:NULL];
                [self setRootControllerOffset:0];
                [UIView commitAnimations];
            }
        } else {
            BOOL hideMenu = (finalX > adjustedOrigin.x);
            if(hideMenu) {
                self.panGestureVelocity = velocity.x;
                [self setMenuState:MFSideMenuStateClosed];
            } else {
                self.panGestureVelocity = 0;
                [UIView beginAnimations:nil context:NULL];
                [self setRootControllerOffset:adjustedOrigin.x];
                [UIView commitAnimations];
            }
        }
        
        self.panDirection = MFSideMenuPanDirectionNone;
	}
}

- (void) handleLeftPan:(UIPanGestureRecognizer *)recognizer {
    if(!self.rightSideMenuViewController && self.menuState == MFSideMenuStateClosed) return;
    
    UIView *view = self.rootViewController.view;
    
    CGPoint translatedPoint = [recognizer translationInView:view];
    CGPoint adjustedOrigin = [self pointAdjustedForInterfaceOrientation:panGestureOrigin];
    translatedPoint = CGPointMake(adjustedOrigin.x + translatedPoint.x,
                                  adjustedOrigin.y + translatedPoint.y);
    
    translatedPoint.x = MAX(translatedPoint.x, -1*self.menuWidth);
    translatedPoint.x = MIN(translatedPoint.x, self.menuWidth);
    if(self.menuState == MFSideMenuStateLeftMenuOpen) {
        // don't let the pan go less than 0 if the menu is already open
        translatedPoint.x = MAX(translatedPoint.x, 0);
    } else {
        // we are opening the menu
        translatedPoint.x = MIN(translatedPoint.x, 0);
    }
    
    [self setRootControllerOffset:translatedPoint.x];
    
	if(recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [recognizer velocityInView:view];
        CGFloat finalX = translatedPoint.x + (.35*velocity.x);
        CGFloat viewWidth = [self widthAdjustedForInterfaceOrientation:view];
        
        if(self.menuState == MFSideMenuStateClosed) {
            BOOL showMenu = (finalX < -1*viewWidth/2);
            if(showMenu) {
                self.panGestureVelocity = velocity.x;
                [self setMenuState:MFSideMenuStateRightMenuOpen];
            } else {
                self.panGestureVelocity = 0;
                [UIView beginAnimations:nil context:NULL];
                [self setRootControllerOffset:0];
                [UIView commitAnimations];
            }
        } else {
            BOOL hideMenu = (finalX < adjustedOrigin.x);
            if(hideMenu) {
                self.panGestureVelocity = velocity.x;
                [self setMenuState:MFSideMenuStateClosed];
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
    if(self.menuState != MFSideMenuStateClosed) {
        [self setMenuState:MFSideMenuStateClosed];
    }
}


#pragma mark -
#pragma mark - UIGestureRecognizer Helpers

- (UIPanGestureRecognizer *)panGestureRecognizer {
    UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handlePan:)];
	[recognizer setMaximumNumberOfTouches:1];
    [recognizer setDelegate:self];
    return recognizer;
}

- (void)addGestureRecognizers {
    [self.navigationController.navigationBar addGestureRecognizer:[self panGestureRecognizer]];
    [self.navigationController.view addGestureRecognizer:[self panGestureRecognizer]];
    [menuContainerView addGestureRecognizer:[self panGestureRecognizer]];
}

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

- (CGSize) sizeAdjustedForInterfaceOrientation:(UIView *)view {
    if(UIInterfaceOrientationIsPortrait(self.rootViewController.interfaceOrientation)) {
        return CGSizeMake(view.frame.size.width, view.frame.size.height);
    } else {
        return CGSizeMake(view.frame.size.height, view.frame.size.width);
    }
}


#pragma mark -
#pragma mark - Menu Rotation

- (void) orientSideMenuFromStatusBar {
    CGRect newFrame = self.rootViewController.view.window.screen.applicationFrame;
    self.menuContainerView.transform = self.navigationController.view.transform;
    self.menuContainerView.frame = newFrame;
}

- (void)statusBarOrientationDidChange:(NSNotification *)notification {
    [self orientSideMenuFromStatusBar];
    
    if(self.menuState != MFSideMenuStateClosed) {
        [self setMenuState:MFSideMenuStateClosed];
    }
    
    [self drawRootControllerShadowPath];
}


#pragma mark -
#pragma mark - Menu State & Open/Close Animation

- (void)toggleLeftSideMenu {
    if(self.menuState == MFSideMenuStateLeftMenuOpen) {
        [self setMenuState:MFSideMenuStateClosed];
    } else {
        [self setMenuState:MFSideMenuStateLeftMenuOpen];
    }
}

- (void) toggleRightSideMenu {
    if(self.menuState == MFSideMenuStateRightMenuOpen) {
        [self setMenuState:MFSideMenuStateClosed];
    } else {
        [self setMenuState:MFSideMenuStateRightMenuOpen];
    }
}

- (void)setMenuState:(MFSideMenuState)menuState {
    switch (menuState) {
        case MFSideMenuStateClosed:
            [self closeSideMenu];
            break;
        case MFSideMenuStateLeftMenuOpen:
            if(!self.leftSideMenuViewController) return;
            [self openLeftSideMenu];
            break;
        case MFSideMenuStateRightMenuOpen:
            if(!self.rightSideMenuViewController) return;
            [self openRightSideMenu];
            break;
        default:
            break;
    }
    
    if (self.navigationController.isViewLoaded && [self.navigationController.view respondsToSelector:@selector(accessibilityViewIsModal)]) {
        self.navigationController.view.accessibilityViewIsModal = menuState == MFSideMenuStateClosed;
    }
    
    _menuState = menuState;
}

- (void)openLeftSideMenu {
    [self.menuContainerView bringSubviewToFront:self.leftSideMenuViewController.view];
    [self openSideMenu:YES];
}

- (void)openRightSideMenu {
    [self.menuContainerView bringSubviewToFront:self.rightSideMenuViewController.view];
    [self openSideMenu:NO];
}

- (void)openSideMenu:(BOOL)leftSideMenu {
    // notify that the menu state event is starting
    [self sendMenuStateEventNotification:MFSideMenuStateEventMenuWillOpen];
    
    CGFloat navigationControllerXPosition = ABS([self pointAdjustedForInterfaceOrientation:self.rootViewController.view.frame.origin].x);
    CGFloat duration = [self animationDurationFromStartPosition:navigationControllerXPosition toEndPosition:self.menuWidth];
    
    [UIView animateWithDuration:duration animations:^{
        [self setRootControllerOffset:(leftSideMenu ? self.menuWidth : -1*self.menuWidth)];
    } completion:^(BOOL finished) {
        // disable user interaction on the current stack of view controllers if the menu is visible
        for(UIViewController* viewController in self.navigationController.viewControllers) {
            viewController.view.userInteractionEnabled = (self.menuState == MFSideMenuStateClosed);
        }
        
        // notify that the menu state event is done
        [self sendMenuStateEventNotification:MFSideMenuStateEventMenuDidOpen];
    }];
}

- (void)closeSideMenu {
    // notify that the menu state event is starting
    [self sendMenuStateEventNotification:MFSideMenuStateEventMenuWillClose];
    
    CGFloat navigationControllerXPosition = ABS([self pointAdjustedForInterfaceOrientation:self.rootViewController.view.frame.origin].x);
    CGFloat duration = [self animationDurationFromStartPosition:navigationControllerXPosition toEndPosition:0];
    [UIView animateWithDuration:duration animations:^{
        CGFloat xPosition = 0;
        [self setRootControllerOffset:xPosition];
    } completion:^(BOOL finished) {
        // disable user interaction on the current stack of view controllers if the menu is visible
        for(UIViewController* viewController in self.navigationController.viewControllers) {
            viewController.view.userInteractionEnabled = (self.menuState == MFSideMenuStateClosed);
        }
        
        // notify that the menu state event is done
        [self sendMenuStateEventNotification:MFSideMenuStateEventMenuDidClose];
    }];
}

- (void) sendMenuStateEventNotification:(MFSideMenuStateEvent)event {
    if(self.menuStateEventBlock) self.menuStateEventBlock(event);
}

- (CGFloat)animationDurationFromStartPosition:(CGFloat)startPosition toEndPosition:(CGFloat)endPosition {
    CGFloat animationPositionDelta = ABS(endPosition - startPosition);
    
    CGFloat duration;
    if(ABS(self.panGestureVelocity) > 1.0) {
        // try to continue the animation at the speed the user was swiping
        duration = animationPositionDelta / ABS(self.panGestureVelocity);
    } else {
        // no swipe was used, user tapped the bar button item
        CGFloat animationDurationPerPixel = kMFSideMenuAnimationDuration / endPosition;
        duration = animationDurationPerPixel * animationPositionDelta;
    }
    
    return MIN(duration, kMFSideMenuAnimationMaxDuration);
}


#pragma mark -
#pragma mark - Side Menu Positioning

- (void) setLeftSideMenuFrameToClosedPosition {
    if(!self.leftSideMenuViewController) return;
    CGRect leftFrame = self.leftSideMenuViewController.view.frame;
    leftFrame.size.width = self.menuWidth;
    leftFrame.origin.x = (self.menuSlideAnimationEnabled) ? -1*leftFrame.size.width / self.menuSlideFactor : 0;
    leftFrame.origin.y = 0;
    self.leftSideMenuViewController.view.frame = leftFrame;
    self.leftSideMenuViewController.view.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleHeight;
}

- (void) setRightSideMenuFrameToClosedPosition {
    if(!self.rightSideMenuViewController) return;
    CGRect rightFrame = self.rightSideMenuViewController.view.frame;
    rightFrame.size.width = self.menuWidth;
    rightFrame.origin.y = 0;
    rightFrame.origin.x = [self widthAdjustedForInterfaceOrientation:self.rootViewController.view] - self.menuWidth;
    if(self.menuSlideAnimationEnabled) rightFrame.origin.x += self.menuWidth / self.menuSlideFactor;
    self.rightSideMenuViewController.view.frame = rightFrame;
    self.rightSideMenuViewController.view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleHeight;
}

- (void)alignLeftMenuControllerWithRootViewController {
    CGRect leftMenuFrame = self.leftSideMenuViewController.view.frame;
    leftMenuFrame.size.width = _menuWidth;
    CGFloat menuX = [self pointAdjustedForInterfaceOrientation:self.rootViewController.view.frame.origin].x -
    leftMenuFrame.size.width;
    leftMenuFrame.origin.x = menuX;
    self.leftSideMenuViewController.view.frame = leftMenuFrame;
}

- (void)alignRightMenuControllerWithRootViewController {
    CGRect rightMenuFrame = self.rightSideMenuViewController.view.frame;
    rightMenuFrame.size.width = _menuWidth;
    CGFloat menuX = [self widthAdjustedForInterfaceOrientation:self.rootViewController.view] +
    [self pointAdjustedForInterfaceOrientation:self.rootViewController.view.frame.origin].x;
    rightMenuFrame.origin.x = menuX;
    self.rightSideMenuViewController.view.frame = rightMenuFrame;
}


#pragma mark -
#pragma mark - Root Controller

- (UIViewController *) rootViewController {
    return self.navigationController.view.window.rootViewController;
}

- (void) setRootControllerOffset:(CGFloat)xOffset {
    UIViewController *rootController = self.rootViewController;
    CGRect frame = rootController.view.frame;
    frame.origin = CGPointMake(xOffset*rootController.view.transform.a, xOffset*rootController.view.transform.b);
    rootController.view.frame = frame;
    
    if(!self.menuSlideAnimationEnabled) return;
    
    if(xOffset > 0){
        [self alignLeftMenuControllerWithRootViewController];
        [self setRightSideMenuFrameToClosedPosition];
    } else if(xOffset < 0){
        [self alignRightMenuControllerWithRootViewController];
        [self setLeftSideMenuFrameToClosedPosition];
    } else {
        [self setLeftSideMenuFrameToClosedPosition];
        [self setRightSideMenuFrameToClosedPosition];
    }
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
