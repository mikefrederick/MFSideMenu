//
//  MFSideMenuManager.m
//
//  Created by Michael Frederick on 3/18/12.
//

#import "MFSideMenuManager.h"
#import "UIViewController+MFSideMenu.h"
#import <QuartzCore/QuartzCore.h>

#define kMenuShadowWidth 10.0

@implementation MFSideMenuManager

@synthesize navigationController;
@synthesize sideMenuController;
@synthesize menuSide;
@synthesize options;

+ (MFSideMenuManager *) sharedManager {
    static dispatch_once_t once;
    static MFSideMenuManager *sharedManager;
    dispatch_once(&once, ^ { sharedManager = [[MFSideMenuManager alloc] init]; });
    return sharedManager;
}

+ (void) configureWithNavigationController:(UINavigationController *)controller 
                        sideMenuController:(id)menuController {
    MenuOptions options = MenuButtonEnabled|BackButtonEnabled;
    
    [MFSideMenuManager configureWithNavigationController:controller
                                      sideMenuController:menuController
                                                menuSide:MenuLeftHandSide
                                                 options:options];
}

+ (void) configureWithNavigationController:(UINavigationController *)controller
                        sideMenuController:(id)menuController
                                  menuSide:(MenuSide)side
                                   options:(MenuOptions)options {
    MFSideMenuManager *manager = [MFSideMenuManager sharedManager];
    manager.navigationController = controller;
    manager.sideMenuController = menuController;
    manager.menuSide = side;
    manager.options = options;
    
    [controller setMenuState:MFSideMenuStateHidden];
    
    if(controller.viewControllers && controller.viewControllers.count) {
        // we need to do this b/c the options to show the barButtonItem
        // weren't set yet when viewDidLoad of the topViewController was called
        [controller.topViewController setupSideMenuBarButtonItem];
    }
    
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
    
    [manager orientSideMenuFromStatusBar];
    
    [[NSNotificationCenter defaultCenter] addObserver:manager
                                             selector:@selector(flipViewAccordingToStatusBarOrientation:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    
    if(side == MenuRightHandSide) {
        // on the right hand side the shadowpath doesn't start at 0 so we have to redraw it when the device flips
        [[NSNotificationCenter defaultCenter] addObserver:manager
                                                 selector:@selector(drawNavigationControllerShadowPath)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
    }
    
    
    [manager drawNavigationControllerShadowPath];
    controller.view.layer.shadowOpacity = 0.75f;
    controller.view.layer.shadowRadius = kMenuShadowWidth;
    controller.view.layer.shadowColor = [UIColor blackColor].CGColor;
}

+ (CGFloat) menuVisibleNavigationControllerXPosition {
    return ([MFSideMenuManager sharedManager].menuSide == MenuLeftHandSide) ? kSidebarWidth : -1*kSidebarWidth;
}

+ (BOOL) menuButtonEnabled {
    return (([MFSideMenuManager sharedManager].options & MenuButtonEnabled) == MenuButtonEnabled);
}

+ (BOOL) backButtonEnabled {
    return (([MFSideMenuManager sharedManager].options & BackButtonEnabled) == BackButtonEnabled);
}

- (void) drawNavigationControllerShadowPath {    
    CGRect pathRect = self.navigationController.view.bounds;
    if(self.menuSide == MenuRightHandSide) {
        // draw the shadow on the right hand side of the navigationController
        pathRect.origin.x = pathRect.size.width - kMenuShadowWidth;
    }
    pathRect.size.width = kMenuShadowWidth;
    
    self.navigationController.view.layer.shadowPath = [UIBezierPath bezierPathWithRect:pathRect].CGPath;
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

- (CGFloat) yAdjustedForInterfaceOrientation:(CGPoint)point {
    switch (self.navigationController.interfaceOrientation)
    {
        case UIInterfaceOrientationPortrait:
            return point.y;
            break;
            
        case UIInterfaceOrientationPortraitUpsideDown:
            return -1*point.y;
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
            return -1*point.x;
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            return point.x;
            break;
    }
}

- (CGFloat) xAdjustedForInterfaceOrientation:(CGPoint)point {
    switch (self.navigationController.interfaceOrientation)
    {
        case UIInterfaceOrientationPortrait:
            return point.x;
            break;
            
        case UIInterfaceOrientationPortraitUpsideDown:
            return -1*point.x;
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
            return -1*point.y;
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            return point.y;
            break;
    }
}

- (void) setXAdjustedForInterfaceOrientation:(CGFloat)newX point:(CGPoint)point {
    switch (self.navigationController.interfaceOrientation)
    {
        case UIInterfaceOrientationPortrait:
            point.x = newX;
            break;
            
        case UIInterfaceOrientationPortraitUpsideDown:
            point.x = -1*newX;
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
            point.y = -1*newX;
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            point.y = newX;
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

// this method handles the navigation bar pan event
// and sets the navigation controller's frame as needed
- (void) handleNavigationBarPan:(UIPanGestureRecognizer *)recognizer {    
    UIView *view = self.navigationController.view;
    
	if(recognizer.state == UIGestureRecognizerStateBegan) {
        originalOrigin = view.frame.origin;
	}
    
    CGPoint translatedPoint = [recognizer translationInView:view];
    translatedPoint = CGPointMake([self xAdjustedForInterfaceOrientation:originalOrigin] + translatedPoint.x,
                                  [self yAdjustedForInterfaceOrientation:originalOrigin] + translatedPoint.y);
    
    if(self.menuSide == MenuLeftHandSide) {
        translatedPoint.x = MIN(translatedPoint.x, kSidebarWidth);
        translatedPoint.x = MAX(translatedPoint.x, 0);
    } else {
        translatedPoint.x = MAX(translatedPoint.x, -1*kSidebarWidth);
        translatedPoint.x = MIN(translatedPoint.x, 0);
    }
    
    
    [self setNavigationControllerOffset:translatedPoint.x];

    
	if(recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [recognizer velocityInView:view];
        CGFloat finalX = translatedPoint.x + (.35*velocity.x);
        CGFloat viewWidth = [self widthAdjustedForInterfaceOrientation:view]; 
        
        if(self.navigationController.menuState == MFSideMenuStateHidden) {
            BOOL showMenu = (self.menuSide == MenuLeftHandSide) ? (finalX > viewWidth/2) : (finalX < -1*viewWidth/2);
            if(showMenu) {
                self.navigationController.velocity = velocity.x;
                [self.navigationController setMenuState:MFSideMenuStateVisible];
            } else {
                self.navigationController.velocity = 0;
                [UIView beginAnimations:nil context:NULL];
                [self setNavigationControllerOffset:0];
                [UIView commitAnimations];
            }
        } else if(self.navigationController.menuState == MFSideMenuStateVisible) {
            BOOL hideMenu = (self.menuSide == MenuLeftHandSide) ? (finalX < [self xAdjustedForInterfaceOrientation:originalOrigin]) :
                                                                (finalX > [self xAdjustedForInterfaceOrientation:originalOrigin]);
            if(hideMenu) {
                self.navigationController.velocity = velocity.x;
                [self.navigationController setMenuState:MFSideMenuStateHidden];
            } else {
                self.navigationController.velocity = 0;
                [UIView beginAnimations:nil context:NULL];
                [self setNavigationControllerOffset:[self xAdjustedForInterfaceOrientation:originalOrigin]]; 
                [UIView commitAnimations];
            }
        }
	}
}

- (void) navigationControllerPanned:(id)sender {
    if(self.navigationController.menuState == MFSideMenuStateHidden) return;
    
    [self handleNavigationBarPan:sender];
}

- (void) navigationBarPanned:(id)sender {
    if(self.navigationController.menuState != MFSideMenuStateHidden) return;
    
    [self handleNavigationBarPan:sender];
}


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
            if(self.menuSide == MenuRightHandSide) {
                newFrame.origin.x = -1*newFrame.size.width + kSidebarWidth;
            }
            break;
        case UIInterfaceOrientationLandscapeLeft:
            angle = - M_PI / 2.0f;
            newFrame.origin.x += statusBarSize.width;
            newFrame.size.width -= statusBarSize.width;
            if(self.menuSide == MenuRightHandSide) {
                newFrame.origin.y = -1*newFrame.size.height + kSidebarWidth;
            }
            break;
        case UIInterfaceOrientationLandscapeRight:
            angle = M_PI / 2.0f;
            newFrame.size.width -= statusBarSize.width;
            if(self.menuSide == MenuRightHandSide) {
                newFrame.origin.y = newFrame.size.height - kSidebarWidth;
            }
            break;
        default: // as UIInterfaceOrientationPortrait
            angle = 0.0;
            newFrame.origin.y += statusBarSize.height;
            newFrame.size.height -= statusBarSize.height;
            if(self.menuSide == MenuRightHandSide) {
                newFrame.origin.x = newFrame.size.width - kSidebarWidth;
            }
            break;
    }
    
    self.sideMenuController.view.transform = CGAffineTransformMakeRotation(angle);
    self.sideMenuController.view.frame = newFrame;
}

- (void)flipViewAccordingToStatusBarOrientation:(NSNotification *)notification {
    [self orientSideMenuFromStatusBar];
    
    if(self.navigationController.menuState == MFSideMenuStateVisible) {
        [self.navigationController setMenuState:MFSideMenuStateHidden];
    }
}



@end
