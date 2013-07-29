//
//  RCUserProfileViewController.m
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 29/5/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCUtilities.h"
#import "RCConstants.h"
#import "SBJson.h"
#import "RCUserProfileViewController.h"
#import "RCConnectionManager.h"
#import "RCAmazonS3Helper.h"
#import "RCResourceCache.h"
#import "RCFriendListViewController.h"
#import "RCPostDetailsViewController.h"
#import "UIImage+animatedGIF.h"
#import <AWSRuntime/AWSRuntime.h>

@interface RCUserProfileViewController ()

@property (nonatomic, strong) UITextField* txtFieldEditName;
@property (nonatomic, assign) BOOL editingProfile;
@property (nonatomic, assign) BOOL pickedNewAvatarImage;
@property (nonatomic, weak)   UIImage *userAvatarImage;
@property (nonatomic, strong) UILabel *lblAvatarEdit;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;
@end

@implementation RCUserProfileViewController {
    NSArray  *_postPreviewElements;
    NSString *_friendStatus;
    int       _friendshipID;
    int       _followID;
    BOOL      _isFollowing;
    
    int       nRows;
    
    // Feed page control:
    int     currentPageNumber;
    int     currentMaxPostNumber;
    int     currentMaxDisplayedPostNumber;
    int     showThreshold;
    BOOL    willShowMoreFeeds;
    
    // Map reference data:
    NSArray *referencePoints;
    double  minimapScaleX;
    double  minimapScaleY;
    struct RCMapReferencePoint orgRefPoint;
}

@synthesize collectionView = _collectionView;
@synthesize btnDeclineRequest = _btnDeclineRequest;
@synthesize profileUser = _profileUser;
@synthesize viewingUser = _viewingUser;
@synthesize postList = _postList;
@synthesize viewingUserID = _viewingUserID;

