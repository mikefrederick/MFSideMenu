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

@interface UIView (Screenshot)
- (UIImage *)screenshot;
@end

@interface UIScrollView (Screenshot)
- (UIImage *)screenshot;
@end

@interface MFSideMenuContainerViewController ()

@property (nonatomic, strong) UIView *leftMenuContainer;
@property (nonatomic, strong) UIView *rightMenuContainer;

@property (nonatomic, strong) UIImageView *centerImageView;
@property (nonatomic, strong) UIImageView *leftImageView;
@property (nonatomic, strong) UIImageView *rightImageView;

@property (nonatomic, assign) CGPoint panGestureOrigin;
@property (nonatomic, assign) CGFloat panGestureVelocity;
@property (nonatomic, assign) MFSideMenuPanDirection panDirection;

@property (nonatomic, assign) BOOL viewHasAppeared;
@end

@implementation MFSideMenuContainerViewController

@synthesize leftMenuViewController = _leftSideMenuViewController;
@synthesize centerViewController = _centerViewController;
@synthesize rightMenuViewController = _rightSideMenuViewController;
@synthesize leftMenuContainer;
@synthesize rightMenuContainer;
@synthesize centerImageView;
@synthesize leftImageView;
@synthesize rightImageView;
@synthesize panMode;
@synthesize panGestureOrigin;
@synthesize panGestureVelocity;
@synthesize menuState = _menuState;
@synthesize panDirection;
@synthesize leftMenuWidth = _leftMenuWidth;
@synthesize rightMenuWidth = _rightMenuWidth;
@synthesize showMenuOverContent = _showMenuOverContent;
@synthesize menuParallaxFactor = _menuParallaxFactor;
@synthesize contentParallaxFactor = _contentParallaxFactor;
@synthesize menuScaleFactor = _menuScaleFactor;
@synthesize contentScaleFactor = _contentScaleFactor;
@synthesize menuSlideAnimationEnabled = _menuSlideAnimationEnabled;
@synthesize menuSlideAnimationFactor = _menuSlideAnimationFactor;
@synthesize menuAnimationDefaultDuration;
@synthesize menuAnimationMaxDuration;
@synthesize contentShadow;
@synthesize leftMenuShadow;
@synthesize rightMenuShadow;


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
    if (self.leftMenuContainer) return;
    
    self.leftMenuContainer = [[UIView alloc] init];
    self.rightMenuContainer = [[UIView alloc] init];
    
    self.centerImageView = [[UIImageView alloc] init];
    self.leftImageView = [[UIImageView alloc] init];
    self.rightImageView = [[UIImageView alloc] init];
    self.contentScaleFactor = 1.0;
    self.menuScaleFactor = 1.0;
    
    self.menuState = MFSideMenuStateClosed;
    self.menuWidth = 270.0f;
    self.menuAnimationDefaultDuration = 0.2f;
    self.menuAnimationMaxDuration = 0.4f;
    self.panMode = MFSideMenuPanModeDefault;
    self.viewHasAppeared = NO;
}

