//
//  MFSideMenuContainerViewController.m
//  MFSideMenuDemoSplitViewController
//
//  Created by Michael Frederick on 4/2/13.
//  Copyright (c) 2013 Frederick Development. All rights reserved.
//

#import "MFSideMenuContainerViewController.h"
#import <QuartzCore/QuartzCore.h>

typedef enum {
    MFSideMenuPanDirectionNone,
    MFSideMenuPanDirectionLeft,
    MFSideMenuPanDirectionRight
} MFSideMenuPanDirection;



@interface MFSideMenuContainerViewController ()
@property (nonatomic, strong) UIViewController *leftSideMenuViewController;
@property (nonatomic, strong) UIViewController *centerViewController;
@property (nonatomic, strong) UIViewController *rightSideMenuViewController;
@property (nonatomic, strong) UIView *menuContainerView;

@property (nonatomic, assign) CGPoint panGestureOrigin;
@property (nonatomic, assign) CGFloat panGestureVelocity;
@property (nonatomic, assign) MFSideMenuPanDirection panDirection;
@end

@implementation MFSideMenuContainerViewController

@synthesize leftSideMenuViewController = _leftSideMenuViewController;
@synthesize centerViewController = _centerViewController;
@synthesize rightSideMenuViewController = _rightSideMenuViewController;
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
@synthesize menuAnimationDefaultDuration;
@synthesize menuAnimationMaxDuration;


+ (MFSideMenuContainerViewController *)controllerWithLeftSideMenuViewController:(id)leftSideMenuViewController
                                                           centerViewController:(id)centerViewController
                                                    rightSideMenuViewController:(id)rightSideMenuViewController {
    MFSideMenuContainerViewController *controller = [MFSideMenuContainerViewController new];
    controller.leftSideMenuViewController = leftSideMenuViewController;
    controller.centerViewController = centerViewController;
    controller.rightSideMenuViewController = rightSideMenuViewController;
    return controller;
}

- (id) init {
    self = [super init];
    if(self) {
        CGRect applicationFrame = [[UIApplication sharedApplication].delegate window].screen.applicationFrame;
        CGRect menuContainerFrame = (CGRect){CGPointZero, applicationFrame.size};
        self.menuContainerView = [[UIView alloc] initWithFrame:menuContainerFrame];
        self.menuContainerView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        self.menuState = MFSideMenuStateClosed;
        self.menuWidth = 270.0f;
        self.shadowRadius = 10.0f;
        self.shadowOpacity = 0.75f;
        self.shadowColor = [UIColor blackColor];
        self.menuSlideFactor = 3.0f;
        self.shadowEnabled = YES;
        self.menuAnimationDefaultDuration = 0.2f;
        self.menuAnimationMaxDuration = 0.4f;
        self.panMode = MFSideMenuPanModeDefault;
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self addGestureRecognizers];
    [self.view insertSubview:menuContainerView atIndex:0];
    
    [self setLeftSideMenuFrameToClosedPosition];
    [self setRightSideMenuFrameToClosedPosition];
    
    [self drawMenuShadows];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if(self.menuContainerView && self.menuContainerView.superview) {
        [self.menuContainerView removeFromSuperview];
    }
}


#pragma mark -
#pragma mark - UIViewController Rotation

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    self.centerViewController.view.layer.shadowPath = nil;
    self.centerViewController.view.layer.shouldRasterize = YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    [self drawRootControllerShadowPath];
    self.centerViewController.view.layer.shouldRasterize = NO;
}


#pragma mark -
#pragma mark - UIViewController Containment

- (void)setLeftSideMenuViewController:(UIViewController *)leftSideMenuViewController {
    _leftSideMenuViewController = leftSideMenuViewController;
    if(!_leftSideMenuViewController) return;
    
    [self addChildViewController:_leftSideMenuViewController];
    [self.menuContainerView insertSubview:_leftSideMenuViewController.view atIndex:0];
    [_leftSideMenuViewController didMoveToParentViewController:self];
    
    [self setLeftSideMenuFrameToClosedPosition];
}

- (void)setCenterViewController:(UIViewController *)centerViewController {
    _centerViewController = centerViewController;
    if(!_centerViewController) return;
    
    [self addChildViewController:_centerViewController];
    [self.view addSubview:_centerViewController.view];
    [_centerViewController didMoveToParentViewController:self];
}