@synthesize previewBackground = _previewBackground;
@synthesize previewPostImage = _previewPostImage;
@synthesize previewLabelLocation = _previewLabelLocation;
@synthesize previewLabelDate = _previewLabelDate;
@synthesize previewLabelDescription = _previewLabelDescription;
@synthesize selectedCell = _selectedCell;
@synthesize txtFieldEditName = _txtFieldEditName;
@synthesize editingProfile = _editingProfile;
@synthesize pickedNewAvatarImage = _pickedNewAvatarImage;
@synthesize userAvatarImage = _userAvatarImage;
@synthesize lblAvatarEdit = _lblAvatarEdit;
@synthesize longPressGestureRecognizer = _longPressGestureRecognizer;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (id)initWithUser:(RCUser *) profileUser viewingUser:(RCUser *)viewingUser{
    self = [super init];
    if (self) {
        _profileUser = profileUser;
        _viewingUser = viewingUser;
        _viewingUserID = _viewingUser.userID;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([self.navigationController.viewControllers count] > 2)
        [self setupBackButton];
    
    // Initialize display elements
    self.navigationItem.title = @" ";
    _lblName.text = _profileUser.name;
    _btnFriendAction.enabled = NO;
    _btnAvatarImg.enabled = NO;
    //_userAvatarImage = [UIImage standardLoadingImage];
    //[_btnAvatarImg setImage:[UIImage standardLoadingImage] forState:UIControlStateNormal];
    [_btnFriendAction setTitle:RCLoadingRelation forState:UIControlStateNormal];
    
    [_profileUser getUserAvatarAsync:_viewingUserID completionHandler:^(UIImage* img){
        dispatch_async(dispatch_get_main_queue(), ^{
            _userAvatarImage = img;
            [_btnAvatarImg setBackgroundImage:_userAvatarImage forState:UIControlStateNormal];
            [_btnAvatarImg setBackgroundImage:_userAvatarImage forState:UIControlStateDisabled];
        });
    }];
    
    UICollectionViewFlowLayout *flow =  (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    flow.minimumInteritemSpacing = 0.0;
    
    if ([[UIScreen mainScreen] bounds].size.height < RCIphone5Height) {
        nRows = 2;
    }else {
        nRows = 3;
    }
    float width = (_collectionView.frame.size.height-42) / nRows;
    int numCell = [[UIScreen mainScreen] bounds].size.width / width + 0.5;
    showThreshold = numCell * nRows;
    
    
    _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    
    _postList = [[NSMutableArray alloc] init];
    
    _postPreviewElements = [[NSArray alloc] initWithObjects:_previewBackground, _previewPostImage, _previewLabelDate, _previewLabelDescription, _previewLabelLocation, nil];
    [_previewPostImage.layer setCornerRadius:10.0];
    [_previewPostImage setClipsToBounds:YES];
    [self hidePostPreview];
    
    [_btnFollow setContentEdgeInsets:UIEdgeInsetsMake(0, 35, 0, 0)];
    [_btnFollow setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [_btnViewFriends setContentEdgeInsets:UIEdgeInsetsMake(0, 35, 0, 0)];
    [_btnViewFriends setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    
    if (_viewingUser.userID != _profileUser.userID) {
        [_btnEditProfile setHidden:YES];
        [_btnEditProfile setEnabled:NO];

//        [self asynchGetUserRelationRequest];
//        [self asynchCheckUserFollowRequest];
        [self getUserRelations];
        
        UIImage *buttonImage = [UIImage imageNamed:@"btnStandard-normal.png"];
        UIButton *postButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _btnFriendAction = postButton;
        [postButton setFrame:CGRectMake(0,0,buttonImage.size.width*1.6, buttonImage.size.height)];
        [postButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
        [postButton addTarget:self action:@selector(btnFriendActionClicked:) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithCustomView:postButton] ;
        self.navigationItem.rightBarButtonItem = rightButton;
    } else {
        [_btnFriendAction removeFromSuperview];
        [_btnFollow setHidden:YES];
        [_btnFollow setEnabled:NO];
        [_btnViewFriends setHidden:YES];
        [_btnViewFriends setEnabled:NO];
        
        _pickedNewAvatarImage = NO;
        _editingProfile = NO;
    }
    
    [self showMoreFeedButton:NO animate:NO];
    
    NSString* cellIdentifier = [RCProfileViewCell cellIdentifier];
    [self.collectionView registerClass:[RCProfileViewCell class] forCellWithReuseIdentifier:cellIdentifier];
    UINib *nib = [UINib nibWithNibName:cellIdentifier bundle: nil];
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:cellIdentifier];
    
    // Set up reference points:
    // Should load this from somewhere next time
//    referencePoints = [[NSArray alloc] initWithObjects: createMapReferencePoint(103.77, 1.32, 886, 409),
//                                                        createMapReferencePoint(0.0, 51.51, 556, 223),
//                                                        createMapReferencePoint(-109.87, 23.10, 219, 335),
//                                                        createMapReferencePoint(120.93, 23.81, 933, 331),
//                                                        createMapReferencePoint(142.62, 43.37, 982, 244), nil];
    
    referencePoints = [[NSArray alloc] initWithObjects: createMapReferencePoint(103.77, 1.32, 791, 352),
                                                       createMapReferencePoint(0.0, 51.51, 497, 172),
                                                       createMapReferencePoint(-109.87, 23.10, 187, 279),
                                                       createMapReferencePoint(120.93, 23.81, 841, 278),
                                                       createMapReferencePoint(142.62, 43.37, 902, 205), nil];
    
    //CGPoint x = [self calculateCoordinateOnMinimapWithCoordinate:0.0 lattitude:0.0];
    [self calculateReferenceCoordinate];
    [self asynchFetchFeeds];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [AppDelegate cleanupMemory];
    // Dispose of any resources that can be recreated.
}

- (void)getUserRelations {
    [_viewingUser getUserFriendRelationAsync:_profileUser completionHandler:^(BOOL isFriend, int friendshipID, NSString* friendStatus, NSString* errorMsg) {
        if (errorMsg == nil) {
            if (isFriend) {
                _friendshipID = friendshipID;
                _friendStatus = friendStatus;
            }else
                _friendStatus = RCFriendStatusNull;
            [self setFriendActionButton];
        }else
            postNotification(errorMsg);
    }];
    
    [_viewingUser getUserFollowRelationAsync:_profileUser completionHandler:^(BOOL isFollowing, int followID, NSString* errorMsg) {
        if (errorMsg == nil) {
            _isFollowing = isFollowing;
            _followID = followID;
            if (!_isFollowing)
                [_btnFollow setTitle:@"Follow" forState:UIControlStateNormal];
            else
                [_btnFollow setTitle:@"Unfollow" forState:UIControlStateNormal];
        }else
            postNotification(errorMsg);
    }];
}

#pragma mark - web requests

// Feed requests
- (void)asynchFetchFeeds {
    //Asynchronous Request
    //[_postList removeAllObjects];
    @try {
        currentPageNumber = 1;
        currentMaxDisplayedPostNumber = currentMaxPostNumber = currentPageNumber * RCPostPerPage;
        
        NSMutableString *address = [[NSMutableString alloc] initWithFormat:@"%@%@/%d?mobile=1", RCServiceURL, RCUsersResource, _profileUser.userID];
        addArgumentToQueryString(address, @"page", [NSString stringWithFormat:@"%d",currentPageNumber]);
        
        NSURL *url=[NSURL URLWithString:address];
        NSURLRequest *request = CreateHttpGetRequest(url);
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
             
             SBJsonParser *jsonParser = [SBJsonParser new];
             NSArray *jsonData = (NSArray *) [jsonParser objectWithString:responseData error:nil];
             
             if ([jsonData count] > 0) {
                 for (NSDictionary* elem in jsonData){
                     [_postList addObject:[[RCPost alloc] initWithNSDictionary:elem]];
                 }
                 
                 [_collectionView reloadData];
                 [self drawMinimap];
             }
             willShowMoreFeeds = ([_postList count] == currentMaxPostNumber);
         }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        postNotification(RCErrorMessageFailedToGetUsersRelation);
    }
}

- (void)asynchFetchFeedNextPage {
    //Asynchronous Request
    //[_postList removeAllObjects];
    @try {
        currentPageNumber++;
        currentMaxPostNumber = currentPageNumber * RCPostPerPage;
        
        NSMutableString *address = [[NSMutableString alloc] initWithFormat:@"%@%@/%d?mobile=1", RCServiceURL, RCUsersResource, _profileUser.userID];
        addArgumentToQueryString(address, @"page", [NSString stringWithFormat:@"%d",currentPageNumber]);
        
        NSURL *url=[NSURL URLWithString:address];
        NSURLRequest *request = CreateHttpGetRequest(url);
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
             
             SBJsonParser *jsonParser = [SBJsonParser new];
             NSArray *jsonData = (NSArray *) [jsonParser objectWithString:responseData error:nil];
             
             if ([jsonData count] > 0) {
                 for (NSDictionary* elem in jsonData){
                     [_postList addObject:[[RCPost alloc] initWithNSDictionary:elem]];
                 }
             }else {
                 willShowMoreFeeds = NO;
                 [_btnMoreFeed setHidden:YES];
             }
             
              [self drawMinimap];
         }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        postNotification(RCErrorMessageFailedToGetUsersRelation);
    }
}

//// Friend relation requests
//- (void)asynchGetUserRelationRequest{
//    //Asynchronous Request
//    @try {
//        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d/relation?mobile=1&other_user=%d", RCServiceURL, RCUsersResource, self.viewingUserID, _profileUser.userID]];
//        NSURLRequest *request = CreateHttpGetRequest(url);
//        
//        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
//                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
//         {
//             [self completeFriendshipRequest:data];
//         }];
//    }
//    @catch (NSException * e) {
//        NSLog(@"Exception: %@", e);
//        alertStatus(RCErrorMessageFailedToGetUsersRelation, RCAlertMessageConnectionFailed,self);
//    }
//}
//
//- (void)asynchCreateFriendshipRequest{
//    //Asynchronous Request
//    @try {
//        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@", RCServiceURL, RCFriendshipsResource]];
//        NSMutableString* dataSt = initQueryString(@"friendship[friend_id]",
//                                                  [[NSString alloc] initWithFormat:@"%d",_profileUser.userID]);
//        NSData *postData = [dataSt dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
//        NSURLRequest *request = CreateHttpPostRequest(url, postData);
//        
//        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
//                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
//         {
//             [self completeFriendshipRequest:data];
//         }];
//    }
//    @catch (NSException * e) {
//        NSLog(@"Exception: %@", e);
//        alertStatus(RCErrorMessageFailedToEditFriendStatus,RCAlertMessageConnectionFailed,self);
//    }
//}
//
//- (void)asynchEditFriendshipRequest{
//    //Asynchronous Request
//    @try {
//        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d", RCServiceURL, RCFriendshipsResource, _friendshipID]];
//        NSMutableString* dataSt = initEmptyQueryString();
//        NSData *putData = [dataSt dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
//        NSURLRequest *request = CreateHttpPutRequest(url, putData);
//        
//        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
//                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
//         {
//             [self completeFriendshipRequest:data];
//         }];
//    }
//    @catch (NSException * e) {
//        NSLog(@"Exception: %@", e);
//        alertStatus(RCErrorMessageFailedToEditFriendStatus,RCAlertMessageConnectionFailed,self);
//    }
//}
//
//- (void)asynchDeleteFriendshipRequest{
//    //Asynchronous Request
//    @try {
//        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d/?mobile=1", RCServiceURL, RCFriendshipsResource, _friendshipID]];
//        NSURLRequest *request = CreateHttpDeleteRequest(url);
//
//        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
//                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
//        {
//            [self completeFriendshipRequest:data];
//        }];
//    }
//    @catch (NSException * e) {
//        NSLog(@"Exception: %@", e);
//        alertStatus(RCErrorMessageFailedToEditFriendStatus,RCAlertMessageConnectionFailed,self);
//    }
//}
//
//- (void)completeFriendshipRequest:(NSData *)data {
//    NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
//    
//    SBJsonParser *jsonParser = [SBJsonParser new];
//    NSDictionary *friendshipJson = (NSDictionary *) [jsonParser objectWithString:responseData error:nil];
//    NSLog(@"%@",friendshipJson);
//    
//    if (friendshipJson != NULL) {
//        _friendStatus = [friendshipJson objectForKey:@"status"];
//        if ((NSNull *)_friendStatus == [NSNull null]) {
//            _friendStatus = RCFriendStatusNull;
//            [_btnFriendAction setTitle:RCFriendStatusActionRequestFriend forState:UIControlStateNormal];
//            _btnFriendAction.enabled = YES;
//            if (_btnDeclineRequest != nil)
//                [_btnDeclineRequest removeFromSuperview];
//        } else {
//            NSNumber *num = [friendshipJson objectForKey:@"id"];
//            _friendshipID = [num intValue];
//            if ([_friendStatus isEqualToString:RCFriendStatusAccepted]) {
//                [_btnFriendAction setTitle:RCFriendStatusActionUnfriend forState:UIControlStateNormal];
//                _btnFriendAction.enabled = YES;
//                if (_btnDeclineRequest != nil)
//                    [_btnDeclineRequest removeFromSuperview];
//            } else if ([_friendStatus isEqualToString:RCFriendStatusPending]) {
//                [_btnFriendAction setTitle:RCFriendStatusActionRequestSent forState:UIControlStateNormal];
//                _btnFriendAction.enabled = NO;
//                if (_btnDeclineRequest != nil)
//                    [_btnDeclineRequest removeFromSuperview];
//            } else if ([_friendStatus isEqualToString:RCFriendStatusRequested]) {
//                [_btnFriendAction setTitle:RCFriendStatusActionRequestAccept forState:UIControlStateNormal];
//                CGRect baseFrame = _btnFriendAction.frame;
//                if (_btnDeclineRequest != nil)
//                    _btnDeclineRequest = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//                _btnDeclineRequest.frame = CGRectMake(baseFrame.origin.x, baseFrame.origin.y + baseFrame.size.height + 10, baseFrame.size.width, baseFrame.size.height);
//                [_btnDeclineRequest setTitle:RCDeclineRequest forState:UIControlStateNormal];
//                [_btnDeclineRequest addTarget:self action:@selector(asynchDeleteFriendshipRequest) forControlEvents:UIControlEventTouchUpInside];
//                [self.view addSubview:_btnDeclineRequest];
//                _btnFriendAction.enabled = YES;
//                
//            }
//        }
//            
//    }else {
//        alertStatus([NSString stringWithFormat:@"Failed to obtain friend status, please try again! %@", responseData], @"Connection Failed!", nil);
//    }
//}
//
//// Follow relation requests
//- (void) asynchCheckUserFollowRequest {
//    //Asynchronous Request
//    @try {
//        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d/relation_follow?mobile=1&other_user=%d", RCServiceURL, RCUsersResource, self.viewingUserID, _profileUser.userID]];
//        NSURLRequest *request = CreateHttpGetRequest(url);
//        
//        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
//                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
//         {
//             [self completeFollowRequest:data];
//         }];
//    }
//    @catch (NSException * e) {
//        NSLog(@"Exception: %@", e);
//        alertStatus(RCErrorMessageFailedToGetUsersRelation, RCAlertMessageConnectionFailed,self);
//    }
//}
//
//- (void) asynchCreateFollowRequest {
//    //Asynchronous Request
//    @try {
//        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@?mobile=1", RCServiceURL, RCFollowResource]];
//        NSMutableString* dataSt = initQueryString(@"follow[followee_id]",
//                                                  [[NSString alloc] initWithFormat:@"%d",_profileUser.userID]);
//        NSData *postData = [dataSt dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
//        NSURLRequest *request = CreateHttpPostRequest(url, postData);
//        
//        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
//                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
//         {
//             [self completeFollowRequest:data];
//         }];
//    }
//    @catch (NSException * e) {
//        NSLog(@"Exception: %@", e);
//        alertStatus(RCErrorMessageFailedToEditFriendStatus,RCAlertMessageConnectionFailed,self);
//    }
//}
//
//- (void)asynchDeleteFollowRequest{
//    //Asynchronous Request
//    @try {
//        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d/?mobile=1", RCServiceURL, RCFollowResource, _followID]];
//        NSURLRequest *request = CreateHttpDeleteRequest(url);
//        
//        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
//                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
//         {
//             [self completeFollowRequest:data];
//         }];
//    }
//    @catch (NSException * e) {
//        NSLog(@"Exception: %@", e);
//        alertStatus(RCErrorMessageFailedToEditFriendStatus,RCAlertMessageConnectionFailed,self);
//    }
//}
//
//- (void) completeFollowRequest: (NSData*) data {
//    NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
//    
//    SBJsonParser *jsonParser = [SBJsonParser new];
//    NSDictionary *followJson = (NSDictionary *) [jsonParser objectWithString:responseData error:nil];
//    NSLog(@"%@",followJson);
//    
//    if (followJson != NULL) {
//        NSDictionary *followObj = [followJson objectForKey:@"follow"];
//        if ((NSNull*) followObj == [NSNull null]) {
//            _isFollowing = NO;
//            [_btnFollow setTitle:@"Follow" forState:UIControlStateNormal];
//        }else {
//            NSNumber *num = [followObj objectForKey:@"id"];
//            _followID = [num intValue];
//            _isFollowing = YES;
//            [_btnFollow setTitle:@"Unfollow" forState:UIControlStateNormal];
//        }
//    }else {
//        alertStatus(@"Failed to obtain follow status, please try again!", @"Connection Failed", nil);
//    }
//}

#pragma mark - UI events
- (IBAction)btnFriendActionClicked:(id)sender {
//    if ([_friendStatus isEqualToString:RCFriendStatusNull]) {
//        [self asynchCreateFriendshipRequest];
//    } else if ([_friendStatus isEqualToString:RCFriendStatusAccepted]) {
//        [self asynchDeleteFriendshipRequest];
//    } else if ([_friendStatus isEqualToString:RCFriendStatusPending] || [_friendStatus isEqualToString:RCFriendStatusRequested] ) {
//        [self asynchEditFriendshipRequest];
//    }
    
    if ([_friendStatus isEqualToString:RCFriendStatusNull]) {
        [RCUser addFriendAsCurrentUserAsync:_profileUser completionHandler:^(int friendshipID, NSString* errorMsg) {
            if (errorMsg == nil) {
                _friendStatus = RCFriendStatusPending;
                _friendshipID = friendshipID;
                [self setFriendActionButton];
                postNotification([NSString stringWithFormat:@"You have sent a friend request to %@", _profileUser.name]);
            }else
                postNotification(errorMsg);
        }];
    } else if ([_friendStatus isEqualToString:RCFriendStatusAccepted]) {
        [RCUser removeFriendRelationAsync:_friendshipID completionhandler:^(NSString* errorMsg) {
            if (errorMsg == nil) {
                _friendStatus = RCFriendStatusNull;
                [self setFriendActionButton];
                postNotification([NSString stringWithFormat:@"You have removed %@ from your friend list", _profileUser.name]);
            }else
                postNotification(errorMsg);
        }];
    } else if ([_friendStatus isEqualToString:RCFriendStatusRequested] ) {
        [RCUser acceptFriendRelationAsync:_friendshipID completionhandler:^(NSString* errorMsg) {
            if (errorMsg == nil) {
                _friendStatus = RCFriendStatusAccepted;
                [self setFriendActionButton];
                postNotification([NSString stringWithFormat:@"%@ is now your friend", _profileUser.name]);
            }else
                postNotification(errorMsg);
        }];
    }
}

- (void)setFriendActionButton {
    if ([_friendStatus isEqualToString:RCFriendStatusNull]) {
        [_btnFriendAction setTitle:RCFriendStatusActionRequestFriend forState:UIControlStateNormal];
        _btnFriendAction.enabled = YES;
        if (_btnDeclineRequest != nil)
            [_btnDeclineRequest removeFromSuperview];
    }else if ([_friendStatus isEqualToString:RCFriendStatusAccepted]) {
        [_btnFriendAction setTitle:RCFriendStatusActionUnfriend forState:UIControlStateNormal];
        _btnFriendAction.enabled = YES;
        if (_btnDeclineRequest != nil)
            [_btnDeclineRequest removeFromSuperview];
    } else if ([_friendStatus isEqualToString:RCFriendStatusPending]) {
        [_btnFriendAction setTitle:RCFriendStatusActionRequestSent forState:UIControlStateNormal];
        _btnFriendAction.enabled = NO;
        if (_btnDeclineRequest != nil)
            [_btnDeclineRequest removeFromSuperview];
    } else if ([_friendStatus isEqualToString:RCFriendStatusRequested]) {
        [_btnFriendAction setTitle:RCFriendStatusActionRequestAccept forState:UIControlStateNormal];
        CGRect baseFrame = _btnFriendAction.frame;
        if (_btnDeclineRequest != nil)
            _btnDeclineRequest = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        _btnDeclineRequest.frame = CGRectMake(baseFrame.origin.x, baseFrame.origin.y + baseFrame.size.height + 10, baseFrame.size.width, baseFrame.size.height);
        [_btnDeclineRequest setTitle:RCDeclineRequest forState:UIControlStateNormal];
        [_btnDeclineRequest addTarget:self action:@selector(asynchDeleteFriendshipRequest) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_btnDeclineRequest];
        _btnFriendAction.enabled = YES;
    }
}

- (IBAction)btnAvatarClicked:(id)sender {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.allowsEditing = YES;
    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (IBAction)btnFollowClicked:(id)sender {
    if (!_isFollowing) {
        [RCUser followUserAsCurrentUserAsync:_profileUser completionHandler:^(int followID, NSString* errorMsg){
            if (errorMsg == nil) {
                _isFollowing = YES;
                _followID = followID;
                [_btnFollow setTitle:@"Unfollow" forState:UIControlStateNormal];
                postNotification([NSString stringWithFormat:@"You are now following %@", _profileUser.name]);
            }else
                postNotification(errorMsg);
        }];
    }else {
        [RCUser removeFollowRelationAsync:_followID completionHandler:^(NSString* errorMsg){
            if (errorMsg == nil) {
                _isFollowing = NO;
                [_btnFollow setTitle:@"Follow" forState:UIControlStateNormal];
                postNotification([NSString stringWithFormat:@"You do not follow %@ anymore", _profileUser.name]);
            }else
                postNotification(errorMsg);
        }];
    }
}

- (IBAction)btnViewFriendsClicked:(id)sender {
    RCFriendListViewController *friendListViewController = [[RCFriendListViewController alloc] initWithUser:_profileUser withLoggedinUser:_viewingUser];
    [self.navigationController pushViewController:friendListViewController animated:YES];
}

- (IBAction)btnMoreFeedClicked:(id)sender {
    //[self showMoreFeedButton:NO animate:NO];
    currentMaxDisplayedPostNumber = currentMaxPostNumber;
    [_collectionView reloadData];
}

#pragma mark - upload in background thread
- (void)processBackgroundThreadUpload:(UIImage *)avatarImage
{
    _btnAvatarImg.enabled = NO;
    //[self performSelectorInBackground:@selector(processBackgroundThreadUploadInBackground:)
    //                       withObject:avatarImage];
    
    __unsafe_unretained typeof(self) weakSelf = self;
    [_profileUser setUserAvatarAsync:avatarImage completionHandler:^(UIImage* retAvatar){
        dispatch_async(dispatch_get_main_queue(),^{
            if (retAvatar != nil) {
                weakSelf.userAvatarImage = retAvatar;
                postNotification(RCInfoStringPostSuccess);
                [weakSelf.btnAvatarImg setBackgroundImage:retAvatar forState:UIControlStateDisabled];
            }
        });
    }];
}

//- (void)processBackgroundThreadUploadInBackground:(UIImage *)avatarImage
//{
//    // Convert the image to JPEG data.
//    NSData *imageData = UIImageJPEGRepresentation(avatarImage, 1.0);
//    
//    // Upload image data.  Remember to set the content type.
//    S3PutObjectRequest *por = [[S3PutObjectRequest alloc] initWithKey:self.profileUser.email
//                                                          inBucket:RCAmazonS3AvatarPictureBucket];
//    por.contentType = @"image/jpeg";
//    por.data        = imageData;
//    
//    // Put the image data into the specified s3 bucket and object.
//     AmazonS3Client *s3 = [RCAmazonS3Helper s3:_viewingUserID forResource:[NSString stringWithFormat:@"%@/*",RCAmazonS3AvatarPictureBucket]];
//    NSString *error = @"Couldn't connect to server, please try again later";
//    if (s3 != nil) {
//        S3PutObjectResponse *putObjectResponse = [s3 putObject:por];
//        error = putObjectResponse.error.description;
//        if(putObjectResponse.error != nil) {
//            NSLog(@"Error: %@", putObjectResponse.error);
//        }
//    }
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self showCheckErrorMessage:error image:avatarImage];
//    });
//}

//- (void)showCheckErrorMessage:(NSString *)error image:(UIImage *)image
//{
//    if(error != nil)
//    {
//        NSLog(@"Error: %@", error);
//        alertStatus(error,RCAlertMessageUploadError,self);
//    }
//    else
//    {
//        RCResourceCache *cache = [RCResourceCache centralCache];
//        NSString *key = [[NSString alloc] initWithFormat:@"%@/%d/avatar", RCUsersResource, _profileUser.userID];
//        [cache invalidateKey:key];
//        _userAvatarImage = image;
//        alertStatus(RCInfoStringPostSuccess, RCAlertMessageUploadSuccess,self);
//        [_btnAvatarImg setBackgroundImage:_userAvatarImage forState:UIControlStateDisabled];
//    }
//    [RCConnectionManager endConnection];
//}



#pragma mark - UIImagePickerControllerDelegate methods

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    // Get the selected image.
    //UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    UIImage *resizedImage = imageWithImage(image, CGSizeMake(200,200));
    
    [_btnAvatarImg setBackgroundImage:resizedImage forState:UIControlStateNormal];
    [_btnAvatarImg setBackgroundImage:nil forState:UIControlStateDisabled];
    _userAvatarImage = resizedImage;
    _pickedNewAvatarImage = YES;
    [picker dismissViewControllerAnimated:YES completion:nil];
}

-(void) imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Helper Methods
// To be removed, old code
//-(void) getAvatarImageFromInternet {
//    /*RCResourceCache *cache = [RCResourceCache centralCache];
//    NSString *key = [[NSString alloc] initWithFormat:@"%@/%d-avatar", RCUsersResource, _profileUser.userID];
//    
//    dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
//    dispatch_async(queue, ^{
//        UIImage *cachedImg = [cache getResourceForKey:key usingQuery:^{
//            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
//            UIImage *image = [RCAmazonS3Helper getAvatarImage:_profileUser withLoggedinUserID:_viewingUserID];
//            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
//            return image;
//        }];
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if (cachedImg == nil)
//                _userAvatarImage = [UIImage imageNamed:@"default_avatar.png"];
//            else
//                _userAvatarImage = cachedImg;
//            [_btnAvatarImg setBackgroundImage:_userAvatarImage forState:UIControlStateDisabled];
//            
//        });
//    });*/
//    
//    
//}

#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSLog(@"number of items: %d", [_postList count]);
    return section == 0 ? [_postList count] : 0;
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    NSString* cellIdentifier = [RCProfileViewCell cellIdentifier];
    RCProfileViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    //RCPost *post = [[RCPost alloc] initWithNSDictionary:[_postList objectAtIndex:indexPath.row]];
    RCPost *post = [_postList objectAtIndex:indexPath.row];
    [cell initCellAppearanceForPost:post];
    
    // Pulling next page if necessary:
    if (indexPath.row == (currentMaxPostNumber - 1)) {
        [self asynchFetchFeedNextPage];
    }
    
    if (indexPath.row == (currentMaxDisplayedPostNumber - 1)){
        [self showMoreFeedButton:YES animate:YES];
    }else if (indexPath.row < (currentMaxDisplayedPostNumber - 1 - showThreshold)) {
        if (!_btnMoreFeed.isHidden)
            [self showMoreFeedButton:NO animate:YES];
    }
    
    return cell;
}

