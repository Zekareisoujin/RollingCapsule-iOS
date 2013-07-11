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
#import "RCAmazonS3Helper.h"
#import "RCResourceCache.h"
#import <AWSRuntime/AWSRuntime.h>

@interface RCUserProfileViewController ()

@end

@implementation RCUserProfileViewController

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

NSArray  *_postPreviewElements;
NSString *_friendStatus;
int       _friendshipID;

// Test map scale:
double  refLong;
double  refLat;
double  refX;
double  refY;
double  minimapScaleX;
double  minimapScaleY;

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
    self.navigationItem.title = @" ";
    _lblEmail.text = _profileUser.email;
    _lblName.text = _profileUser.name;
    _btnFriendAction.enabled = NO;
    _btnAvatarImg.enabled = NO;
    [_btnFriendAction setTitle:RCLoadingRelation forState:UIControlStateNormal];
    [self getAvatarImageFromInternet];
    if (_profileUser.userID != _viewingUser.userID)
        [self asynchGetUserRelationRequest];
    else {
        [_btnFriendAction removeFromSuperview];
    }
    
    UICollectionViewFlowLayout *flow =  (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    flow.minimumInteritemSpacing = 0.0;
    
    _postList = [[NSMutableArray alloc] init];
    
    _postPreviewElements = [[NSArray alloc] initWithObjects:_previewBackground, _previewPostImage, _previewLabelDate, _previewLabelDescription, _previewLabelLocation, nil];
    [_previewPostImage.layer setCornerRadius:10.0];
    [_previewPostImage setClipsToBounds:YES];
    [self hidePostPreview];
    
    if (_viewingUser.userID != _profileUser.userID) {
        UIImage *buttonImage = [UIImage imageNamed:@"profileBtnFriendAction"];
        UIButton *postButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _btnFriendAction = postButton;
        [postButton setFrame:CGRectMake(0,0,buttonImage.size.width, buttonImage.size.height)];
        [postButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
        [postButton addTarget:self action:@selector(btnFriendActionClicked:) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithCustomView:postButton] ;
        self.navigationItem.rightBarButtonItem = rightButton;
    }
    
    NSString* cellIdentifier = [RCProfileViewCell cellIdentifier];
    [self.collectionView registerClass:[RCProfileViewCell class] forCellWithReuseIdentifier:cellIdentifier];
    UINib *nib = [UINib nibWithNibName:cellIdentifier bundle: nil];
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:cellIdentifier];
    
    [self calculateReferenceCoordinate];
    [self asynchFetchFeeds];
    
    /*CGPoint test = [self calculateCoordinateOnMinimapWithCoordinate:0.0 andLattitude:51.47];
    NSLog(@"Map coordinates x is %.2f and y is %.2f", test.x, test.y);*/
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - web requests

- (void)asynchFetchFeeds {
    //Asynchronous Request
    [_postList removeAllObjects];
    @try {
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d?mobile=1", RCServiceURL, RCUsersResource, _profileUser.userID]];
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
                     
                     RCPost *test = [[RCPost alloc] initWithNSDictionary:elem];
                     CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(test.latitude, test.longitude);
                     MKMapPoint point = MKMapPointForCoordinate(coord);
                     NSLog(@"Long & lat: %.2f and %.2f; producing: %.2f and %.2f", test.longitude, test.latitude, point.x, point.y);
                 }
                 
                 [_collectionView reloadData];
                 [self drawMinimap];
             }
             
             /*if (jsonData != NULL) {
                 //NSLog(@"Profile View: fetched feeds: %@", jsonData);
                 NSArray *jsonDataArray = (NSArray *) [jsonData objectForKey:@"post_list"];
                 //NSLog(@"Profile View: post lists: %@", jsonDataArray);
                 for (NSDictionary* elem in jsonDataArray){
                     [_postList addObject:[[RCPost alloc] initWithNSDictionary:elem]];
                 }
                 
                 [_collectionView reloadData];
             }else {
                 alertStatus([NSString stringWithFormat:@"%@ %@",RCErrorMessageFailedToGetFeed, responseData], RCAlertMessageConnectionFailed, self);
             }*/
         }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        alertStatus(RCErrorMessageFailedToGetUsersRelation, RCAlertMessageConnectionFailed,self);
    }
}

- (void)asynchGetUserRelationRequest{
    //Asynchronous Request
    @try {
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d/relation?mobile=1&other_user=%d", RCServiceURL, RCUsersResource, self.viewingUserID, _profileUser.userID]];
        NSURLRequest *request = CreateHttpGetRequest(url);
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             [self connectionDidFinishLoading:data];
         }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        alertStatus(RCErrorMessageFailedToGetUsersRelation, RCAlertMessageConnectionFailed,self);
    }
}

