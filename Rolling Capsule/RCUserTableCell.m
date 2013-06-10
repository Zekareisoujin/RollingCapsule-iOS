//
//  RCFriendListTableCell.m
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 28/5/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCUserTableCell.h"
#import "RCConstants.h"
#import "RCAmazonS3Helper.h"

@implementation RCUserTableCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void) populateCellData:(RCUser *) user withLoggedInUserID:(int)loggedInUserID completion:(void (^)(void))callback {
    _lblEmail.text = user.email;
    _lblName.text = user.name;
    dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
    dispatch_async(queue, ^{
        UIImage *image = [RCAmazonS3Helper getAvatarImage:user withLoggedinUserID:loggedInUserID];
        callback();
        if (image != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_imgViewAvatar setImage:image];
            });
        }
    });
}

+ (RCUserTableCell *) getFriendListTableCell:(UITableView *)tableView {
    static NSString *CellIdentifier = @"RCUserTableCell";
    RCUserTableCell *cell;
    
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:CellIdentifier owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    return cell;
}

+ (CGFloat) cellHeight {
    return 78;
}

@end
