//
//  FeedPostPreview.h
//  Rolling Capsule
//
//  Created by Nguyen Phi Long Louis on 28/05/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCUser.h"
#import "RCPost.h"

@interface RCPostCommentCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *lblPostContent;
@property (weak, nonatomic) IBOutlet UILabel *lblUserProfileName;
@property (weak, nonatomic) IBOutlet UIImageView *imgUserAvatar;
@property (weak, nonatomic) IBOutlet UIImageView *imgPostContent;

- (void)getAvatarImageFromInternet:(RCUser *) user withLoggedInUserID:(int)loggedInUserID usingCollection:(NSMutableDictionary*)userCache;
- (void)getPostContentImageFromInternet:(RCUser *) user withPostContent:(RCPost *) post usingCollection:(NSMutableDictionary*)postCache;

@end