#pragma mark – UICollectionViewDelegateFlowLayout

// 1
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    float width = (collectionView.frame.size.height-24) / nRows;
    CGSize retval = CGSizeMake(width,width);
    return retval;
}

// 3
- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(10, 10, 10, 10);//UIEdgeInsetsM
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    RCProfileViewCell *cell = (RCProfileViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
    RCPost *post = (RCPost*)[_postList objectAtIndex:indexPath.row];
    
    if (_selectedCell == cell) {
        if (_selectedCell != nil) {
            [_selectedCell setHighlightShadow:NO];
            [self hidePostPreview];
        }
        _selectedCell = nil;
    }else {
        [_selectedCell setHighlightShadow:NO];
        _selectedCell = cell;
        [_selectedCell setHighlightShadow:YES];
        [self showPostPreview:post withImageFromCell:cell];
    }
}

//Preview panel related methods
- (void) hidePostPreview {
    [UIView animateWithDuration:0.3 animations:^{
        for (UIView *elem in _postPreviewElements)
            elem.layer.opacity = 0.0;
    }completion:^(BOOL finished){
        for (UIView *elem in _postPreviewElements)
            [elem setHidden:YES];
    }];
}

- (void) showPostPreview: (RCPost*) post withImageFromCell: (RCProfileViewCell*) cell{
    for (UIView *elem in _postPreviewElements)
        [elem setHidden:NO];
    
    [_previewPostImage setImage:cell.imageView.image];
    [_previewLabelDescription setText:post.subject];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd.MM.yyyy"];
    [_previewLabelDate setText:[formatter stringFromDate:post.createdTime]];
    //Left location
    
    [UIView animateWithDuration:0.3 animations:^{
        for (UIView *elem in _postPreviewElements)
            elem.layer.opacity = 1.0;
    }];
}