- (void)setupMenuContainerViews {
    if (self.leftMenuContainer.superview && self.rightMenuContainer.superview) return;    
    self.leftMenuContainer.frame = CGRectMake(-self.leftMenuWidth, 0, self.leftMenuWidth, self.view.bounds.size.height);
    [self.view addSubview:self.leftMenuContainer];
    self.leftMenuContainer.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.leftMenuContainer.backgroundColor = [UIColor clearColor];

    self.rightMenuContainer.frame = CGRectMake(self.view.bounds.size.width, 0, self.rightMenuWidth, self.view.bounds.size.height);
    [self.view addSubview:self.rightMenuContainer];
    self.rightMenuContainer.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.rightMenuContainer.backgroundColor = [UIColor clearColor];
    
    if(self.leftMenuViewController && !self.leftMenuViewController.view.superview) {
        [self.leftMenuContainer addSubview:self.leftMenuViewController.view];
    }
    
    if(self.rightMenuViewController && !self.rightMenuViewController.view.superview) {
        [self.rightMenuContainer addSubview:self.rightMenuViewController.view];
    }
    
    self.centerImageView.image = nil;
    self.centerImageView.contentMode = UIViewContentModeScaleToFill;
    self.centerImageView.userInteractionEnabled = YES;
    self.centerImageView.hidden = YES;
    self.centerImageView.backgroundColor = [UIColor clearColor];
    self.centerImageView.frame = self.view.bounds;
    
    self.leftImageView.image = nil;
    self.leftImageView.contentMode = UIViewContentModeScaleToFill;
    self.leftImageView.userInteractionEnabled = YES;
    self.leftImageView.hidden = YES;
    self.leftImageView.backgroundColor = [UIColor clearColor];
    self.leftImageView.frame = self.leftMenuContainer.bounds;
    
    self.rightImageView.image = nil;
    self.rightImageView.contentMode = UIViewContentModeScaleToFill;
    self.rightImageView.userInteractionEnabled = YES;
    self.rightImageView.hidden = YES;
    self.rightImageView.backgroundColor = [UIColor clearColor];
    self.rightImageView.frame = self.rightMenuContainer.bounds;
    
    [self.view addSubview:self.centerImageView];
    [self.leftMenuContainer addSubview:self.leftImageView];
    [self.rightMenuContainer addSubview:self.rightImageView];
}


#pragma mark -
#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupMenuContainerViews];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if(!self.viewHasAppeared) {
        [self setLeftSideMenuFrameToClosedPosition];
        [self setRightSideMenuFrameToClosedPosition];
        [self addGestureRecognizers];
        [self.contentShadow draw];
        [self.leftMenuShadow draw];
        [self.rightMenuShadow draw];
        
        self.viewHasAppeared = YES;
    }
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
    
    [self.contentShadow shadowedViewWillRotate];
    [self.leftMenuShadow shadowedViewWillRotate];
    [self.rightMenuShadow shadowedViewWillRotate];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    [self.contentShadow shadowedViewDidRotate];
    [self.leftMenuShadow shadowedViewDidRotate];
    [self.rightMenuShadow shadowedViewDidRotate];
}


#pragma mark -
#pragma mark - UIViewController Containment

- (void)setLeftMenuViewController:(UIViewController *)leftSideMenuViewController {
    [self removeChildViewControllerFromContainer:_leftSideMenuViewController];
    self.leftMenuShadow = nil;
    
    _leftSideMenuViewController = leftSideMenuViewController;
    if(!_leftSideMenuViewController) return;
    
    [self addChildViewController:_leftSideMenuViewController];
    _leftSideMenuViewController.view.frame = self.leftMenuContainer.bounds;
    [self.leftMenuContainer addSubview:[_leftSideMenuViewController view]];
    [_leftSideMenuViewController didMoveToParentViewController:self];
    
    if(self.viewHasAppeared) [self setLeftSideMenuFrameToClosedPosition];
    
    self.leftMenuShadow = [MFSideMenuShadow shadowWithView:self.leftMenuContainer];
    [self.leftMenuShadow draw];
}

- (void)setCenterViewController:(UIViewController *)centerViewController {
    [self removeCenterGestureRecognizers];
    [self removeChildViewControllerFromContainer:_centerViewController];
    self.contentShadow = nil;
    
    CGPoint origin = ((UIViewController *)_centerViewController).view.frame.origin;
    _centerViewController = centerViewController;
    if(!_centerViewController) return;
    
    [self addChildViewController:_centerViewController];
    [self.view addSubview:[_centerViewController view]];
    [((UIViewController *)_centerViewController) view].frame = (CGRect){.origin = origin, .size=centerViewController.view.frame.size};
    
    [_centerViewController didMoveToParentViewController:self];
    
    self.contentShadow = [MFSideMenuShadow shadowWithView:[_centerViewController view]];
    [self.contentShadow draw];
    [self addCenterGestureRecognizers];
}

