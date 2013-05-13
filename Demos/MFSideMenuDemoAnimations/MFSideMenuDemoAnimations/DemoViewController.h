//
//  DemoViewController.h
//  MFSideMenuDemoStoryboard
//
//  Created by Michael Frederick on 4/9/13.
//  Copyright (c) 2013 Michael Frederick. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DemoViewController : UIViewController

@property (nonatomic, strong) IBOutlet UISegmentedControl *animationTypeSegmentedControl;
@property (nonatomic, strong) IBOutlet UISlider *animationExaggerationSlider;
@property (nonatomic, strong) IBOutlet UILabel *exaggerationAmountLabel;
@property (nonatomic, strong) IBOutlet UIView *exaggerationWrapperView;

- (IBAction)showLeftMenuPressed:(id)sender;
- (IBAction)showRightMenuPressed:(id)sender;

@end