- (void) calculateReferenceCoordinate {
    // Method 1:
    NSValue *val1 = [referencePoints objectAtIndex:0];
    NSValue *val2 = [referencePoints objectAtIndex:1];
    struct RCMapReferencePoint p1, p2;
    [val1 getValue:&p1];
    [val2 getValue:&p2];
    
    CLLocationCoordinate2D refCoord = CLLocationCoordinate2DMake(p1.lattitude, p1.longitude);
    MKMapPoint refPoint = MKMapPointForCoordinate(refCoord);
    CLLocationCoordinate2D refCoord2 = CLLocationCoordinate2DMake(p2.lattitude, p2.longitude);
    MKMapPoint refPoint2 = MKMapPointForCoordinate(refCoord2);
    
    minimapScaleX = (p1.x - p2.x) / (refPoint.x - refPoint2.x);
    minimapScaleY = (p1.y - p2.y) / (refPoint.y - refPoint2.y);
    orgRefPoint = p1;
    
    // Method 2:
//    minimapScaleX = (refX - refX2) / (refLong - refLong2);
//    minimapScaleY = (refY - refY2) / (refLat - refLat2);
}

- (CGPoint) calculateCoordinateOnMinimapWithCoordinate:(double)longitude lattitude:(double)lattitude {
    // Method 1:
    CLLocationCoordinate2D refCoord = CLLocationCoordinate2DMake(orgRefPoint.lattitude, orgRefPoint.longitude);
    MKMapPoint refPoint = MKMapPointForCoordinate(refCoord);
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(lattitude, longitude);
    MKMapPoint point = MKMapPointForCoordinate(coord);
    
    CGPoint ret = CGPointMake((point.x - refPoint.x)*minimapScaleX + orgRefPoint.x, (point.y - refPoint.y)*minimapScaleY + orgRefPoint.y);
    
    // Method 2:
//    CGPoint ret = CGPointMake((longitude - refLong)*minimapScaleX + refX, (lattitude - refLat)*minimapScaleY + refY);
    
    // Method 3:
//    float longt = 0;
//    float latt = 0;
//    float denominator = 0;
//    
//    for (NSValue *val in referencePoints) {
//        struct RCMapReferencePoint p;
//        [val getValue:&p];
//        
//        CLLocationCoordinate2D coord1 = CLLocationCoordinate2DMake(lattitude, longitude);
//        MKMapPoint point1 = MKMapPointForCoordinate(coord1);
//        CLLocationCoordinate2D coord2 = CLLocationCoordinate2DMake(p.lattitude, p.longitude);
//        MKMapPoint point2 = MKMapPointForCoordinate(coord2);
//        
//        float deltaLongt = point1.x - point2.x;
//        float deltaLatt = point1.y - point2.y;
//        float distSq = deltaLongt * deltaLongt + deltaLatt * deltaLatt;
//        float weight = 1/distSq;
//        
//        longt += weight * p.x;
//        latt += weight * p.y;
//        denominator += weight;
//    }
//    
//    CGPoint ret = CGPointMake(longt / denominator, latt / denominator);
    
    // Method 4:
//    UIImage* map = [UIImage imageNamed:@"profileWorldMap"];
//    CGFloat width = map.size.width;
//    CGFloat height = map.size.height;
//    
//    CGFloat x = (width * (180 + longitude) / 360);
//    while (x-width > 0) x-=width;
//    x += width/2;
//    
//    CGFloat PI = 3.141592654;
//    CGFloat latRad = lattitude * PI/180;
//    CGFloat mercN = log(tan((PI/4)+(latRad/2)));
//    CGFloat y = (height / 2) - (width * mercN / (2*PI));
//    
//    CGPoint ret = CGPointMake(x, y);
    
    return ret;
}