- (void)setRightSideMenuViewController:(UIViewController *)rightSideMenuViewController {
    _rightSideMenuViewController = rightSideMenuViewController;
    if(!_rightSideMenuViewController) return;
    
    [self addChildViewController:_rightSideMenuViewController];
    [self.menuContainerView insertSubview:_rightSideMenuViewController.view atIndex:0];
    [_rightSideMenuViewController didMoveToParentViewController:self];
    
    [self setRightSideMenuFrameToClosedPosition];
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
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc]
                                             initWithTarget:self
                                             action:@selector(navigationControllerTapped:)];
    [tapRecognizer setDelegate:self];
    [self.centerViewController.view addGestureRecognizer:tapRecognizer];
    
    [self.centerViewController.view addGestureRecognizer:[self panGestureRecognizer]];
    [menuContainerView addGestureRecognizer:[self panGestureRecognizer]];
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
    
    CGFloat navigationControllerXPosition = ABS(self.centerViewController.view.frame.origin.x);
    CGFloat duration = [self animationDurationFromStartPosition:navigationControllerXPosition toEndPosition:self.menuWidth];
    
    [UIView animateWithDuration:duration animations:^{
        [self setCenterControllerOffset:(leftSideMenu ? self.menuWidth : -1*self.menuWidth)];
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
    
    CGFloat navigationControllerXPosition = ABS(self.centerViewController.view.frame.origin.x);
    CGFloat duration = [self animationDurationFromStartPosition:navigationControllerXPosition toEndPosition:0];
    [UIView animateWithDuration:duration animations:^{
        [self setCenterControllerOffset:0];
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
    rightFrame.origin.x = self.centerViewController.view.frame.size.width - self.menuWidth;
    if(self.menuSlideAnimationEnabled) rightFrame.origin.x += self.menuWidth / self.menuSlideFactor;
    self.rightSideMenuViewController.view.frame = rightFrame;
    self.rightSideMenuViewController.view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleHeight;
}

- (void)alignLeftMenuControllerWithCenterViewController {
    CGRect leftMenuFrame = self.leftSideMenuViewController.view.frame;
    leftMenuFrame.size.width = _menuWidth;
    CGFloat menuX = self.centerViewController.view.frame.origin.x - leftMenuFrame.size.width;
    leftMenuFrame.origin.x = menuX;
    self.leftSideMenuViewController.view.frame = leftMenuFrame;
}

- (void)alignRightMenuControllerWithCenterViewController {
    CGRect rightMenuFrame = self.rightSideMenuViewController.view.frame;
    rightMenuFrame.size.width = _menuWidth;
    CGFloat menuX = self.centerViewController.view.frame.size.width + self.centerViewController.view.frame.origin.x;
    rightMenuFrame.origin.x = menuX;
    self.rightSideMenuViewController.view.frame = rightMenuFrame;
}


#pragma mark -
#pragma mark - MFSideMenuOptions

- (void)setShadowEnabled:(BOOL)shadowEnabled {
    _shadowEnabled = shadowEnabled;
    
    if(_shadowEnabled) {
        [self drawMenuShadows];
    } else {
        self.centerViewController.view.layer.shadowOpacity = 0.0f;
        self.centerViewController.view.layer.shadowRadius = 0.0f;
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
            [self setCenterControllerOffset:_menuWidth];
            [self alignLeftMenuControllerWithCenterViewController];
            [self setRightSideMenuFrameToClosedPosition];
            break;
        case MFSideMenuStateRightMenuOpen:
            [self setCenterControllerOffset:-1*_menuWidth];
            [self alignRightMenuControllerWithCenterViewController];
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
        // we draw the shadow on the centerViewController, because it might not always be the uinavigationcontroller
        // i.e. it could be a uitabbarcontroller
        [self drawRootControllerShadowPath];
        self.centerViewController.view.layer.shadowOpacity = self.shadowOpacity;
        self.centerViewController.view.layer.shadowRadius = self.shadowRadius;
        self.centerViewController.view.layer.shadowColor = [self.shadowColor CGColor];
    }
}

// draw a shadow between the navigation controller and the menu
- (void) drawRootControllerShadowPath {
    if(_shadowEnabled) {
        CGRect pathRect = self.centerViewController.view.bounds;
        pathRect.size = self.centerViewController.view.frame.size;
        self.centerViewController.view.layer.shadowPath = [UIBezierPath bezierPathWithRect:pathRect].CGPath;
    }
}


#pragma mark -
#pragma mark - MFSideMenuPanMode

- (BOOL) centerViewControllerPanEnabled {
    return ((self.panMode & MFSideMenuPanModeRootViewController) == MFSideMenuPanModeRootViewController);
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
        if([gestureRecognizer.view isEqual:self.centerViewController.view] &&
           [self centerViewControllerPanEnabled]) return YES;
        
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
    UIView *view = self.centerViewController.view;
    
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
    
    UIView *view = self.centerViewController.view;
    
    CGPoint translatedPoint = [recognizer translationInView:view];
    CGPoint adjustedOrigin = panGestureOrigin;
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
    
    [self setCenterControllerOffset:translatedPoint.x];
    
    if(recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [recognizer velocityInView:view];
        CGFloat finalX = translatedPoint.x + (.35*velocity.x);
        CGFloat viewWidth = view.frame.size.width;
        
        if(self.menuState == MFSideMenuStateClosed) {
            BOOL showMenu = (finalX > viewWidth/2);
            if(showMenu) {
                self.panGestureVelocity = velocity.x;
                [self setMenuState:MFSideMenuStateLeftMenuOpen];
            } else {
                self.panGestureVelocity = 0;
                [UIView beginAnimations:nil context:NULL];
                [self setCenterControllerOffset:0];
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
                [self setCenterControllerOffset:adjustedOrigin.x];
                [UIView commitAnimations];
            }
        }
        
        self.panDirection = MFSideMenuPanDirectionNone;
	}
}

- (void) handleLeftPan:(UIPanGestureRecognizer *)recognizer {
    if(!self.rightSideMenuViewController && self.menuState == MFSideMenuStateClosed) return;
    
    UIView *view = self.centerViewController.view;
    
    CGPoint translatedPoint = [recognizer translationInView:view];
    CGPoint adjustedOrigin = panGestureOrigin;
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
    
    [self setCenterControllerOffset:translatedPoint.x];
    
	if(recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [recognizer velocityInView:view];
        CGFloat finalX = translatedPoint.x + (.35*velocity.x);
        CGFloat viewWidth = view.frame.size.width;
        
        if(self.menuState == MFSideMenuStateClosed) {
            BOOL showMenu = (finalX < -1*viewWidth/2);
            if(showMenu) {
                self.panGestureVelocity = velocity.x;
                [self setMenuState:MFSideMenuStateRightMenuOpen];
            } else {
                self.panGestureVelocity = 0;
                [UIView beginAnimations:nil context:NULL];
                [self setCenterControllerOffset:0];
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
                [self setCenterControllerOffset:adjustedOrigin.x];
                [UIView commitAnimations];
            }
        }
	}
}

- (void)navigationControllerTapped:(id)sender {
    if(self.menuState != MFSideMenuStateClosed) {
        [self setMenuState:MFSideMenuStateClosed];
    }
}


#pragma mark -
#pragma mark - Root Controller

- (void) setCenterControllerOffset:(CGFloat)xOffset {
    CGRect frame = self.centerViewController.view.frame;
    frame.origin.x = xOffset;
    self.centerViewController.view.frame = frame;
    
    if(!self.menuSlideAnimationEnabled) return;
    
    if(xOffset > 0){
        [self alignLeftMenuControllerWithCenterViewController];
        [self setRightSideMenuFrameToClosedPosition];
    } else if(xOffset < 0){
        [self alignRightMenuControllerWithCenterViewController];
        [self setLeftSideMenuFrameToClosedPosition];
    } else {
        [self setLeftSideMenuFrameToClosedPosition];
        [self setRightSideMenuFrameToClosedPosition];
    }
}

- (CGFloat)animationDurationFromStartPosition:(CGFloat)startPosition toEndPosition:(CGFloat)endPosition {
    CGFloat animationPositionDelta = ABS(endPosition - startPosition);
    
    CGFloat duration;
    if(ABS(self.panGestureVelocity) > 1.0) {
        // try to continue the animation at the speed the user was swiping
        duration = animationPositionDelta / ABS(self.panGestureVelocity);
    } else {
        // no swipe was used, user tapped the bar button item
        CGFloat animationDurationPerPixel = self.menuAnimationDefaultDuration / endPosition;
        duration = animationDurationPerPixel * animationPositionDelta;
    }
    
    return MIN(duration, self.menuAnimationMaxDuration);
}


@end
