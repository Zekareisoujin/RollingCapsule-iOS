//
//  RCUserProfileViewController.m
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 29/5/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "Util.h"
#import "Constants.h"
#import "SBJson.h"
#import "RCUserProfileViewController.h"

@interface RCUserProfileViewController ()

@end

@implementation RCUserProfileViewController

@synthesize user = _user;
@synthesize loggedinUserID = _loggedinUserID;

NSString *_friendStatus;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithUser:(RCUser *) user loggedinUserID:(int)_id{
    self = [super init];
    if (self) {
        _user = user;
        _loggedinUserID = _id;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Profile";
    _lblEmail.text = _user.email;
    _lblName.text = _user.name;
    _btnFriendAction.enabled = NO;
    [_btnFriendAction setTitle:@"Loading relation" forState:UIControlStateNormal];
    dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
    dispatch_async(queue, ^{
        NSURL *imageUrl = [NSURL URLWithString:_user.avatarImg];
        UIImage *image = [UIImage imageWithData: [NSData dataWithContentsOfURL:imageUrl]];
        dispatch_async(dispatch_get_main_queue(), ^{
            _imgViewAvatar.image = image;
        });
    });
    [self asynchGetUserRelationRequest];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - web request
- (void)asynchGetUserRelationRequest{
    //Asynchronous Request
    @try {
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d/get_relation?mobile=1&other_user=%d", RCServiceURL, RCUsersResource, self.loggedinUserID, _user.userID]];
        
        NSURLRequest *request = CreateHttpGetRequest(url);
        
        NSURLConnection *connection = [[NSURLConnection alloc]
                                       initWithRequest:request
                                       delegate:self
                                       startImmediately:YES];
        _receivedData = [[NSMutableData alloc] init];
        
        if(!connection) {
            NSLog(@"Connection Failed.");
        } else {
            NSLog(@"Connection Succeeded.");
        }
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        alertStatus(@"Failure getting friends from web service",@"Connection Failed!",self);
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
 	//NSLog(@"Received response: %@", response);
 	
    [_receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
 	//NSLog(@"Received %d bytes of data", [data length]);
 	
    [_receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
 	NSLog(@"Error receiving response: %@", error);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSString *responseData = [[NSString alloc]initWithData:_receivedData encoding:NSUTF8StringEncoding];
    
    SBJsonParser *jsonParser = [SBJsonParser new];
    NSDictionary *friendshipJson = (NSDictionary *) [jsonParser objectWithString:responseData error:nil];
    NSLog(@"%@",friendshipJson);
    
    if (friendshipJson != NULL) {
        _friendStatus = [friendshipJson objectForKey:@"status"];
        if ((NSNull *)_friendStatus == [NSNull null]) {
            [_btnFriendAction setTitle:@"Add friend" forState:UIControlStateNormal];
            _btnFriendAction.enabled = YES;
        } else if ([_friendStatus isEqualToString:RCFriendStatusAccepted]) {
            [_btnFriendAction setTitle:@"Unfriend" forState:UIControlStateNormal];
            _btnFriendAction.enabled = YES;
        } else if ([_friendStatus isEqualToString:RCFriendStatusPending]) {
            [_btnFriendAction setTitle:@"Request sent" forState:UIControlStateNormal];
            _btnFriendAction.enabled = NO;
        } else if ([_friendStatus isEqualToString:RCFriendStatusRequested]) {
            [_btnFriendAction setTitle:@"Accept requeset" forState:UIControlStateNormal];
            _btnFriendAction.enabled = YES;
        }
            
    }else {
        alertStatus([NSString stringWithFormat:@"Failed to obtain friend status, please try again! %@", responseData], @"Connection Failed!", self);
    }
}

#pragma mark - UI events
- (IBAction)btnFriendActionClicked:(id)sender {
    
}

@end