- (void)setRightMenuViewController:(UIViewController *)rightSideMenuViewController {
    [self removeChildViewControllerFromContainer:_rightSideMenuViewController];
    self.rightMenuShadow = nil;
    
    _rightSideMenuViewController = rightSideMenuViewController;
    if(!_rightSideMenuViewController) return;
    
    [self addChildViewController:_rightSideMenuViewController];
    _rightSideMenuViewController.view.frame = self.rightMenuContainer.bounds;
    [self.rightMenuContainer addSubview:[_rightSideMenuViewController view]];
    [_rightSideMenuViewController didMoveToParentViewController:self];
    
    if(self.viewHasAppeared) [self setRightSideMenuFrameToClosedPosition];
    
    self.rightMenuShadow = [MFSideMenuShadow shadowWithView:self.rightMenuContainer];
    [self.rightMenuShadow draw];
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
    [self.leftMenuContainer addGestureRecognizer:[self panGestureRecognizer]];
    [self.rightMenuContainer addGestureRecognizer:[self panGestureRecognizer]];
}

- (void)removeCenterGestureRecognizers
{
    if (self.centerViewController)
    {
        [[self.centerViewController view] removeGestureRecognizer:[self centerTapGestureRecognizer]];
        [[self.centerViewController view] removeGestureRecognizer:[self panGestureRecognizer]];
        [self.centerImageView removeGestureRecognizer:[self centerTapGestureRecognizer]];
        [self.centerImageView removeGestureRecognizer:[self panGestureRecognizer]];
    }
}
- (void)addCenterGestureRecognizers
{
    if (self.centerViewController)
    {
        [[self.centerViewController view] addGestureRecognizer:[self centerTapGestureRecognizer]];
        [[self.centerViewController view] addGestureRecognizer:[self panGestureRecognizer]];
        [self.centerImageView addGestureRecognizer:[self centerTapGestureRecognizer]];
        [self.centerImageView addGestureRecognizer:[self panGestureRecognizer]];
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
    
    [self setControllerOffset:self.leftMenuWidth animated:YES completion:completion];
}

- (void)openRightSideMenuCompletion:(void (^)(void))completion {
    if(!self.rightMenuViewController) return;

    [self setControllerOffset:-self.rightMenuWidth animated:YES completion:completion];
}

- (void)closeSideMenuCompletion:(void (^)(void))completion {
    [self setControllerOffset:0 animated:YES completion:completion];
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
                self.leftMenuContainer.hidden = YES;
                self.rightMenuContainer.hidden = YES;
                self.centerImageView.image = nil;
                self.centerImageView.hidden = YES;
                [self.centerViewController view].hidden = NO;
                self.contentShadow.shadowedView = [self.centerViewController view];
                [self.contentShadow draw];
                
                self.leftImageView.image = nil;
                self.leftImageView.hidden = YES;
                self.leftMenuViewController.view.hidden = NO;
                self.leftMenuShadow.shadowedView = self.leftMenuViewController.view;
                [self.leftMenuShadow draw];
                
                self.rightImageView.image = nil;
                self.rightImageView.hidden = YES;
                self.rightMenuViewController.view.hidden = NO;
                self.rightMenuShadow.shadowedView = self.rightMenuViewController.view;
                [self.rightMenuShadow draw];
                
                innerCompletion();
            }];
            break;
        }
        case MFSideMenuStateLeftMenuOpen: {
            if(!self.leftMenuViewController) return;
            [self sendStateEventNotification:MFSideMenuStateEventMenuWillOpen];
            [self leftMenuWillShow];
            [self openLeftSideMenuCompletion:^{
                self.leftImageView.image = nil;
                self.leftImageView.hidden = YES;
                self.leftMenuViewController.view.hidden = NO;
                self.leftMenuShadow.shadowedView = self.leftMenuViewController.view;
                [self.leftMenuShadow draw];
                innerCompletion();
            }];
            break;
        }
        case MFSideMenuStateRightMenuOpen: {
            if(!self.rightMenuViewController) return;
            [self sendStateEventNotification:MFSideMenuStateEventMenuWillOpen];
            [self rightMenuWillShow];
            [self openRightSideMenuCompletion:^{
                self.rightImageView.image = nil;
                self.rightImageView.hidden = YES;
                self.rightMenuViewController.view.hidden = NO;
                self.rightMenuShadow.shadowedView = self.rightMenuViewController.view;
                [self.rightMenuShadow draw];
                innerCompletion();
            }];
            break;
        }
        default:
            break;
    }
}

