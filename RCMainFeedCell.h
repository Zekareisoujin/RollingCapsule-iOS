//
//  RCMainFeedCell.h
//  memcap
//
//  Created by Trinh Tuan Phuong on 18/6/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCPost.h"
#import "RCUser.h"

@interface RCMainFeedCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

+ (NSString*) cellIdentifier;
- (void)getPostContentImageFromInternet:(RCUser *) user withPostContent:(RCPost *) post usingCollection:(NSMutableDictionary*)postCache completion:(void (^)(void))callback;
- (void) enableDimMask:(bool) enable;
@end
