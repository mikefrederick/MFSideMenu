//
//  UIViewController+MFSideMenu.m
//
//  Created by Michael Frederick on 3/18/12.
//

#import "UIViewController+MFSideMenu.h"
#import "MFSideMenuManager.h"
#import <objc/runtime.h>

@interface UIViewController (MFSideMenuPrivate)
- (void)toggleSideMenu:(BOOL)hidden;
@end

@implementation UIViewController (MFSideMenu)

static char menuStateKey;

- (void) toggleSideMenuPressed:(id)sender {
    if(self.navigationController.menuState == MFSideMenuStateVisible) {
        [self.navigationController setMenuState:MFSideMenuStateHidden];
    } else {
        [self.navigationController setMenuState:MFSideMenuStateVisible];
    }
}

- (void) backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) setupSideMenuBarButtonItem {
    if(self.navigationController.menuState == MFSideMenuStateVisible || 
       [[self.navigationController.viewControllers objectAtIndex:0] isEqual:self]) {
        self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] 
                                                 initWithImage:[UIImage imageNamed:@"ButtonMenu.png"] style:UIBarButtonItemStyleBordered 
                                                 target:self action:@selector(toggleSideMenuPressed:)] autorelease];
    } else {
        self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back-arrow"] 
                                         style:UIBarButtonItemStyleBordered target:self action:@selector(backButtonPressed:)] autorelease];
    }
}

- (void)setMenuState:(MFSideMenuState)menuState {
    if(![self isKindOfClass:[UINavigationController class]]) {
        self.navigationController.menuState = menuState;
        return;
    }
    
    MFSideMenuState currentState = self.menuState;
    
    objc_setAssociatedObject(self, &menuStateKey, [NSNumber numberWithInt:menuState], OBJC_ASSOCIATION_RETAIN);
    
    switch (currentState) {
        case MFSideMenuStateHidden:
            if (menuState == MFSideMenuStateVisible) {
                [self toggleSideMenu:NO];
            }
            break;
        case MFSideMenuStateVisible:
            if (menuState == MFSideMenuStateHidden) {
                [self toggleSideMenu:YES];
            }
            break;
        default:
            break;
    }
}

- (MFSideMenuState)menuState {
    if(![self isKindOfClass:[UINavigationController class]]) {
        return self.navigationController.menuState;
    }
    
    return (MFSideMenuState)[objc_getAssociatedObject(self, &menuStateKey) intValue];
}

- (void)animationFinished:(NSString *)animationID finished:(BOOL)finished context:(void *)context
{
    if ([animationID isEqualToString:@"toggleSideMenu"])
    {
        if([self isKindOfClass:[UINavigationController class]]) {
            UINavigationController *controller = (UINavigationController *)self;
            [controller.visibleViewController setupSideMenuBarButtonItem];
            
            // disable user interaction on the current view controller
            controller.visibleViewController.view.userInteractionEnabled = (self.menuState == MFSideMenuStateHidden);
        }
    }
}

@end


@implementation UIViewController (MFSideMenuPrivate)

- (void) toggleSideMenu:(BOOL)hidden {
    [UIView beginAnimations:@"toggleSideMenu" context:NULL];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationFinished:finished:context:)];
    [UIView setAnimationDuration:kMenuAnimationDuration];
    
    CGRect frame = self.view.frame;
    if (hidden) {
        frame.origin = CGPointZero;
    } else {
        frame.origin.x = kSidebarWidth;
    }
    
    self.view.frame = frame;
    
    [UIView commitAnimations];
}

@end 
