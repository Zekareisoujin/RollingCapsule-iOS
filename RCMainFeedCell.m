//
//  RCMainFeedCell.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 18/6/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "RCMainFeedCell.h"
#import "RCResourceCache.h"
#import "RCConstants.h"
#import "RCAmazonS3Helper.h"

@implementation RCMainFeedCell

UIView *dimMask;

+ (NSString*) cellIdentifier {
    return @"RCMainFeedCell";
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.borderColor = [UIColor blackColor].CGColor;
        self.layer.borderWidth = 2.0;
        self.layer.cornerRadius = 5.0;
    }
    return self;

}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)getPostContentImageFromInternet:(RCUser *) user withPostContent:(RCPost *) post usingCollection:(NSMutableDictionary*)postCache completion:(void (^)(void))callback {
    self.imageView.layer.borderColor = [UIColor colorWithRed:52.0/255.0 green:178.0/255.0 blue:167.0/255.0 alpha:1.0].CGColor;
    self.imageView.layer.borderWidth = 2.0;
    self.imageView.layer.cornerRadius = 5.0;
    self.imageView.clipsToBounds = YES;
    [self.layer setMasksToBounds:NO];
    [self.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.layer setShadowRadius:5.0];
    [self.layer setShadowOffset:CGSizeMake(2,2)];
    [self.layer setShadowOpacity:0.5];
    [self setBackgroundColor:[UIColor clearColor]];
    
    dimMask = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _imageView.frame.size.width, _imageView.frame.size.height)];
    [dimMask setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5]];
    [_imageView addSubview:dimMask];
    dimMask.hidden = YES;
    
    if ([post.fileUrl isKindOfClass:[NSNull class]]) return;
    RCResourceCache *cache = [RCResourceCache centralCache];
    NSString *key = [NSString stringWithFormat:@"%@/%d", RCPostsResource, post.postID];
    dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
    dispatch_async(queue, ^{
        RCUser *owner = [[RCUser alloc] init];
        owner.userID = post.userID;
        owner.email = post.authorEmail;
        owner.name = post.authorName;
        UIImage* cachedImg = (UIImage*)[cache getResourceForKey:key usingQuery:^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            UIImage *image = [RCAmazonS3Helper getUserMediaImage:owner withLoggedinUserID:user.userID withImageUrl:post.fileUrl];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            NSLog(@"downloading images");
            if (image == nil)
                image = [UIImage imageNamed:@"default_avatar.jpg"];
            return image;
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (cachedImg != nil)
                [_imageView setImage:cachedImg];
            callback();
        });
    });
}

- (void) enableDimMask:(bool)enable {
    dimMask.hidden = !enable;
}

@end
