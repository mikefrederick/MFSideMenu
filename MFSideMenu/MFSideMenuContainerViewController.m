//
//  MFSideMenuContainerViewController.m
//  MFSideMenuDemoSplitViewController
//
//  Created by Michael Frederick on 4/2/13.
//  Copyright (c) 2013 Frederick Development. All rights reserved.
//

#import "MFSideMenuContainerViewController.h"
#import <QuartzCore/QuartzCore.h>

NSString * const MFSideMenuStateNotificationEvent = @"MFSideMenuStateNotificationEvent";

typedef enum {
    MFSideMenuPanDirectionNone,
    MFSideMenuPanDirectionLeft,
    MFSideMenuPanDirectionRight
} MFSideMenuPanDirection;

@interface MFSideMenuContainerViewController ()
@property (nonatomic, strong) UIView *menuContainerView;

@property (nonatomic, assign) CGPoint panGestureOrigin;
@property (nonatomic, assign) CGFloat panGestureVelocity;
@property (nonatomic, assign) MFSideMenuPanDirection panDirection;

@property (nonatomic, assign) BOOL viewHasAppeared;
@end

@implementation MFSideMenuContainerViewController

@synthesize leftMenuViewController = _leftSideMenuViewController;
@synthesize centerViewController = _centerViewController;
@synthesize rightMenuViewController = _rightSideMenuViewController;
@synthesize menuContainerView;
@synthesize panMode;
@synthesize panGestureOrigin;
@synthesize panGestureVelocity;
@synthesize menuState = _menuState;
@synthesize panDirection;
@synthesize leftMenuWidth = _leftMenuWidth;
@synthesize rightMenuWidth = _rightMenuWidth;
@synthesize menuSlideAnimationEnabled;
@synthesize menuSlideAnimationFactor;
@synthesize menuAnimationDefaultDuration;
@synthesize menuAnimationMaxDuration;
@synthesize shadow;


#pragma mark -
#pragma mark - Initialization

+ (MFSideMenuContainerViewController *)containerWithCenterViewController:(id)centerViewController
                                                  leftMenuViewController:(id)leftMenuViewController
                                                 rightMenuViewController:(id)rightMenuViewController {
    MFSideMenuContainerViewController *controller = [MFSideMenuContainerViewController new];
    controller.leftMenuViewController = leftMenuViewController;
    controller.centerViewController = centerViewController;
    controller.rightMenuViewController = rightMenuViewController;
    return controller;
}

- (id) init {
    self = [super init];
    if(self) {
        [self setDefaultSettings];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)inCoder {
    id coder = [super initWithCoder:inCoder];
    [self setDefaultSettings];
    return coder;
}

- (void)setDefaultSettings {
    if(self.menuContainerView) return;
    
    self.menuContainerView = [[UIView alloc] init];
    self.menuState = MFSideMenuStateClosed;
    self.menuWidth = 270.0f;
    self.menuSlideAnimationFactor = 3.0f;
    self.menuAnimationDefaultDuration = 0.2f;
    self.menuAnimationMaxDuration = 0.4f;
    self.panMode = MFSideMenuPanModeDefault;
    self.viewHasAppeared = NO;
}

- (void)setupMenuContainerView {
    if(self.menuContainerView.superview) return;
    
    self.menuContainerView.frame = self.view.bounds;
    self.menuContainerView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    
    [self.view insertSubview:menuContainerView atIndex:0];
    
    if(self.leftMenuViewController && !self.leftMenuViewController.view.superview) {
        [self.menuContainerView addSubview:self.leftMenuViewController.view];
    }
    
    if(self.rightMenuViewController && !self.rightMenuViewController.view.superview) {
        [self.menuContainerView addSubview:self.rightMenuViewController.view];
    }
}

#pragma mark -
#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if(!self.viewHasAppeared) {
        [self setupMenuContainerView];
        [self setLeftSideMenuFrameToClosedPosition];
        [self setRightSideMenuFrameToClosedPosition];
        [self addGestureRecognizers];
        [self.shadow draw];
        
        self.viewHasAppeared = YES;
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    if([self respondsToSelector:@selector(topLayoutGuide)]) {
        UIEdgeInsets insets = UIEdgeInsetsMake([self.topLayoutGuide length], 0, 0, 0);
        if(_leftSideMenuViewController &&
            [_leftSideMenuViewController automaticallyAdjustsScrollViewInsets] &&
            [_leftSideMenuViewController.view respondsToSelector:@selector(setContentInset:)]) {
            [(UIScrollView *)_leftSideMenuViewController.view setContentInset:insets];
        }
        if(_rightSideMenuViewController &&
            [_rightSideMenuViewController automaticallyAdjustsScrollViewInsets] &&
            [_rightSideMenuViewController.view respondsToSelector:@selector(setContentInset:)]) {
            [(UIScrollView *)_rightSideMenuViewController.view setContentInset:insets];
        }
    }
}


