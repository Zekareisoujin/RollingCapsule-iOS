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
#import "RCNotification.h"
#import "UIImage+animatedGIF.h"

@implementation RCMainFeedCell {
    int _currentPostID;
}

@synthesize dimMask = _dimMask;
@synthesize cellState = _cellState;
@synthesize currentFileUrl = _currentFileUrl;

+ (UIImage*) loadingImage {
//    static UIImage* staticRCLoadingImage = nil;
//    if (staticRCLoadingImage == nil) {
//        //staticRCLoadingImage = [UIImage imageNamed:@"loading2.gif"];
//        
//        NSURL *url = [[NSBundle mainBundle] URLForResource:@"loading2" withExtension:@"gif"];
//        staticRCLoadingImage = [UIImage animatedImageWithAnimatedGIFURL:url];
//    }
//    return staticRCLoadingImage;
    return [UIImage standardLoadingImage];
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

- (void) prepareCellAppearance {
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

- (void)initCellAppearanceForPost:(RCPost *) post {
    [self prepareCellAppearance];
    _currentPostID = post.postID;
    [self.layer setShadowPath:[[UIBezierPath
                                bezierPathWithRect:self.bounds] CGPath]];
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
    } else
        [self.lblNotification setHidden:YES];
}

- (void) updateUIWithPost:(RCPost*)post {
    if (post.postID == _currentPostID)
        [_imageView setImage:post.thumbnailImage];
}

-(void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self setNeedsDisplay];
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
