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
#import <AWSRuntime/AWSRuntime.h>

@interface RCUserProfileViewController ()

@end

@implementation RCUserProfileViewController

@synthesize btnDeclineRequest = _btnDeclineRequest;
@synthesize profileUser = _profileUser;
@synthesize viewingUser = _viewingUser;
@synthesize viewingUserID = _viewingUserID;

NSString *_friendStatus;
int       _friendshipID;

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
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - web requests

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
    dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
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
        
    });
}

@end