// these callbacks are called when the menu will become visible, not neccessarily when they will OPEN
- (void)leftMenuWillShow {
    self.leftMenuContainer.hidden = NO;
}

- (void)rightMenuWillShow {
    self.rightMenuContainer.hidden = NO;
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
#pragma mark - View Controller Movements

// Set offset from negative self.rightMenuWidth to positive self.leftMenuWidth
// An offset of 0 is closed

- (void)setControllerOffset:(CGFloat)offset animated:(BOOL)animated completion:(void (^)(void))completion {
    [self setControllerOffset:offset additionalAnimations:nil
                     animated:animated completion:completion];
}

- (void)setControllerOffset:(CGFloat)offset
       additionalAnimations:(void (^)(void))additionalAnimations
                   animated:(BOOL)animated
                 completion:(void (^)(void))completion {
    void (^innerCompletion)() = ^ {
        self.panGestureVelocity = 0.0;
        if(completion) completion();
    };
    
    if(animated) {
        CGFloat centerViewControllerXPosition = [self.centerViewController view].frame.origin.x/self.contentParallaxFactor;
        CGFloat duration = [self animationDurationFromStartPosition:centerViewControllerXPosition toEndPosition:offset];
        
        [UIView animateWithDuration:duration animations:^{
            CGFloat leftAlpha = self.leftMenuShadow.alpha;
            CGFloat rightAlpha = self.rightMenuShadow.alpha;
            
            [self setControllerOffset:offset];
            
            // Otherwise shadow is removed while menu closes
            if (self.leftMenuShadow.alpha != leftAlpha && leftAlpha > 0)
                self.leftMenuShadow.alpha = leftAlpha;
            if (self.rightMenuShadow.alpha != rightAlpha && rightAlpha > 0)
                self.rightMenuShadow.alpha = rightAlpha;
            
            if(additionalAnimations) additionalAnimations();
        } completion:^(BOOL finished) {
            [self setControllerOffset:offset];
            innerCompletion();
        }];
    } else {
        [self setControllerOffset:offset];
        if(additionalAnimations) additionalAnimations();
        innerCompletion();
    }
}

- (void)setControllerOffset:(CGFloat)offset {
    CGRect leftFrame = self.leftMenuContainer.frame;
    CGRect centerFrame = [self.centerViewController view].frame;
    CGRect rightFrame = self.rightMenuContainer.frame;
    
    leftFrame.origin.x = MIN(0, MAX(-self.leftMenuWidth, offset - self.leftMenuWidth)) * self.menuParallaxFactor;
    centerFrame.origin.x = offset * self.contentParallaxFactor;
    rightFrame.origin.x = centerFrame.size.width - self.rightMenuWidth * (1 - self.menuParallaxFactor) + offset * self.menuParallaxFactor;
    
    
    self.leftMenuContainer.frame = leftFrame;
    [self.centerViewController view].frame = centerFrame;
    self.rightMenuContainer.frame = rightFrame;
    
    self.leftMenuShadow.alpha = MAX(0, MIN(1, offset/20));
    self.rightMenuShadow.alpha = MAX(0, MIN(1, -offset/20));
    
    
    // handle scaling
    if (offset != 0 && self.centerImageView.hidden == YES)
    {
        self.centerImageView.image = [self.centerViewController view].screenshot;
        self.centerImageView.layer.sublayers = nil;
        self.contentShadow.shadowedView = self.centerImageView;
        [self.contentShadow draw];
        self.centerImageView.hidden = NO;
        [self.centerViewController view].hidden = YES;
        
        self.leftImageView.image = [self.leftMenuViewController view].screenshot;
        self.leftImageView.layer.sublayers = nil;
        self.leftMenuShadow.shadowedView = self.leftImageView;
        [self.leftMenuShadow draw];
        self.leftImageView.hidden = NO;
        [self.leftMenuViewController view].hidden = YES;
        
        self.rightImageView.image = [self.rightMenuViewController view].screenshot;
        self.rightImageView.layer.sublayers = nil;
        self.rightMenuShadow.shadowedView = self.rightImageView;
        [self.rightMenuShadow draw];
        self.rightImageView.hidden = NO;
        [self.rightMenuViewController view].hidden = YES;
    }
    if (offset != self.leftMenuWidth && self.leftImageView.hidden == YES)
    {
        self.leftImageView.image = [self.leftMenuViewController view].screenshot;
        self.leftImageView.layer.sublayers = nil;
        self.leftMenuShadow.shadowedView = self.leftImageView;
        [self.leftMenuShadow draw];
        self.leftImageView.hidden = NO;
        [self.leftMenuViewController view].hidden = YES;
    }
    if (offset != self.rightMenuWidth && self.rightImageView.hidden == YES)
    {
        self.rightImageView.image = [self.rightMenuViewController view].screenshot;
        self.rightImageView.layer.sublayers = nil;
        self.rightMenuShadow.shadowedView = self.rightImageView;
        [self.rightMenuShadow draw];
        self.rightImageView.hidden = NO;
        [self.rightMenuViewController view].hidden = YES;
    }
    
    CGFloat slideRatio = offset == 0 ? 0 : MAX(offset/self.leftMenuWidth, -offset/self.rightMenuWidth);
    
    CGRect centerImageFrame = centerFrame;
    centerImageFrame.size.width = (1 - (1 - self.contentScaleFactor) * slideRatio) * centerFrame.size.width;
    centerImageFrame.size.height = (1 - (1 - self.contentScaleFactor) * slideRatio) * centerFrame.size.height;
    centerImageFrame.origin.y = (1 - self.contentScaleFactor) * slideRatio * centerFrame.size.height / 2;
    if (offset > 0)
        centerImageFrame.origin.x = MAX(MIN((centerFrame.size.width - centerImageFrame.size.width)/2 + centerFrame.origin.x,leftFrame.origin.x + leftFrame.size.width),self.view.bounds.size.width - centerImageFrame.size.width);
    else if (offset < 0)
        centerImageFrame.origin.x = MIN(MAX((centerFrame.size.width - centerImageFrame.size.width)/2 + centerFrame.origin.x, rightFrame.origin.x - centerImageFrame.size.width),0);
    
    self.centerImageView.frame = centerImageFrame;
    
    CGRect leftImageFrame = self.leftMenuContainer.bounds;
    leftImageFrame.size.width = (1 - (1 - self.menuScaleFactor) * (1 - slideRatio)) * leftFrame.size.width;
    leftImageFrame.size.height = (1 - (1 - self.menuScaleFactor) * (1 - slideRatio)) * leftFrame.size.height;
    leftImageFrame.origin.x = 0;
    leftImageFrame.origin.y = (leftFrame.size.height - leftImageFrame.size.height) / 2;
    
    self.leftImageView.frame = leftImageFrame;
    
    CGRect rightImageFrame = self.rightMenuContainer.bounds;
    rightImageFrame.size.width = (1 - (1 - self.menuScaleFactor) * (1 - slideRatio)) * rightFrame.size.width;
    rightImageFrame.size.height = (1 - (1 - self.menuScaleFactor) * (1 - slideRatio)) * rightFrame.size.height;
    rightImageFrame.origin.x = rightFrame.size.width - rightImageFrame.size.width;
    rightImageFrame.origin.y = (rightFrame.size.height - rightImageFrame.size.height) / 2;
    
    self.rightImageView.frame = rightImageFrame;
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

- (void) setLeftSideMenuFrameToClosedPosition {
    if(!self.leftMenuViewController) return;
    CGRect leftFrame = self.leftMenuContainer.frame;
    leftFrame.size.width = self.leftMenuWidth;
    leftFrame.size.height = self.view.bounds.size.height;
    leftFrame.origin.x = -self.leftMenuWidth * self.menuParallaxFactor;
    leftFrame.origin.y = 0;
    self.leftMenuContainer.frame = leftFrame;
    self.leftMenuContainer.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleHeight;
}

- (void) setRightSideMenuFrameToClosedPosition {
    if(!self.rightMenuViewController) return;
    CGRect rightFrame = self.rightMenuContainer.frame;
    rightFrame.size.width = self.rightMenuWidth;
    rightFrame.size.height = self.view.bounds.size.height;
    rightFrame.origin.y = 0;
    rightFrame.origin.x = self.view.bounds.size.width - self.rightMenuWidth * (1 - self.menuParallaxFactor);
    self.rightMenuContainer.frame = rightFrame;
    self.rightMenuContainer.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleHeight;
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
    
    CGRect menuRect = self.leftMenuContainer.frame;
    menuRect.size.width = _leftMenuWidth;
    self.leftMenuContainer.frame = menuRect;
    
    [self setControllerOffset:_leftMenuWidth animated:animated completion:nil];
}

- (void)setRightMenuWidth:(CGFloat)rightMenuWidth animated:(BOOL)animated {
    _rightMenuWidth = rightMenuWidth;
    
    if(self.menuState != MFSideMenuStateRightMenuOpen) {
        [self setRightSideMenuFrameToClosedPosition];
        return;
    }
    
    CGRect menuRect = self.rightMenuContainer.frame;
    menuRect.origin.x = self.view.bounds.size.width - _rightMenuWidth;
    menuRect.size.width = _rightMenuWidth;
    self.rightMenuContainer.frame = menuRect;
    
    [self setControllerOffset:-_rightMenuWidth animated:animated completion:nil];
}


#pragma mark -
#pragma mark - Menu Sliding Options

- (void)setShowMenuOverContent:(BOOL)showMenuOverContent
{
    _showMenuOverContent = showMenuOverContent;
    
    if (_showMenuOverContent)
    {
        [self.view sendSubviewToBack:[self.centerViewController view]];
        [self.view sendSubviewToBack:self.centerImageView];
    }
    else
    {
        [self.view bringSubviewToFront:[self.centerViewController view]];
        [self.view bringSubviewToFront:self.centerImageView];
    }
}

- (CGFloat)menuParallaxFactor
{
    return (self.showMenuOverContent ? 1 : _menuParallaxFactor);
}

- (void)setMenuParallaxFactor:(CGFloat)menuParallaxFactor
{
    _menuParallaxFactor = MAX(0, MIN(1, menuParallaxFactor));
}

- (CGFloat)contentParallaxFactor
{
    return (self.showMenuOverContent ? _contentParallaxFactor : 1);
}

- (void)setContentParallaxFactor:(CGFloat)contentParallaxFactor
{
    _contentParallaxFactor = MAX(0, MIN(1, contentParallaxFactor));
}

- (CGFloat)menuScaleFactor
{
    return (self.showMenuOverContent ? 1 : _menuScaleFactor);
}

- (void)setMenuScaleFactor:(CGFloat)menuScaleFactor
{
    _menuScaleFactor = MAX(0, MIN(1, menuScaleFactor));
}

- (CGFloat)contentScaleFactor
{
    return (self.showMenuOverContent ? _contentScaleFactor : 1);
}

- (void)setContentScaleFactor:(CGFloat)contentScaleFactor
{
    _contentScaleFactor = MAX(0, MIN(1, contentScaleFactor));
}

- (void)setMenuSlideAnimationEnabled:(BOOL)menuSlideAnimationEnabled
{
    _menuSlideAnimationEnabled = menuSlideAnimationEnabled;
    
    if (_menuSlideAnimationEnabled)
        [self setMenuParallaxFactor:1/self.menuSlideAnimationFactor];
    
    else
        [self setMenuParallaxFactor:0];
}

- (void)setMenuSlideAnimationFactor:(CGFloat)menuSlideAnimationFactor
{
    _menuSlideAnimationFactor = menuSlideAnimationFactor;
    
    if (self.menuSlideAnimationEnabled)
        [self setMenuParallaxFactor:1/_menuSlideAnimationFactor];
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
        
        if([gestureRecognizer.view isEqual:self.leftMenuContainer] || [gestureRecognizer.view isEqual:self.rightMenuContainer])
            return [self sideMenuPanEnabled];
        
        // pan gesture is attached to a custom view
        return YES;
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
    
    if (self.panDirection == MFSideMenuPanDirectionNone && recognizer.state == UIGestureRecognizerStateEnded) {
        [self setMenuState:MFSideMenuStateClosed];
    }
}

- (void) handleRightPan:(UIPanGestureRecognizer *)recognizer {
    if(!self.leftMenuViewController && self.menuState == MFSideMenuStateClosed) return;
    
    UIView *view = [self.centerViewController view];
    
    CGPoint translatedPoint = [recognizer translationInView:view];
    CGPoint adjustedOrigin = CGPointZero;
    if (self.menuState == MFSideMenuStateRightMenuOpen)
        adjustedOrigin.x = -self.rightMenuWidth;
    else if (self.menuState == MFSideMenuStateLeftMenuOpen)
        adjustedOrigin.x = self.leftMenuWidth;
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
                [self setMenuState:MFSideMenuStateClosed];
            }
        } else {
            BOOL hideMenu = (finalX > adjustedOrigin.x);
            if(hideMenu) {
                self.panGestureVelocity = velocity.x;
                [self setMenuState:MFSideMenuStateClosed];
            } else {
                self.panGestureVelocity = 0;
                [self setMenuState:MFSideMenuStateRightMenuOpen];
            }
        }
    } else {
        [self setControllerOffset:translatedPoint.x];
    }
    
    if (translatedPoint.x == 0)
        self.panDirection = MFSideMenuPanDirectionNone;
}

