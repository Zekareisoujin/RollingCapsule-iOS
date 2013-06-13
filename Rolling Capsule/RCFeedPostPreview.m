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
#import "RCResourceCache.h"

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
                [_imgUserAvatar setImage:cachedImg];
            });
    });

}

- (void)getPostContentImageFromInternet:(RCUser *) user withPostContent:(RCPost *) post usingCollection:(NSMutableDictionary*)postCache {
    if ([post.fileUrl isKindOfClass:[NSNull class]]) return;
    RCResourceCache *cache = [RCResourceCache centralCache];
    NSString *key = [NSString stringWithFormat:@"%@/%d", RCPostsResource, post.postID];
    dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
    dispatch_async(queue, ^{
        UIImage* cachedImg = (UIImage*)[cache getResourceForKey:key usingQuery:^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            UIImage *image = [RCAmazonS3Helper getUserMediaImage:[[RCUser alloc] init] withLoggedinUserID:user.userID withImageUrl:post.fileUrl];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            return image;
        }];
        if (cachedImg != nil)
            dispatch_async(dispatch_get_main_queue(), ^{
                [_imgPostContent setImage:cachedImg];
            });
    });
}

@end
