//
//  FeedPostPreview.m
//  Rolling Capsule
//
//  Created by Nguyen Phi Long Louis on 28/05/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCFeedPostPreview.h"
#import "RCConstants.h"
#import "RCUtilities.h"
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

- (void)getAvatarImageFromInternet:(RCUser *) user withLoggedInUserID:(int)loggedInUserID usingCollection:(NSMutableDictionary*)userCache {
    UIImage *cachedImg = [userCache objectForKey:[NSNumber numberWithInt:loggedInUserID]];
    if (cachedImg != nil) {
        [_imgUserAvatar setImage: cachedImg];
    }else {
        dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
        dispatch_async(queue, ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            UIImage *image = [RCAmazonS3Helper getAvatarImage:user withLoggedinUserID:loggedInUserID];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            if (image != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_imgUserAvatar setImage:image];
                    if (image != nil)
                        [userCache setObject:image forKey:[NSNumber numberWithInt:loggedInUserID]];
                });
            }
        });
    }
}

- (void)getPostContentImageFromInternet:(RCUser *) user withPostContent:(RCPost *) post usingCollection:(NSMutableDictionary*)postCache {
    UIImage *cachedImg = [postCache objectForKey:[NSNumber numberWithInt:post.postID]];
    if (cachedImg != nil) {
        [_imgPostContent setImage: cachedImg];
    }else {
        dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
        dispatch_async(queue, ^{
            if ((NSNull *)post.fileUrl != [NSNull null]) {
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
                UIImage *image = [RCAmazonS3Helper getUserMediaImage:[[RCUser alloc] init] withLoggedinUserID:user.userID withImageUrl:post.fileUrl];
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_imgPostContent setImage:image];
                    if (image != nil)
                        [postCache setObject:image forKey:[NSNumber numberWithInt:post.postID]];
                });
            }
        });
    }
}

@end