- (void) drawMinimap {
    UIImage *minimapImage = _previewWorldMap.image;
    UIGraphicsBeginImageContext(minimapImage.size);
    
    [minimapImage drawAtPoint:CGPointZero];
	/*CGContextRef ctx = UIGraphicsGetCurrentContext();
	[[UIColor redColor] setStroke];
    [[UIColor redColor] setFill];*/
    
    UIImage *mapDot = [UIImage imageNamed:@"profileWorldMapSpot"];
    
    for (RCPost* post in _postList){
        CGPoint drawLoc = [self calculateCoordinateOnMinimapWithCoordinate:post.longitude lattitude:post.latitude];
        /*CGRect circleRect = CGRectMake(drawLoc.x, drawLoc.y, 10, 10);
        CGContextFillEllipseInRect(ctx, circleRect);*/
        drawLoc.x -= mapDot.size.width/2;
        drawLoc.y -= mapDot.size.height/2;
        
        NSLog(@"Post id: %d", post.postID);
        if (post.postID == 434)
            NSLog(@"Here");
        
        [mapDot drawAtPoint:drawLoc];
    }
    
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    [_previewWorldMap setImage:finalImage];
	UIGraphicsEndImageContext();
}

- (IBAction)btnEditProfileTouchUpInside:(id)sender {
    if (_editingProfile) {
        _editingProfile = NO;
        [_btnEditProfile setTitle:@"Edit" forState:UIControlStateNormal];
        _btnAvatarImg.enabled = NO;
        [self doneEditProfile];
        [_lblAvatarEdit removeFromSuperview];
    } else {
        _editingProfile = YES;
        [_btnEditProfile setTitle:@"Apply" forState:UIControlStateNormal];
        [_btnAvatarImg setBackgroundImage:_userAvatarImage forState:UIControlStateNormal];
        _btnAvatarImg.enabled = YES;
        CGRect lblFrame = _btnAvatarImg.frame;
        int incr = 8;
        lblFrame.origin.x += incr;
        lblFrame.origin.y += 4;
        lblFrame.size.width -= incr*2;
        lblFrame.size.height = 20;
        _lblAvatarEdit = [[UILabel alloc] initWithFrame:lblFrame];
        [_lblAvatarEdit setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.2]];
        [self.view addSubview:_lblAvatarEdit];
        [_lblAvatarEdit setText:@"Edit"];
        _lblAvatarEdit.textAlignment = NSTextAlignmentCenter;
        [_lblAvatarEdit setTextColor:[UIColor whiteColor]];
        CGRect frame = _lblName.frame;
        frame.size.height += 5;
        _txtFieldEditName = [[UITextField alloc] initWithFrame:frame];
        _txtFieldEditName.delegate = self;
        _txtFieldEditName.borderStyle = UITextBorderStyleRoundedRect;
        _txtFieldEditName.text = _lblName.text;
        _txtFieldEditName.textAlignment = NSTextAlignmentRight;
        _txtFieldEditName.delegate = self;
        [self.view addSubview:_txtFieldEditName];
    }
}

