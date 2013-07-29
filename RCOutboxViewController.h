//
//  RCOutboxViewController.h
//  memcap
//
//  Created by Trinh Tuan Phuong on 26/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RCOutboxViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tblViewUploadTasks;
@property (weak, nonatomic) IBOutlet UILabel *lblUsername;
@property (weak, nonatomic) IBOutlet UIImageView *imgViewUserAvatar;
- (IBAction)btnCleanupTouchUpInside:(id)sender;
@property (nonatomic, strong) NSMutableArray* uploadTasks;
@end
