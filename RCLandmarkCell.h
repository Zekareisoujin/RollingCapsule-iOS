//
//  RCLandmarkCell.h
//  memcap
//
//  Created by Trinh Tuan Phuong on 7/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RCLandmarkCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imgViewCategory;
@property (weak, nonatomic) IBOutlet UILabel *lblLandmarkTitle;
+ (NSString*) cellIdentifier;

@end
