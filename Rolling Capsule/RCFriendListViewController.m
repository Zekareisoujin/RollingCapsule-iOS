//
//  RCFriendListViewController.m
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 28/5/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "Constants.h"
#import "Util.h"
#import "SBJSon.h"
#import "RCFriendListViewController.h"
#import "RCFriendListTableCell.h"
#import "RCFindFriendsViewController.h"
#import "RCUserProfileViewController.h"
#import "AppDelegate.h"
@interface RCFriendListViewController ()

@end

@implementation RCFriendListViewController

@synthesize items = _items;
@synthesize user = _user;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //default value for userID, this is for experimental purpose only
        _user.userID = 1;
    }
    return self;
}

- (id)initWithUser:(RCUser *) user {
    self = [super init];
    if (self) {
        _user = user;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _items = [[NSMutableArray alloc] init];
    _tblViewFriendList.tableFooterView = [[UIView alloc] init];
    self.navigationItem.title = [[NSString alloc] initWithFormat:@"%@'s friends", _user.name];
    UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithTitle:@"Find friends"
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(openFindFriendsView)];
    self.navigationItem.rightBarButtonItem = anotherButton;
	[self asynchGetFriendsRequest];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //Where we configure the cell in each row
    
    static NSString *CellIdentifier = @"RCFriendListTableCell";
    RCFriendListTableCell *cell;
    
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"RCFriendListTableCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    RCUser *user = [_items objectAtIndex:indexPath.row];
    cell.lblEmail.text = user.email;
    cell.lblName.text = user.name;
    
    dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
    dispatch_async(queue, ^{
        NSURL *imageUrl = [NSURL URLWithString:user.avatarImg];
        UIImage *image = [UIImage imageWithData: [NSData dataWithContentsOfURL:imageUrl]];
        dispatch_async(dispatch_get_main_queue(), ^{
            cell.imgViewAvatar.image = image;
        });
    });
    
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 78;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    RCUser *user = [_items objectAtIndex:indexPath.row];
    RCUserProfileViewController *detailViewController = [[RCUserProfileViewController alloc] initWithUser:user loggedinUserID:_user.userID];
    [self.navigationController pushViewController:detailViewController animated:YES];
}

#pragma mark - web request
- (void)asynchGetFriendsRequest {
    //Asynchronous Request
    @try {
            
            NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d/friends?mobile=1", RCServiceURL, RCUsersResource, _user.userID]];
            
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
    NSArray *usersJson = (NSArray *) [jsonParser objectWithString:responseData error:nil];
    NSLog(@"%@",usersJson);
    
    if (usersJson != NULL) {
        for (NSDictionary *userData in usersJson) {
            RCUser *user = [[RCUser alloc] initWithNSDictionary:userData];
            [_items addObject:user];
        }
        [_tblViewFriendList reloadData];
    }else {
        alertStatus([NSString stringWithFormat:@"Failed to obtain friend list, please try again! %@", responseData], @"Connection Failed!", self);
    }
}

#pragma mark - open new view

- (void) openFindFriendsView {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate showSideMenu];
    //RCFindFriendsViewController *findFriendsViewController = [[RCFindFriendsViewController /alloc] initWithUser:_user];
    //[self.navigationController pushViewController:findFriendsViewController animated:YES];
}

@end
