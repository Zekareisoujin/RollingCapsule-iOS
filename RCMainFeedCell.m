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
#import "RCConnectionManager.h"

@implementation RCMainFeedCell

@synthesize dimMask = _dimMask;
@synthesize cellState = _cellState;
@synthesize currentFileUrl = _currentFileUrl;

+ (UIImage*) loadingImage {
    static UIImage* staticRCLoadingImage = nil;
    if (staticRCLoadingImage == nil) {
        staticRCLoadingImage = [UIImage imageNamed:@"loading.gif"];
    }
return staticRCLoadingImage;
}
+ (NSString*) cellIdentifier {
    return @"RCMainFeedCell";
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self prepareForReuse];
    }
    return self;

}

- (void) awakeFromNib {
    [super awakeFromNib];
    _dimMask = [[UIView alloc] init];
    [_dimMask setBackgroundColor:[UIColor blackColor]];
    _dimMask.alpha = 0.7;
    [self prepareForReuse];
}

- (void) prepareForReuse {
    [_dimMask removeFromSuperview];
        self.imageView.layer.borderColor = [UIColor colorWithRed:RCAppThemeColorRed green:RCAppThemeColorGreen blue:RCAppThemeColorBlue alpha:1.0].CGColor;
    self.imageView.layer.borderWidth = 2.0;
    self.imageView.layer.cornerRadius = 5.0;
    self.imageView.clipsToBounds = YES;
    [self.layer setMasksToBounds:NO];
    [self.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.layer setShadowRadius:5.0];
    [self.layer setShadowOffset:CGSizeMake(2,2)];
    [self.layer setShadowOpacity:0.5];
    [_imageView setImage:[RCMainFeedCell loadingImage]];
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
    [self.layer setShadowPath:[[UIBezierPath
                                bezierPathWithRect:self.bounds] CGPath]];
    if ([post.fileUrl isKindOfClass:[NSNull class]]) return;
    RCResourceCache *cache = [RCResourceCache centralCache];
    NSString *key = [NSString stringWithFormat:@"%@/%@", RCMediaResource, post.thumbnailUrl];
    dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
    dispatch_async(queue, ^{
        RCUser *owner = [[RCUser alloc] init];
        owner.userID = post.userID;
        owner.email = post.authorEmail;
        owner.name = post.authorName;
        UIImage* cachedImg = nil;
        
        cachedImg = [cache getResourceForKey:key usingQuery:^{
            UIImage *image = [RCAmazonS3Helper getUserMediaImage:owner withLoggedinUserID:user.userID withImageUrl:post.thumbnailUrl];
            return image;
            }];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.imageView.image == [RCMainFeedCell loadingImage]) {
                if (cachedImg == nil)
                    [_imageView setImage:[UIImage imageNamed:@"default_avatar.jpg"]];
                else
                    [_imageView setImage:cachedImg];
            }
            callback();
        });
    });
    
    /*[RCUser getUserWithIDAsync:post.userID completionHandler:^(RCUser* owner){
        UIImage* cachedImg = (UIImage*)[cache getResourceForKey:key usingQuery:^{
            UIImage *image = [RCAmazonS3Helper getUserMediaImage:owner withLoggedinUserID:user.userID withImageUrl:post.thumbnailUrl];
            NSLog(@"downloading images");
            return image;
        }];
        //dispatch_async(dispatch_get_main_queue(), ^{
            if (cachedImg != nil)
                [_imageView setImage:cachedImg];
            else
                NSLog(@"nil image");
            callback();
        //});
    }];*/
}

-(void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self setNeedsDisplay];
    //UICollectionView* collectionView;
    //[collectionView indexPathForCell:self];
}

- (void) changeCellState:(int)newState {
    int backup = _cellState;
    _cellState = newState;
    switch (newState) {
        case RCCellStateDimmed:
            _dimMask.frame = CGRectMake(0,0,self.frame.size.width,self.frame.size.height);
            [self.imageView addSubview:_dimMask];
            _dimMask.frame = CGRectMake(0,0,self.frame.size.width,self.frame.size.height);
            break;
        case RCCellStateNormal:
            [_dimMask removeFromSuperview];
            [self.layer setMasksToBounds:NO];
            [self.layer setShadowColor:[UIColor blackColor].CGColor];
            [self.layer setShadowRadius:5.0];
            [self.layer setShadowOffset:CGSizeMake(2,2)];
            [self.layer setShadowOpacity:0.5];
            break;
        case RCCellStateFloat:
            [_dimMask removeFromSuperview];
            [self.layer setShadowColor:[UIColor blackColor].CGColor];
            [self.layer setShadowRadius:5.0];
            [self.layer setShadowOffset:CGSizeMake(5,5)];
            [self.layer setShadowOpacity:0.8];
            [self setBackgroundColor:[UIColor clearColor]];
            break;
        default:
            _cellState = backup;
            NSLog(@"Main-feed-cell: invalid state change");
            break;
    }
}

@end