- (UIStatusBarStyle)preferredStatusBarStyle {
    if (self.centerViewController) {
        if ([self.centerViewController isKindOfClass:[UINavigationController class]]) {
            return [((UINavigationController *)self.centerViewController).topViewController preferredStatusBarStyle];
        }
        return [self.centerViewController preferredStatusBarStyle];
    }
    return UIStatusBarStyleDefault;
}


#pragma mark -
#pragma mark - UIViewController Rotation

-(NSUInteger)supportedInterfaceOrientations {
    if (self.centerViewController) {
        if ([self.centerViewController isKindOfClass:[UINavigationController class]]) {
            return [((UINavigationController *)self.centerViewController).topViewController supportedInterfaceOrientations];
        }
        return [self.centerViewController supportedInterfaceOrientations];
    }
    return [super supportedInterfaceOrientations];
}

-(BOOL)shouldAutorotate {
    if (self.centerViewController) {
        if ([self.centerViewController isKindOfClass:[UINavigationController class]]) {
            return [((UINavigationController *)self.centerViewController).topViewController shouldAutorotate];
        }
        return [self.centerViewController shouldAutorotate];
    }
    return YES;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    if (self.centerViewController) {
        if ([self.centerViewController isKindOfClass:[UINavigationController class]]) {
            return [((UINavigationController *)self.centerViewController).topViewController preferredInterfaceOrientationForPresentation];
        }
        return [self.centerViewController preferredInterfaceOrientationForPresentation];
    }
    return UIInterfaceOrientationPortrait;
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [self.shadow shadowedViewWillRotate];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    [self.shadow shadowedViewDidRotate];
}


#pragma mark -
#pragma mark - UIViewController Containment

- (void)setLeftMenuViewController:(UIViewController *)leftSideMenuViewController {
    [self removeChildViewControllerFromContainer:_leftSideMenuViewController];
    
    _leftSideMenuViewController = leftSideMenuViewController;
    if(!_leftSideMenuViewController) return;
    
    [self addChildViewController:_leftSideMenuViewController];
    if(self.menuContainerView.superview) {
        [self.menuContainerView insertSubview:[_leftSideMenuViewController view] atIndex:0];
    }
    [_leftSideMenuViewController didMoveToParentViewController:self];
    
    if(self.viewHasAppeared) [self setLeftSideMenuFrameToClosedPosition];
}

- (void)setCenterViewController:(UIViewController *)centerViewController {
    [self removeCenterGestureRecognizers];
    [self removeChildViewControllerFromContainer:_centerViewController];
    
    CGPoint origin = ((UIViewController *)_centerViewController).view.frame.origin;
    _centerViewController = centerViewController;
    if(!_centerViewController) return;
    
    [self addChildViewController:_centerViewController];
    [self.view addSubview:[_centerViewController view]];
    [((UIViewController *)_centerViewController) view].frame = (CGRect){.origin = origin, .size=centerViewController.view.frame.size};
    
    [_centerViewController didMoveToParentViewController:self];
    
    if(self.shadow) {
        [self.shadow setShadowedView:centerViewController.view];
    } else {
        self.shadow = [MFSideMenuShadow shadowWithView:[_centerViewController view]];
    }
    [self.shadow draw];
    [self addCenterGestureRecognizers];
}

- (void)setRightMenuViewController:(UIViewController *)rightSideMenuViewController {
    [self removeChildViewControllerFromContainer:_rightSideMenuViewController];
    
    _rightSideMenuViewController = rightSideMenuViewController;
    if(!_rightSideMenuViewController) return;
    
    [self addChildViewController:_rightSideMenuViewController];
    if(self.menuContainerView.superview) {
        [self.menuContainerView insertSubview:[_rightSideMenuViewController view] atIndex:0];
    }
    [_rightSideMenuViewController didMoveToParentViewController:self];
    
    if(self.viewHasAppeared) [self setRightSideMenuFrameToClosedPosition];
}

