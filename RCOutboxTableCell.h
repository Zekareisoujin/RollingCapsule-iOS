//
//  RCOutboxTableCell.h
//  memcap
//
//  Created by Nguyen Phi Long Louis on 27/07/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCUploadTask.h"
@interface RCOutboxTableCell : UITableViewCell

+ (CGFloat) cellHeight;
@property (weak, nonatomic) IBOutlet UIImageView *imgViewThumbnail;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *viewActivityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *btnDeleteTask;
@property (weak, nonatomic) IBOutlet UIImageView *imgViewAction;
@property (weak, nonatomic) IBOutlet UIButton *btnTaskAction;
- (IBAction)btnTaskActionTouchUpInside:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *lblSubject;
- (IBAction)btnDeleteTaskTouchUpInside:(id)sender;
+ (RCOutboxTableCell*) createOutboxTableCell: (UITableView*) tableView;
- (void) setupButtonControl:(RCUploadTask*) task;
@end
