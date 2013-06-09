//
//  RCFriendListTableCell.m
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 28/5/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCFriendListTableCell.h"
#import "RCConstants.h"
#import "RCAmazonS3Helper.h"

@implementation RCFriendListTableCell

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

-(void) getAvatarImageFromInternet:(RCUser *) user withLoggedInUserID:(int)loggedInUserID {
    dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
    dispatch_async(queue, ^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        UIImage *image = [RCAmazonS3Helper getAvatarImage:user withLoggedinUserID:loggedInUserID];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if (image != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_imgViewAvatar setImage:image];
            });
        }
    });
}

@end
