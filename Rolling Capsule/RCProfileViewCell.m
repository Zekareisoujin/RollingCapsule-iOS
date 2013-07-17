//
//  RCProfileViewCell.m
//  memcap
//
//  Created by Nguyen Phi Long Louis on 7/07/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCProfileViewCell.h"
#import "RCResourceCache.h"
#import "RCUser.h"
#import "RCConstants.h"
#import "RCAmazonS3Helper.h"

@implementation RCProfileViewCell

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

- (void)getPostContentImageFromInternet:(RCUser *) user withPostContent:(RCPost *) post usingCollection:(NSMutableDictionary*)postCache completion:(void (^)(void))callback {
    
    [self.imageView.layer setCornerRadius:10.0];
    [self.imageView setClipsToBounds:YES];
    
    [self.layer setMasksToBounds:NO];
    [self.layer setShadowColor:[UIColor whiteColor].CGColor];
    [self.layer setShadowRadius:5.0];
    [self.layer setShadowOffset:CGSizeZero];
    [self.layer setShadowPath:[[UIBezierPath
                                bezierPathWithRect:self.bounds] CGPath]];
    
    if ([post.fileUrl isKindOfClass:[NSNull class]]) return;
    RCResourceCache *cache = [RCResourceCache centralCache];
    NSString *key = [NSString stringWithFormat:@"%@/%d-thumbnail", RCPostsResource, post.postID];
    dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
    dispatch_async(queue, ^{
        RCUser *owner = [[RCUser alloc] init];
        owner.userID = post.userID;
        owner.email = post.authorEmail;
        owner.name = post.authorName;
        UIImage* cachedImg = (UIImage*)[cache getResourceForKey:key usingQuery:^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            UIImage *image = [RCAmazonS3Helper getUserMediaImage:owner withLoggedinUserID:user.userID withImageUrl:post.thumbnailUrl];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            NSLog(@"downloading images");
            /*if (image == nil)
                image = [UIImage imageNamed:@"default_avatar.jpg"];*/
            return image;
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (cachedImg != nil)
                [_imageView setImage:cachedImg];
            callback();
        });
    });
}

- (void) setHighlightShadow: (BOOL)highlight {
    [self.layer setShadowOpacity:highlight?1.0:0.0];
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
