//
//  RCOutboxTableCell.m
//  memcap
//
//  Created by Nguyen Phi Long Louis on 27/07/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCOutboxTableCell.h"
#import "RCOperationsManager.h"
#import "UIImage+animatedGIF.h"

@implementation RCOutboxTableCell {
    RCUploadTask* associatedUploadTask;
    BOOL pause;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        pause = NO;
    }
    return self;
}

+ (CGFloat) cellHeight {
    return 60;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) setupButtonControl:(RCUploadTask*) task {
    associatedUploadTask = task;
}

- (IBAction)btnDeleteTaskTouchUpInside:(id)sender {
    RCUploadManager *defaultUM = [RCOperationsManager defaultUploadManager];
    [defaultUM cancelNewPostOperation:associatedUploadTask];
}

+ (RCOutboxTableCell*) createOutboxTableCell: (UITableView*) tableView {
    RCOutboxTableCell *cell;
    static NSString *cellIdentifier = @"RCOutboxTableCell";
    
    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:cellIdentifier owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    return cell;
}

- (IBAction)btnTaskActionTouchUpInside:(id)sender {
    if (pause) {
        pause = NO;
        RCUploadManager *defaultUM = [RCOperationsManager defaultUploadManager];
        [defaultUM unpauseNewPostOperation:associatedUploadTask];
        [_btnTaskAction setImage:[UIImage imageNamed:@"outboxUploading.gif"] forState:UIControlStateNormal];
    } else {
        pause = YES;
        RCUploadManager *defaultUM = [RCOperationsManager defaultUploadManager];
        [defaultUM pauseNewPostOperation:associatedUploadTask];
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"outboxUploading" withExtension:@"gif"];
        [_btnTaskAction setImage:[UIImage animatedImageWithAnimatedGIFURL:url] forState:UIControlStateNormal];
    }
}
@end
