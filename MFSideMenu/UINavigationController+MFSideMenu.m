//
//  UINavigationController+MFSideMenu.m
//  MFSideMenuDemo
//
//  Created by Michael Frederick on 10/24/12.
//  Copyright (c) 2012 University of Wisconsin - Madison. All rights reserved.
//

#import "UINavigationController+MFSideMenu.h"
#import "MFSideMenu.h"
#import <objc/runtime.h>

@implementation UINavigationController (MFSideMenu)

static char menuKey;

- (void)setSideMenu:(MFSideMenu *)sideMenu {
    objc_setAssociatedObject(self, &menuKey, sideMenu, OBJC_ASSOCIATION_RETAIN);
}

- (MFSideMenu *)sideMenu {
    return (MFSideMenu *)objc_getAssociatedObject(self, &menuKey);
}

- (void) MFSideMenu_viewDidAppear:(BOOL)animated {
    [self MFSideMenu_viewDidAppear:animated];
    
    [self.sideMenu performSelector:@selector(navigationControllerDidAppear)];
}

- (void) MFSideMenu_viewDidDisappear:(BOOL)animated {
    [self MFSideMenu_viewDidDisappear:animated];
    
    [self.sideMenu performSelector:@selector(navigationControllerDidDisappear)];
}

+ (void)swizzleViewMethods {
    Swizzle([UINavigationController class], @selector(viewDidAppear:), @selector(MFSideMenu_viewDidAppear:));
    Swizzle([UINavigationController class], @selector(viewDidDisappear:), @selector(MFSideMenu_viewDidDisappear:));
}

void Swizzle(Class c, SEL orig, SEL new)
{
    Method origMethod = class_getInstanceMethod(c, orig);
    Method newMethod = class_getInstanceMethod(c, new);
    if(class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
        class_replaceMethod(c, new, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    else
        method_exchangeImplementations(origMethod, newMethod);
}

@end
