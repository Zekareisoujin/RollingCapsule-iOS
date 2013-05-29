//
//  RCFindFriendsViewController.m
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 29/5/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "Util.h"
#import "Constants.h"
#import "SBJson.h"
#import "RCFindFriendsViewController.h"
#import "RCUserProfileViewController.h"
#import "RCFriendListTableCell.h"
#import "RCUser.h"

@interface RCFindFriendsViewController ()

@end

@implementation RCFindFriendsViewController

@synthesize userID = _userID;
@synthesize items = _items;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithUserID:(int)userID {
    self = [super init];
    if (self) {
        _userID = userID;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Find friends";
    _items = [[NSMutableArray alloc] init];
    _tblViewFoundUsers.tableFooterView = [[UIView alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - web request
- (void)asynchFindUsersRequest:(NSString *)searchString {
    //Asynchronous Request
    @try {
        
        NSString *escapedSearchString = (NSString *)CFBridgingRelease
        (CFURLCreateStringByAddingPercentEscapes(NULL,
                                                 (__bridge CFStringRef) searchString,
                                                 NULL,
                                                 CFSTR("!*'();:@&=+$,/?%#[]"),
                                                 kCFStringEncodingUTF8));
        
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d/find_users?mobile=1&search_string=%@", RCServiceURL, RCUsersResource, self.userID, escapedSearchString]];
        
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
        [_items removeAllObjects];
        for (NSDictionary *userData in usersJson) {
            RCUser *user = [[RCUser alloc] initWithNSDictionary:userData];
            [_items addObject:user];
        }
        [_tblViewFoundUsers reloadData];
    }else {
        alertStatus([NSString stringWithFormat:@"Failed to obtain user list, please try again! %@", responseData], @"Connection Failed!", self);
    }
}


#pragma mark - UISearchBar delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self asynchFindUsersRequest:[searchBar text]];
    [searchBar resignFirstResponder];
    NSLog(@"Clicked search");
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
    RCUserProfileViewController *detailViewController = [[RCUserProfileViewController alloc] initWithUser:user loggedinUserID:_userID];
    [self.navigationController pushViewController:detailViewController animated:YES];     
}


@end
