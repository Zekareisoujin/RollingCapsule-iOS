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
@property (strong, nonatomic) UIView *dimMask;
@property (assign, nonatomic) int cellState;
@property (nonatomic, strong) NSString* currentFileUrl;
+ (NSString*) cellIdentifier;
- (void)initCellAppearanceForPost:(RCPost *) post;
- (void) changeCellState:(int)newState;
- (void) updateUIWithPost:(RCPost*)post;
@end
