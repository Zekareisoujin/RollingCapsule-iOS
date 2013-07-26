//
//  RCFriendListTableCell.m
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 28/5/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCUserTableCell.h"
#import "RCConstants.h"
#import "RCAmazonS3Helper.h"
#import "RCResourceCache.h"
#import "UIImage+animatedGIF.h"
#import "RCUtilities.h"
#import <QuartzCore/QuartzCore.h>

@implementation RCUserTableCell

BOOL isRequestCell;

@synthesize friendshipID = _friendshipID;
@synthesize completionHandler = _completionHandler;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

+ (RCUserTableCell *) getFriendListTableCell:(UITableView *)tableView {
    static NSString *CellIdentifier = @"RCUserTableCell";
    RCUserTableCell *cell;
    
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:CellIdentifier owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    return cell;
}

+ (CGFloat) cellHeight {
    return 60;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)populateCellData:(RCUser *) user withLoggedInUserID:(int)loggedInUserID requestCell:(BOOL)isRequest {
    _user = user;
    [_lblName setText:_user.name];
    [_imgViewAvatar.layer setCornerRadius:10.0];
    [_imgViewAvatar setClipsToBounds:YES];
    [_imgViewAvatar setImage:[UIImage standardLoadingImage]];
    isRequestCell = NO;
    
    [_user getUserAvatarAsync:loggedInUserID completionHandler:^(UIImage* img){
        dispatch_async(dispatch_get_main_queue(), ^{
            [_imgViewAvatar setImage:img];
        });
    }];
    
    isRequestCell = isRequest;
    if (!isRequestCell) {
        CGRect nameFrame = _lblName.frame;
        //nameFrame.origin.y = ([RCUserTableCell cellHeight] - nameFrame.size.height)/2; //doesn't work at the moment
        //nameFrame.origin.y += 15; //hardcoded
        [_lblName setFrame:nameFrame];
        
        [_btnAccept setHidden:YES];
        [_btnReject setHidden:YES];
    }
}

- (IBAction)btnAcceptTouchedUpInside:(id)sender {
    [RCUser acceptFriendRelationAsync:_friendshipID completionhandler:^(NSString* errorMsg){
        if (errorMsg == nil){
            if (_completionHandler != nil)
                _completionHandler(YES);
            postNotification([NSString stringWithFormat:@"You are now friend with %@", _user.name]);
        }else
            postNotification(errorMsg);
    }];
}

- (IBAction)btnRejectTouchedUpInside:(id)sender {
    [RCUser removeFriendRelationAsync:_friendshipID completionhandler:^(NSString* errorMsg){
        if (errorMsg == nil){
            if (_completionHandler != nil)
                _completionHandler(NO);
            //postNotification([NSString stringWithFormat:@"You are now following %@", _user.name]);
        }else
            postNotification(errorMsg);
    }];
}


@end
