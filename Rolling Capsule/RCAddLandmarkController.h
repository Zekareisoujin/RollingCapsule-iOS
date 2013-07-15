//
//  RCAddLandmarkController.h
//  memcap
//
//  Created by Nguyen Phi Long Louis on 15/07/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewController+RCCustomBackButtonViewController.h"

@interface RCAddLandmarkController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet UITextField *txtFieldName;
@property (weak, nonatomic) IBOutlet UITextField *txtFieldDescription;
@property (weak, nonatomic) IBOutlet UIButton *btnCategory;

@property (strong, nonatomic) UICollectionView *tblViewLandmark;
@property (strong, nonatomic) UIView *viewLandmark;

- (IBAction)txtFieldCategoryAction:(id)sender;
- (IBAction)actionBackgroundTap:(id)sender;
@end