- (void) handleLeftPan:(UIPanGestureRecognizer *)recognizer {
    if(!self.rightMenuViewController && self.menuState == MFSideMenuStateClosed) return;
    
    UIView *view = [self.centerViewController view];
    
    CGPoint translatedPoint = [recognizer translationInView:view];
    CGPoint adjustedOrigin = panGestureOrigin;
    if (self.menuState == MFSideMenuStateRightMenuOpen)
        adjustedOrigin.x = -self.rightMenuWidth;
    else if (self.menuState == MFSideMenuStateLeftMenuOpen)
        adjustedOrigin.x = self.leftMenuWidth;
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
    
    [self setControllerOffset:translatedPoint.x];
    
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
                [self setMenuState:MFSideMenuStateClosed];
            }
        } else {
            BOOL hideMenu = (finalX < adjustedOrigin.x);
            if(hideMenu) {
                self.panGestureVelocity = velocity.x;
                [self setMenuState:MFSideMenuStateClosed];
            } else {
                self.panGestureVelocity = 0;
                [self setMenuState:MFSideMenuStateLeftMenuOpen];
            }
        }
	} else {
        [self setControllerOffset:translatedPoint.x];
    }
    
    if (translatedPoint.x == 0)
        self.panDirection = MFSideMenuPanDirectionNone;
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

@end


#pragma mark - UIView + Screenshot

@implementation UIView (Screenshot)

- (UIImage*)screenshot {
    UIGraphicsBeginImageContext(self.bounds.size);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // hack, helps w/ our colors when blurring
    NSData *imageData = UIImageJPEGRepresentation(image, 1); // convert to jpeg
    image = [UIImage imageWithData:imageData];
    
    return image;
}

@end


#pragma mark - UIScrollView + Screenshot

@implementation UIScrollView (Screenshot)

-(UIImage *)screenshot {    
    // Freeze scrollview
    CGPoint offset = self.contentOffset;
    [self setContentOffset:offset animated:NO];
    
    CGSize pageSize = self.bounds.size;
    UIGraphicsBeginImageContext(pageSize);
    
    CGContextRef resizedContext = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(resizedContext, -self.contentOffset.x, -self.contentOffset.y);
    [self.layer renderInContext:resizedContext];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    // hack, helps w/ our colors when blurring
    NSData *imageData = UIImageJPEGRepresentation(image, 1); // convert to jpeg
    image = [UIImage imageWithData:imageData];
    
    return image;
}

@end