- (void) doneEditProfile {
    [_txtFieldEditName removeFromSuperview];
    if (_pickedNewAvatarImage) {
        [self processBackgroundThreadUpload:_userAvatarImage];
    }
    dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
    dispatch_async(queue, ^{
        [self.profileUser updateNewName:_txtFieldEditName.text];
        dispatch_async(dispatch_get_main_queue(), ^{
            _lblName.text = _viewingUser.name;
            [RCConnectionManager endConnection];
        });
    });
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([textField isEqual:_txtFieldEditName]) {
        [textField resignFirstResponder];
    }
    return NO;
}

- (void) showMoreFeedButton: (BOOL)show animate:(BOOL)animate {
    float duration = (animate?0.5:0.0);
    
    if (show && willShowMoreFeeds) {
        [_btnMoreFeed setHidden:!show];
        [UIView animateWithDuration:duration animations:^{
            [_btnMoreFeed.layer setOpacity:1.0];
        }];
    }else {
        [UIView animateWithDuration:duration animations:^{
            [_btnMoreFeed.layer setOpacity:0.0];
        }completion:^(BOOL complete){
            if (complete)
                [_btnMoreFeed setHidden:show];
        }];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return (newLength <= 32);
}

#pragma mark - Long Press Gesture handler
- (IBAction)handleLongPress:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [recognizer locationInView:_collectionView];
        NSIndexPath *indexPath = [_collectionView indexPathForItemAtPoint:point];
        
        //if index path for cell not found
        if (indexPath != nil ) {
            RCPost *post = [_postList objectAtIndex:indexPath.row];
//            RCUser *owner = [[RCUser alloc] init];
//            owner.userID = post.userID;
//            owner.name = post.authorName;
            
            [RCUser getUserWithIDAsync:post.userID completionHandler:^(RCUser *owner){
                //[_collectionView removeGestureRecognizer:recognizer];
                RCPostDetailsViewController *postDetailsViewController = [[RCPostDetailsViewController alloc] initWithPost:post withOwner:owner withLoggedInUser:_viewingUser];
                
                /*if (post.landmarkID == -1)
                    postDetailsViewController.landmark = nil;
                else
                    postDetailsViewController.landmark = [_landmarks objectForKey:[NSNumber numberWithInt:post.landmarkID]];*/
                postDetailsViewController.deleteFunction = ^{
                    [_postList removeObjectAtIndex:indexPath.row];
                    [_collectionView reloadData];
                    [self hidePostPreview];
                };
                //postDetailsViewController.landmarkID = post.landmarkID;
                
                [self.navigationController pushViewController:postDetailsViewController animated:YES];
            }];
            
        }
    }
}

- (void) viewWillAppear:(BOOL)animated {
    [_collectionView addGestureRecognizer:_longPressGestureRecognizer];
}

@end
