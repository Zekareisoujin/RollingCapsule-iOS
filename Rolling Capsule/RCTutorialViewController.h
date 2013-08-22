//
//  RCTutorialViewController.h
//  memcap
//
//  Created by Trinh Tuan Phuong on 16/8/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>

#define NUMBER_OF_TUTORIAL_PAGE 6

@interface RCTutorialViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imgViewBackground;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
- (IBAction)btnStartMemcapTouchUpInside:(id)sender;

@end