- (void)removeChildViewControllerFromContainer:(UIViewController *)childViewController {
    if(!childViewController) return;
    [childViewController willMoveToParentViewController:nil];
    [childViewController removeFromParentViewController];
    [childViewController.view removeFromSuperview];
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
    [self addCenterGestureRecognizers];
    [menuContainerView addGestureRecognizer:[self panGestureRecognizer]];
}

- (void)removeCenterGestureRecognizers
{
    if (self.centerViewController)
    {
        [[self.centerViewController view] removeGestureRecognizer:[self centerTapGestureRecognizer]];
        [[self.centerViewController view] removeGestureRecognizer:[self panGestureRecognizer]];
    }
}
- (void)addCenterGestureRecognizers
{
    if (self.centerViewController)
    {
        [[self.centerViewController view] addGestureRecognizer:[self centerTapGestureRecognizer]];
        [[self.centerViewController view] addGestureRecognizer:[self panGestureRecognizer]];
    }
}

- (UITapGestureRecognizer *)centerTapGestureRecognizer
{
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc]
                                             initWithTarget:self
                                             action:@selector(centerViewControllerTapped:)];
    [tapRecognizer setDelegate:self];
    return tapRecognizer;
}


#pragma mark -
#pragma mark - Menu State

- (void)toggleLeftSideMenuCompletion:(void (^)(void))completion {
    if(self.menuState == MFSideMenuStateLeftMenuOpen) {
        [self setMenuState:MFSideMenuStateClosed completion:completion];
    } else {
        [self setMenuState:MFSideMenuStateLeftMenuOpen completion:completion];
    }
}

- (void)toggleRightSideMenuCompletion:(void (^)(void))completion {
    if(self.menuState == MFSideMenuStateRightMenuOpen) {
        [self setMenuState:MFSideMenuStateClosed completion:completion];
    } else {
        [self setMenuState:MFSideMenuStateRightMenuOpen completion:completion];
    }
}

- (void)openLeftSideMenuCompletion:(void (^)(void))completion {
    if(!self.leftMenuViewController) return;
    [self.menuContainerView bringSubviewToFront:[self.leftMenuViewController view]];
    [self setCenterViewControllerOffset:self.leftMenuWidth animated:YES completion:completion];
}

- (void)openRightSideMenuCompletion:(void (^)(void))completion {
    if(!self.rightMenuViewController) return;
    [self.menuContainerView bringSubviewToFront:[self.rightMenuViewController view]];
    [self setCenterViewControllerOffset:-1*self.rightMenuWidth animated:YES completion:completion];
}

- (void)closeSideMenuCompletion:(void (^)(void))completion {
    [self setCenterViewControllerOffset:0 animated:YES completion:completion];
}

- (void)setMenuState:(MFSideMenuState)menuState {
    [self setMenuState:menuState completion:nil];
}

- (void)setMenuState:(MFSideMenuState)menuState completion:(void (^)(void))completion {
    void (^innerCompletion)() = ^ {
        _menuState = menuState;
        
        [self setUserInteractionStateForCenterViewController];
        MFSideMenuStateEvent eventType = (_menuState == MFSideMenuStateClosed) ? MFSideMenuStateEventMenuDidClose : MFSideMenuStateEventMenuDidOpen;
        [self sendStateEventNotification:eventType];
        
        if(completion) completion();
    };
    
    switch (menuState) {
        case MFSideMenuStateClosed: {
            [self sendStateEventNotification:MFSideMenuStateEventMenuWillClose];
            [self closeSideMenuCompletion:^{
                [self.leftMenuViewController view].hidden = YES;
                [self.rightMenuViewController view].hidden = YES;
                innerCompletion();
            }];
            break;
        }
        case MFSideMenuStateLeftMenuOpen:
            if(!self.leftMenuViewController) return;
            [self sendStateEventNotification:MFSideMenuStateEventMenuWillOpen];
            [self leftMenuWillShow];
            [self openLeftSideMenuCompletion:innerCompletion];
            break;
        case MFSideMenuStateRightMenuOpen:
            if(!self.rightMenuViewController) return;
            [self sendStateEventNotification:MFSideMenuStateEventMenuWillOpen];
            [self rightMenuWillShow];
            [self openRightSideMenuCompletion:innerCompletion];
            break;
        default:
            break;
    }
}

// these callbacks are called when the menu will become visible, not neccessarily when they will OPEN
- (void)leftMenuWillShow {
    [self.leftMenuViewController view].hidden = NO;
    [self.menuContainerView bringSubviewToFront:[self.leftMenuViewController view]];
}

