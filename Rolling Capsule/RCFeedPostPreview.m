//
//  FeedPostPreview.m
//  Rolling Capsule
//
//  Created by Nguyen Phi Long Louis on 28/05/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCFeedPostPreview.h"
#import "Constants.h"
#import "Util.h"
#import "RCAmazonS3Helper.h"
#import "RCPost.h"

@implementation RCFeedPostPreview

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

- (void)getAvatarImageFromInternet:(RCUser *) user withLoggedInUserID:(int)loggedInUserID {
    dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
    dispatch_async(queue, ^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        UIImage *image = [RCAmazonS3Helper getAvatarImage:user withLoggedinUserID:loggedInUserID];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if (image != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_imgUserAvatar setImage:image];
            });
        }
    });
}

- (void)getPostContentImageFromInternet:(RCUser *) user withPostContent:(RCPost *) post {
    dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
    dispatch_async(queue, ^{
        if ((NSNull *)post.fileUrl != [NSNull null]) {
            UIImage *image = [RCAmazonS3Helper getUserMediaImage:[[RCUser alloc] init] withLoggedinUserID:user.userID withImageUrl:post.fileUrl];
            //UIImage *image = [UIImage imageWithData: [NSData dataWithContentsOfURL:imageUrl]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [_imgPostContent setImage:image];
            });
        }
    });
}

@end
