//
//  UIViewController+MFSideMenu.m
//
//  Created by Michael Frederick on 3/18/12.
//

#import "UIViewController+MFSideMenu.h"
#import "MFSideMenuManager.h"
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

@interface UIViewController (MFSideMenuPrivate)
- (void) mf_toggleSideMenu:(BOOL)hidden animationDuration:(NSTimeInterval)duration;
@end

@implementation UIViewController (MFSideMenu)

static char menuStateKey;
static char velocityKey;

- (void) mf_toggleSideMenuPressed:(id)sender {
    if(self.navigationController.mf_menuState == MFSideMenuStateVisible) {
        self.navigationController.mf_menuState = MFSideMenuStateHidden;
    } else {
        self.navigationController.mf_menuState = MFSideMenuStateVisible;
    }
}

- (void) mf_backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (UIBarButtonItem *) mf_menuBarButtonItem {
    return [[[UIBarButtonItem alloc]
             initWithImage:[UIImage imageNamed:@"menu-icon.png"] style:UIBarButtonItemStyleBordered
             target:self action:@selector(mf_toggleSideMenuPressed:)] autorelease];
}

- (UIBarButtonItem *) mf_backBarButtonItem {
    return [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back-arrow"]
                                             style:UIBarButtonItemStyleBordered target:self
                                            action:@selector(mf_backButtonPressed:)] autorelease];
}

- (void) mf_setupSideMenuBarButtonItem {
    if([MFSideMenuManager sharedManager].menuLocation == MFSideMenuLocationRight
       && [MFSideMenuManager menuButtonEnabled]) {
        self.navigationItem.rightBarButtonItem = [self mf_menuBarButtonItem];
        return;
    }
    
    if(self.navigationController.mf_menuState == MFSideMenuStateVisible ||
       [[self.navigationController.viewControllers objectAtIndex:0] isEqual:self]) {
        if([MFSideMenuManager menuButtonEnabled]) {
            self.navigationItem.leftBarButtonItem = [self mf_menuBarButtonItem];
        }
    } else {
        if([MFSideMenuManager sharedManager].menuLocation == MFSideMenuLocationLeft) {
            if([MFSideMenuManager backButtonEnabled]) {
                self.navigationItem.leftBarButtonItem = [self mf_backBarButtonItem];
            }
        }
    }
}

- (void) setMf_menuState:(MFSideMenuState)menuState {
    [self setMf_menuState:menuState animationDuration:kMenuAnimationDuration];
}

- (void) setMf_menuState:(MFSideMenuState)menuState animationDuration:(NSTimeInterval)duration {
    if(![self isKindOfClass:[UINavigationController class]]) {
        [self.navigationController setMf_menuState:menuState animationDuration:duration];
        return;
    }
    
    MFSideMenuState currentState = self.mf_menuState;
    
    objc_setAssociatedObject(self, &menuStateKey, [NSNumber numberWithInt:menuState], OBJC_ASSOCIATION_RETAIN);
    
    switch (currentState) {
        case MFSideMenuStateHidden:
            if (menuState == MFSideMenuStateVisible) {
                [self mf_toggleSideMenu:NO animationDuration:duration];
            }
            break;
        case MFSideMenuStateVisible:
            if (menuState == MFSideMenuStateHidden) {
                [self mf_toggleSideMenu:YES animationDuration:duration];
            }
            break;
        default:
            break;
    }
}

- (MFSideMenuState) mf_menuState {
    if(![self isKindOfClass:[UINavigationController class]]) {
        return self.navigationController.mf_menuState;
    }
    
    return (MFSideMenuState)[objc_getAssociatedObject(self, &menuStateKey) intValue];
}

- (void) setMf_velocity:(CGFloat)velocity {
    objc_setAssociatedObject(self, &velocityKey, [NSNumber numberWithFloat:velocity], OBJC_ASSOCIATION_RETAIN);
}

- (CGFloat) mf_velocity {
    return (CGFloat)[objc_getAssociatedObject(self, &velocityKey) floatValue];
}

- (void) mf_animationFinished:(NSString *)animationID finished:(BOOL)finished context:(void *)context {
    if ([animationID isEqualToString:@"toggleSideMenu"]) {
        if([self isKindOfClass:[UINavigationController class]]) {
            UINavigationController *controller = (UINavigationController *)self;
            [controller.visibleViewController mf_setupSideMenuBarButtonItem];
            
            // disable user interaction on the current view controller is the menu is visible
            controller.visibleViewController.view.userInteractionEnabled = (self.mf_menuState == MFSideMenuStateHidden);
        }
    }
}

@end


@implementation UIViewController (MFSideMenuPrivate)

- (CGFloat) mf_xAdjustedForInterfaceOrientation:(CGPoint)point {
    if(UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        return ABS(point.x);
    } else {
        return ABS(point.y);
    }
}

- (void) mf_toggleSideMenu:(BOOL)hidden animationDuration:(NSTimeInterval)duration {
    if(![self isKindOfClass:[UINavigationController class]]) return;
    
    CGFloat x = [self mf_xAdjustedForInterfaceOrientation:self.view.frame.origin];
    CGFloat navigationControllerXPosition = [MFSideMenuManager menuVisibleNavigationControllerXPosition];
    CGFloat animationPositionDelta = (hidden) ? x : (navigationControllerXPosition  - x);
    
    if(ABS(self.mf_velocity) > 1.0) {
        // try to continue the animation at the speed the user was swiping
        duration = animationPositionDelta / ABS(self.mf_velocity);
    } else {
        // no swipe was used, user tapped the bar button item
        CGFloat animationDurationPerPixel = kMenuAnimationDuration / navigationControllerXPosition;
        duration = animationDurationPerPixel * animationPositionDelta;
    }
    
    if(duration > kMenuAnimationMaxDuration) duration = kMenuAnimationMaxDuration;
    
    [UIView beginAnimations:@"toggleSideMenu" context:NULL];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(mf_animationFinished:finished:context:)];
    [UIView setAnimationDuration:duration];
    
    CGRect frame = self.view.frame;
    frame.origin = CGPointZero;
    if (!hidden) {
        switch (self.interfaceOrientation) 
        {
            case UIInterfaceOrientationPortrait:
                frame.origin.x = navigationControllerXPosition;
                break;
                
            case UIInterfaceOrientationPortraitUpsideDown:
                frame.origin.x = -1*navigationControllerXPosition;
                break;
                
            case UIInterfaceOrientationLandscapeLeft:
                frame.origin.y = -1*navigationControllerXPosition;
                break;
                
            case UIInterfaceOrientationLandscapeRight:
                frame.origin.y = navigationControllerXPosition;
                break;
        } 
    }
    self.view.frame = frame;
        
    [UIView commitAnimations];
}

@end 