- (void)rightMenuWillShow {
    [self.rightMenuViewController view].hidden = NO;
    [self.menuContainerView bringSubviewToFront:[self.rightMenuViewController view]];
}


#pragma mark -
#pragma mark - State Event Notification

- (void)sendStateEventNotification:(MFSideMenuStateEvent)event {
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:event]
                                                         forKey:@"eventType"];
    [[NSNotificationCenter defaultCenter] postNotificationName:MFSideMenuStateNotificationEvent
                                                        object:self
                                                      userInfo:userInfo];
}


#pragma mark -
#pragma mark - Side Menu Positioning

- (void) setLeftSideMenuFrameToClosedPosition {
    if(!self.leftMenuViewController) return;
    CGRect leftFrame = [self.centerViewController view].frame;
    leftFrame.size.width = self.leftMenuWidth;
    leftFrame.origin.x = (self.menuSlideAnimationEnabled) ? -1*leftFrame.size.width / self.menuSlideAnimationFactor : 0;
    leftFrame.origin.y = 0;
    [self.leftMenuViewController view].frame = leftFrame;
    [self.leftMenuViewController view].autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleHeight;
}

- (void) setRightSideMenuFrameToClosedPosition {
    if(!self.rightMenuViewController) return;
    CGRect rightFrame = [self.centerViewController view].frame;
    rightFrame.size.width = self.rightMenuWidth;
    rightFrame.origin.y = 0;
    rightFrame.origin.x = self.menuContainerView.frame.size.width - self.rightMenuWidth;
    if(self.menuSlideAnimationEnabled) rightFrame.origin.x += self.rightMenuWidth / self.menuSlideAnimationFactor;
    [self.rightMenuViewController view].frame = rightFrame;
    [self.rightMenuViewController view].autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleHeight;
}

- (void)alignLeftMenuControllerWithCenterViewController {
    CGRect leftMenuFrame = [self.leftMenuViewController view].frame;
    leftMenuFrame.size.width = _leftMenuWidth;
    
    CGFloat xOffset = [self.centerViewController view].frame.origin.x;
    CGFloat xPositionDivider = (self.menuSlideAnimationEnabled) ? self.menuSlideAnimationFactor : 1.0;
    leftMenuFrame.origin.x = xOffset / xPositionDivider - _leftMenuWidth / xPositionDivider;
    
    [self.leftMenuViewController view].frame = leftMenuFrame;
}

- (void)alignRightMenuControllerWithCenterViewController {
    CGRect rightMenuFrame = [self.rightMenuViewController view].frame;
    rightMenuFrame.size.width = _rightMenuWidth;
    
    CGFloat xOffset = [self.centerViewController view].frame.origin.x;
    CGFloat xPositionDivider = (self.menuSlideAnimationEnabled) ? self.menuSlideAnimationFactor : 1.0;
    rightMenuFrame.origin.x = self.menuContainerView.frame.size.width - _rightMenuWidth
        + xOffset / xPositionDivider
        + _rightMenuWidth / xPositionDivider;
    
    [self.rightMenuViewController view].frame = rightMenuFrame;
}


#pragma mark -
#pragma mark - Side Menu Width

- (void)setMenuWidth:(CGFloat)menuWidth {
    [self setMenuWidth:menuWidth animated:YES];
}

- (void)setLeftMenuWidth:(CGFloat)leftMenuWidth {
    [self setLeftMenuWidth:leftMenuWidth animated:YES];
}

- (void)setRightMenuWidth:(CGFloat)rightMenuWidth {
    [self setRightMenuWidth:rightMenuWidth animated:YES];
}

- (void)setMenuWidth:(CGFloat)menuWidth animated:(BOOL)animated {
    [self setLeftMenuWidth:menuWidth animated:animated];
    [self setRightMenuWidth:menuWidth animated:animated];
}

- (void)setLeftMenuWidth:(CGFloat)leftMenuWidth animated:(BOOL)animated {
    _leftMenuWidth = leftMenuWidth;
    
    if(self.menuState != MFSideMenuStateLeftMenuOpen) {
        [self setLeftSideMenuFrameToClosedPosition];
        return;
    }
    
    CGFloat offset = _leftMenuWidth;
    void (^effects)() = ^ {
        [self alignLeftMenuControllerWithCenterViewController];
    };
    
    [self setCenterViewControllerOffset:offset additionalAnimations:effects animated:animated completion:nil];
}

