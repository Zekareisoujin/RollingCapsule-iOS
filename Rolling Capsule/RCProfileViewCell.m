//
//  RCProfileViewCell.m
//  memcap
//
//  Created by Nguyen Phi Long Louis on 7/07/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCProfileViewCell.h"
#import "RCResourceCache.h"
#import "RCConstants.h"
#import "RCAmazonS3Helper.h"
#import "RCUser.h"
#import "RCNotification.h"
#import "UIImage+animatedGIF.h"

@implementation RCProfileViewCell {
    int _currentPostID;
}

@synthesize imageView = _imageView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

+ (NSString*) cellIdentifier {
    return @"RCProfileViewCell";
}

- (void)initCellAppearanceForPost:(RCPost *) post {
    _currentPostID = post.postID;
    [self.imageView.layer setCornerRadius:10.0];
    [self.imageView setClipsToBounds:YES];
    [self.imageView setImage:[UIImage standardLoadingImage]];
    
    [self.layer setMasksToBounds:NO];
    [self.layer setShadowColor:[UIColor whiteColor].CGColor];
    [self.layer setShadowRadius:5.0];
    [self.layer setShadowOffset:CGSizeZero];
    [self.layer setShadowPath:[[UIBezierPath
                                bezierPathWithRect:self.bounds] CGPath]];
    
    [self.imageView.layer setBorderColor:[UIColor yellowColor].CGColor];
    
    [self.imageView setImage:[UIImage standardLoadingImage]];
    if ([post.thumbnailUrl isKindOfClass:[NSNull class]]) return;
    _currentPostID = post.postID;
    if (post.thumbnailImage != nil)
        [ self.imageView setImage:post.thumbnailImage];
    else
        [post registerUIUpdateAction:self action:@selector(updateUIWithPost:)];
    NSMutableArray* associatedNotifications = [RCNotification notificationsForResource:[NSString stringWithFormat:@"posts/%d",post.postID]];
    if (associatedNotifications != nil && [associatedNotifications count] > 0) {
        //TODO add animation effect for post with new comments
        [self.lblNotification setHidden:NO];
    } else [self.lblNotification setHidden:YES];
}

- (void) updateUIWithPost:(RCPost*)post {
    if (post.postID == _currentPostID)
        [_imageView setImage:post.thumbnailImage];
}


- (void)getPostContentImageFromInternet:(RCUser *) user withPostContent:(RCPost *) post usingCollection:(NSMutableDictionary*)postCache completion:(void (^)(void))callback {
    
//    _currentPostID = post.postID;
//    [self.imageView.layer setCornerRadius:10.0];
//    [self.imageView setClipsToBounds:YES];
//    [self.imageView setImage:[UIImage standardLoadingImage]];
//    
//    [self.layer setMasksToBounds:NO];
//    [self.layer setShadowColor:[UIColor whiteColor].CGColor];
//    [self.layer setShadowRadius:5.0];
//    [self.layer setShadowOffset:CGSizeZero];
//    [self.layer setShadowPath:[[UIBezierPath
//                                bezierPathWithRect:self.bounds] CGPath]];
//    [self.imageView setImage:[UIImage standardLoadingImage]];
//    if ([post.fileUrl isKindOfClass:[NSNull class]]) return;
//    RCResourceCache *cache = [RCResourceCache centralCache];
//    NSString *key = [NSString stringWithFormat:@"%@/%@", RCMediaResource, post.thumbnailUrl];
//    dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
//    dispatch_async(queue, ^{
////        RCUser *owner = [[RCUser alloc] init];
////        owner.userID = post.userID;
////        owner.email = post.authorEmail;
////        owner.name = post.authorName;
//        [RCUser getUserWithIDAsync:post.userID completionHandler:^(RCUser* owner){
//            UIImage* cachedImg = (UIImage*)[cache getResourceForKey:key usingQuery:^{
//                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
//                UIImage *image = [RCAmazonS3Helper getUserMediaImage:owner withLoggedinUserID:user.userID withImageUrl:post.thumbnailUrl];
//                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
//                NSLog(@"downloading images");
//
//                return image;
//            }];
//            dispatch_async(dispatch_get_main_queue(), ^{
//                if (post.postID == _currentPostID)
//                    [_imageView setImage:cachedImg];
//                callback();
//            });
//        }];
//    });
//    
//
//    /*[RCUser getUserWithIDAsync:post.userID completionHandler:^(RCUser* owner){
//        UIImage* cachedImg = (UIImage*)[cache getResourceForKey:key usingQuery:^{
//            UIImage *image = [RCAmazonS3Helper getUserMediaImage:owner withLoggedinUserID:user.userID withImageUrl:post.thumbnailUrl];
//            NSLog(@"downloading images");
//            return image;
//        }];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if (cachedImg != nil)
//                [_imageView setImage:cachedImg];
//            callback();
//        });
//    }];*/

}

- (void) setHighlightShadow: (BOOL)highlight {
    [self.layer setShadowOpacity:highlight?1.0:0.0];
}

- (void) setShowBorder: (BOOL)show {
    [self.imageView.layer setBorderWidth:(show?2.0:0.0)];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
