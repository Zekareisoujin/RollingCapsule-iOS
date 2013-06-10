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
#import "RCResourceCache.h"

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
    
    RCResourceCache *cache = [RCResourceCache centralCache];
    NSString *key = [NSString stringWithFormat:@"%@/%d", RCUsersResource, user.userID];
    dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
    dispatch_async(queue, ^{
        UIImage* cachedImg = (UIImage*)[cache getResourceForKey:key usingQuery:^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            UIImage *image = [RCAmazonS3Helper getAvatarImage:user withLoggedinUserID:loggedInUserID];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            return image;
        }];
        if (cachedImg != nil)
            dispatch_async(dispatch_get_main_queue(), ^{
                [_imgViewAvatar setImage:cachedImg];
            });
    });
}

@end