- (void)asynchCreateFriendshipRequest{
    //Asynchronous Request
    @try {
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@", RCServiceURL, RCFriendshipsResource]];
        NSMutableString* dataSt = initQueryString(@"friendship[friend_id]",
                                                  [[NSString alloc] initWithFormat:@"%d",_profileUser.userID]);
        NSData *postData = [dataSt dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        NSURLRequest *request = CreateHttpPostRequest(url, postData);
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             [self connectionDidFinishLoading:data];
         }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        alertStatus(RCErrorMessageFailedToEditFriendStatus,RCAlertMessageConnectionFailed,self);
    }
}

- (void)asynchEditFriendshipRequest{
    //Asynchronous Request
    @try {
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d", RCServiceURL, RCFriendshipsResource, _friendshipID]];
        NSMutableString* dataSt = initEmptyQueryString();
        NSData *putData = [dataSt dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        NSURLRequest *request = CreateHttpPutRequest(url, putData);
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             [self connectionDidFinishLoading:data];
         }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        alertStatus(RCErrorMessageFailedToEditFriendStatus,RCAlertMessageConnectionFailed,self);
    }
}

- (void)asynchDeleteFriendshipRequest{
    //Asynchronous Request
    @try {
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d/?mobile=1", RCServiceURL, RCFriendshipsResource, _friendshipID]];
        NSURLRequest *request = CreateHttpDeleteRequest(url);

        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
        {
            [self connectionDidFinishLoading:data];
        }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        alertStatus(RCErrorMessageFailedToEditFriendStatus,RCAlertMessageConnectionFailed,self);
    }
}

- (void)connectionDidFinishLoading:(NSData *)data {
    NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    
    SBJsonParser *jsonParser = [SBJsonParser new];
    NSDictionary *friendshipJson = (NSDictionary *) [jsonParser objectWithString:responseData error:nil];
    NSLog(@"%@",friendshipJson);
    
    if (friendshipJson != NULL) {
        _friendStatus = [friendshipJson objectForKey:@"status"];
        if ((NSNull *)_friendStatus == [NSNull null]) {
            _friendStatus = RCFriendStatusNull;
            [_btnFriendAction setTitle:RCFriendStatusActionRequestFriend forState:UIControlStateNormal];
            _btnFriendAction.enabled = YES;
            if (_btnDeclineRequest != nil)
                [_btnDeclineRequest removeFromSuperview];
        } else {
            NSNumber *num = [friendshipJson objectForKey:@"id"];
            _friendshipID = [num intValue];
            if ([_friendStatus isEqualToString:RCFriendStatusAccepted]) {
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
            
    }else {
        alertStatus([NSString stringWithFormat:@"Failed to obtain friend status, please try again! %@", responseData], @"Connection Failed!", self);
    }
}

#pragma mark - UI events
- (IBAction)btnFriendActionClicked:(id)sender {
    if ([_friendStatus isEqualToString:RCFriendStatusNull]) {
        [self asynchCreateFriendshipRequest];
    } else if ([_friendStatus isEqualToString:RCFriendStatusAccepted]) {
        [self asynchDeleteFriendshipRequest];
    } else if ([_friendStatus isEqualToString:RCFriendStatusPending] || [_friendStatus isEqualToString:RCFriendStatusRequested] ) {
        [self asynchEditFriendshipRequest];
    }
}

- (IBAction)btnAvatarClicked:(id)sender {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

#pragma mark - upload in background thread
- (void)processBackgroundThreadUpload:(UIImage *)avatarImage
{
    _btnAvatarImg.enabled = NO;
    [self performSelectorInBackground:@selector(processBackgroundThreadUploadInBackground:)
                           withObject:avatarImage];
}

- (void)processBackgroundThreadUploadInBackground:(UIImage *)avatarImage
{
    // Convert the image to JPEG data.
    NSData *imageData = UIImageJPEGRepresentation(avatarImage, 1.0);
    
    // Upload image data.  Remember to set the content type.
    S3PutObjectRequest *por = [[S3PutObjectRequest alloc] initWithKey:self.profileUser.email
                                                          inBucket:RCAmazonS3AvatarPictureBucket];
    por.contentType = @"image/jpeg";
    por.data        = imageData;
    
    // Put the image data into the specified s3 bucket and object.
     AmazonS3Client *s3 = [RCAmazonS3Helper s3:_viewingUserID forResource:[NSString stringWithFormat:@"%@/*",RCAmazonS3AvatarPictureBucket]];
    NSString *error = @"Couldn't connect to server, please try again later";
    if (s3 != nil) {
        S3PutObjectResponse *putObjectResponse = [s3 putObject:por];
        error = putObjectResponse.error.description;
        if(putObjectResponse.error != nil) {
            NSLog(@"Error: %@", putObjectResponse.error);
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showCheckErrorMessage:error image:avatarImage];
    });
}

- (void)showCheckErrorMessage:(NSString *)error image:(UIImage *)_image
{
    if(error != nil)
    {
        NSLog(@"Error: %@", error);
        alertStatus(error,RCAlertMessageUploadError,self);
    }
    else
    {
        alertStatus(RCInfoStringPostSuccess, RCAlertMessageUploadSuccess,self);
        [_btnAvatarImg setBackgroundImage:_image forState:UIControlStateNormal];
    }
    _btnAvatarImg.enabled = YES;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}



#pragma mark - UIImagePickerControllerDelegate methods

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    // Get the selected image.
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    UIImage *resizedImage = imageWithImage(image, CGSizeMake(80,80));
    
    [self processBackgroundThreadUpload:resizedImage];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

-(void) imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Helper Methods

-(void) getAvatarImageFromInternet {
    RCResourceCache *cache = [RCResourceCache centralCache];
    NSString *key = [[NSString alloc] initWithFormat:@"%@/%d", RCUsersResource, _profileUser.userID];
    
    dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
    dispatch_async(queue, ^{
        UIImage *cachedImg = [cache getResourceForKey:key usingQuery:^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            UIImage *image = [RCAmazonS3Helper getAvatarImage:_profileUser withLoggedinUserID:_viewingUserID];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            return image;
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIControlState controlState = UIControlStateNormal;
            if (_profileUser.userID != _viewingUserID)
                controlState = UIControlStateDisabled;
            else
                _btnAvatarImg.enabled = YES;
            if (cachedImg != nil)
                [_btnAvatarImg setBackgroundImage:cachedImg forState:controlState];
        });
    });
    
    /*dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
    dispatch_async(queue, ^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        UIImage *image = [RCAmazonS3Helper getAvatarImage:_profileUser withLoggedinUserID:_viewingUserID];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        dispatch_async(dispatch_get_main_queue(), ^{
            UIControlState controlState = UIControlStateNormal;
            if (_profileUser.userID != _viewingUserID)
                controlState = UIControlStateDisabled;
            else
                _btnAvatarImg.enabled = YES;
            if (image != nil)
                [_btnAvatarImg setBackgroundImage:image forState:controlState];
        });
        
    });*/
}

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

    [cell getPostContentImageFromInternet:_viewingUser withPostContent:post usingCollection:nil completion:^{
    }];
    
    /*if ([_chosenPosts count] != 0) {
        if ([_chosenPosts containsObject:[[NSNumber alloc] initWithInt:post.postID]]) {
            [cell changeCellState:RCCellStateFloat];
        } else {
            [cell changeCellState:RCCellStateDimmed];
        }
    }*/
    return cell;
}

