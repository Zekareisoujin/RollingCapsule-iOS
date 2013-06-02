//
//  FeedPostPreview.h
//  Rolling Capsule
//
//  Created by Nguyen Phi Long Louis on 28/05/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RCFeedPostPreview : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *lblPostContent;
@property (weak, nonatomic) IBOutlet UILabel *lblUserProfileName;
@property (weak, nonatomic) IBOutlet UIImageView *imgUserAvatar;


@end