- (void)setRightMenuWidth:(CGFloat)rightMenuWidth animated:(BOOL)animated {
    _rightMenuWidth = rightMenuWidth;
    
    if(self.menuState != MFSideMenuStateRightMenuOpen) {
        [self setRightSideMenuFrameToClosedPosition];
        return;
    }
    
    CGFloat offset = -1*rightMenuWidth;
    void (^effects)() = ^ {
        [self alignRightMenuControllerWithCenterViewController];
    };
    
    [self setCenterViewControllerOffset:offset additionalAnimations:effects animated:animated completion:nil];
}


#pragma mark -
#pragma mark - MFSideMenuPanMode

- (BOOL) centerViewControllerPanEnabled {
    return ((self.panMode & MFSideMenuPanModeCenterViewController) == MFSideMenuPanModeCenterViewController);
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
        if([gestureRecognizer.view isEqual:[self.centerViewController view]])
            return [self centerViewControllerPanEnabled];
        
        if([gestureRecognizer.view isEqual:self.menuContainerView])
           return [self sideMenuPanEnabled];
        
        // pan gesture is attached to a custom view
        return YES;
    }
    
    return NO;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        CGPoint velocity = [(UIPanGestureRecognizer *)gestureRecognizer velocityInView:gestureRecognizer.view];
        BOOL isHorizontalPanning = fabsf(velocity.x) > fabsf(velocity.y);
        return isHorizontalPanning;
    }
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
    UIView *view = [self.centerViewController view];
    
	if(recognizer.state == UIGestureRecognizerStateBegan) {
        // remember where the pan started
        panGestureOrigin = view.frame.origin;
        self.panDirection = MFSideMenuPanDirectionNone;
	}
    
    if(self.panDirection == MFSideMenuPanDirectionNone) {
        CGPoint translatedPoint = [recognizer translationInView:view];
        if(translatedPoint.x > 0) {
            self.panDirection = MFSideMenuPanDirectionRight;
            if(self.leftMenuViewController && self.menuState == MFSideMenuStateClosed) {
                [self leftMenuWillShow];
            }
        }
        else if(translatedPoint.x < 0) {
            self.panDirection = MFSideMenuPanDirectionLeft;
            if(self.rightMenuViewController && self.menuState == MFSideMenuStateClosed) {
                [self rightMenuWillShow];
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
    if(!self.leftMenuViewController && self.menuState == MFSideMenuStateClosed) return;
    
    UIView *view = [self.centerViewController view];
    
    CGPoint translatedPoint = [recognizer translationInView:view];
    CGPoint adjustedOrigin = panGestureOrigin;
    translatedPoint = CGPointMake(adjustedOrigin.x + translatedPoint.x,
                                  adjustedOrigin.y + translatedPoint.y);
    
    translatedPoint.x = MAX(translatedPoint.x, -1*self.rightMenuWidth);
    translatedPoint.x = MIN(translatedPoint.x, self.leftMenuWidth);
    if(self.menuState == MFSideMenuStateRightMenuOpen) {
        // menu is already open, the most the user can do is close it in this gesture
        translatedPoint.x = MIN(translatedPoint.x, 0);
    } else {
        // we are opening the menu
        translatedPoint.x = MAX(translatedPoint.x, 0);
    }
    
    if(recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [recognizer velocityInView:view];
        CGFloat finalX = translatedPoint.x + (.35*velocity.x);
        CGFloat viewWidth = view.frame.size.width;
        
        if(self.menuState == MFSideMenuStateClosed) {
            BOOL showMenu = (finalX > viewWidth/2) || (finalX > self.leftMenuWidth/2);
            if(showMenu) {
                self.panGestureVelocity = velocity.x;
                [self setMenuState:MFSideMenuStateLeftMenuOpen];
            } else {
                self.panGestureVelocity = 0;
                [self setCenterViewControllerOffset:0 animated:YES completion:nil];
            }
        } else {
            BOOL hideMenu = (finalX > adjustedOrigin.x);
            if(hideMenu) {
                self.panGestureVelocity = velocity.x;
                [self setMenuState:MFSideMenuStateClosed];
            } else {
                self.panGestureVelocity = 0;
                [self setCenterViewControllerOffset:adjustedOrigin.x animated:YES completion:nil];
            }
        }
        
        self.panDirection = MFSideMenuPanDirectionNone;
	} else {
        [self setCenterViewControllerOffset:translatedPoint.x];
    }
}

- (void) handleLeftPan:(UIPanGestureRecognizer *)recognizer {
    if(!self.rightMenuViewController && self.menuState == MFSideMenuStateClosed) return;
    
    UIView *view = [self.centerViewController view];
    
    CGPoint translatedPoint = [recognizer translationInView:view];
    CGPoint adjustedOrigin = panGestureOrigin;
    translatedPoint = CGPointMake(adjustedOrigin.x + translatedPoint.x,
                                  adjustedOrigin.y + translatedPoint.y);
    
    translatedPoint.x = MAX(translatedPoint.x, -1*self.rightMenuWidth);
    translatedPoint.x = MIN(translatedPoint.x, self.leftMenuWidth);
    if(self.menuState == MFSideMenuStateLeftMenuOpen) {
        // don't let the pan go less than 0 if the menu is already open
        translatedPoint.x = MAX(translatedPoint.x, 0);
    } else {
        // we are opening the menu
        translatedPoint.x = MIN(translatedPoint.x, 0);
    }
    
    [self setCenterViewControllerOffset:translatedPoint.x];
    
	if(recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [recognizer velocityInView:view];
        CGFloat finalX = translatedPoint.x + (.35*velocity.x);
        CGFloat viewWidth = view.frame.size.width;
        
        if(self.menuState == MFSideMenuStateClosed) {
            BOOL showMenu = (finalX < -1*viewWidth/2) || (finalX < -1*self.rightMenuWidth/2);
            if(showMenu) {
                self.panGestureVelocity = velocity.x;
                [self setMenuState:MFSideMenuStateRightMenuOpen];
            } else {
                self.panGestureVelocity = 0;
                [self setCenterViewControllerOffset:0 animated:YES completion:nil];
            }
        } else {
            BOOL hideMenu = (finalX < adjustedOrigin.x);
            if(hideMenu) {
                self.panGestureVelocity = velocity.x;
                [self setMenuState:MFSideMenuStateClosed];
            } else {
                self.panGestureVelocity = 0;
                [self setCenterViewControllerOffset:adjustedOrigin.x animated:YES completion:nil];
            }
        }
	} else {
        [self setCenterViewControllerOffset:translatedPoint.x];
    }
}

- (void)centerViewControllerTapped:(id)sender {
    if(self.menuState != MFSideMenuStateClosed) {
        [self setMenuState:MFSideMenuStateClosed];
    }
}

- (void)setUserInteractionStateForCenterViewController {
    // disable user interaction on the current stack of view controllers if the menu is visible
    if([self.centerViewController respondsToSelector:@selector(viewControllers)]) {
        NSArray *viewControllers = [self.centerViewController viewControllers];
        for(UIViewController* viewController in viewControllers) {
            viewController.view.userInteractionEnabled = (self.menuState == MFSideMenuStateClosed);
        }
    }
}

#pragma mark -
#pragma mark - Center View Controller Movement

- (void)setCenterViewControllerOffset:(CGFloat)offset animated:(BOOL)animated completion:(void (^)(void))completion {
    [self setCenterViewControllerOffset:offset additionalAnimations:nil
                               animated:animated completion:completion];
}

- (void)setCenterViewControllerOffset:(CGFloat)offset
                 additionalAnimations:(void (^)(void))additionalAnimations
                             animated:(BOOL)animated
                           completion:(void (^)(void))completion {
    void (^innerCompletion)() = ^ {
        self.panGestureVelocity = 0.0;
        if(completion) completion();
    };
    
    if(animated) {
        CGFloat centerViewControllerXPosition = ABS([self.centerViewController view].frame.origin.x);
        CGFloat duration = [self animationDurationFromStartPosition:centerViewControllerXPosition toEndPosition:offset];
        
        [UIView animateWithDuration:duration animations:^{
            [self setCenterViewControllerOffset:offset];
            if(additionalAnimations) additionalAnimations();
        } completion:^(BOOL finished) {
            innerCompletion();
        }];
    } else {
        [self setCenterViewControllerOffset:offset];
        if(additionalAnimations) additionalAnimations();
        innerCompletion();
    }
}

- (void) setCenterViewControllerOffset:(CGFloat)xOffset {
    CGRect frame = [self.centerViewController view].frame;
    frame.origin.x = xOffset;
    [self.centerViewController view].frame = frame;
    
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
        // TODO: full animation duration hard to calculate with two menu widths
        CGFloat menuWidth = MAX(_leftMenuWidth, _rightMenuWidth);
        CGFloat animationPerecent = (animationPositionDelta == 0) ? 0 : menuWidth / animationPositionDelta;
        duration = self.menuAnimationDefaultDuration * animationPerecent;
    }
    
    return MIN(duration, self.menuAnimationMaxDuration);
}

@end