#pragma mark – UICollectionViewDelegateFlowLayout

// 1
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    float width = (collectionView.frame.size.height-24) / 3; // hard coding the number of rows to be 3 atm
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
    [_previewLabelDescription setText:post.content];
    
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
    refLong = 103.77;
    refLat = 1.32;
    refX = 437;
    refY = 157;
    
    double refLong2 = -122.41;
    double refLat2 = 37.79;
    double refX2 = 40;
    double refY2 = 88;
    
    CLLocationCoordinate2D refCoord = CLLocationCoordinate2DMake(refLat, refLong);
    MKMapPoint refPoint = MKMapPointForCoordinate(refCoord);
    CLLocationCoordinate2D refCoord2 = CLLocationCoordinate2DMake(refLat2, refLong2);
    MKMapPoint refPoint2 = MKMapPointForCoordinate(refCoord2);
    
    minimapScaleX = (refX - refX2) / (refPoint.x - refPoint2.x);
    minimapScaleY = (refY - refY2) / (refPoint.y - refPoint2.y);
}

- (CGPoint) calculateCoordinateOnMinimapWithCoordinate: (double) longitude andLattitude: (double) lattitude {
    CLLocationCoordinate2D refCoord = CLLocationCoordinate2DMake(refLat, refLong);
    MKMapPoint refPoint = MKMapPointForCoordinate(refCoord);
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(lattitude, longitude);
    MKMapPoint point = MKMapPointForCoordinate(coord);
    
    CGPoint ret = CGPointMake((point.x - refPoint.x)*minimapScaleX + refX, (point.y - refPoint.y)*minimapScaleY + refY);
    return ret;
}

- (void) drawMinimap {
    UIImage *minimapImage = _previewWorldMap.image;
    UIGraphicsBeginImageContext(minimapImage.size);
    
    [minimapImage drawAtPoint:CGPointZero];
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	[[UIColor redColor] setStroke];
    [[UIColor redColor] setFill];
    
    for (RCPost* post in _postList){
        CGPoint drawLoc = [self calculateCoordinateOnMinimapWithCoordinate:post.longitude andLattitude:post.latitude];
        CGRect circleRect = CGRectMake(drawLoc.x, drawLoc.y, 10, 10);
        CGContextFillEllipseInRect(ctx, circleRect);
    }
    
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    [_previewWorldMap setImage:finalImage];
	UIGraphicsEndImageContext();
}

@end
