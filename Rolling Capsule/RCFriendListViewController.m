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

@property (nonatomic, strong) UIRefreshControl *refreshControl;

@end

@implementation RCFriendListViewController
BOOL        _firstRefresh;
@synthesize items = _items;
@synthesize user = _user;
@synthesize refreshControl = _refreshControl;

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
    
    self.navigationItem.title = @" ";
    UITableViewController *tableViewController = setUpRefreshControlWithTableViewController(self, _tblViewFriendList);
    _refreshControl = tableViewController.refreshControl;
    [_refreshControl addTarget:self
                        action:@selector(handleRefresh:)
              forControlEvents:UIControlEventValueChanged  ];
    _firstRefresh = YES;
    [self handleRefresh:_refreshControl];
}

- (void) handleRefresh:(UIRefreshControl *) refreshControl {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd-MMM, hh:mm:ssa"];
    NSString *lastUpdated = [NSString stringWithFormat:@"Last updated on %@", [formatter  stringFromDate:[NSDate date] ] ];
    [_refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:lastUpdated]];
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
    
    [cell getAvatarImageFromInternet:user withLoggedInUserID:_user.userID];
    
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
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    @try {
            
            NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d/friends?mobile=1", RCServiceURL, RCUsersResource, _user.userID]];
            NSURLRequest *request = CreateHttpGetRequest(url);
            
            [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                                   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
            {
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                
                SBJsonParser *jsonParser = [SBJsonParser new];
                NSArray *usersJson = (NSArray *) [jsonParser objectWithString:responseData error:nil];
                NSLog(@"%@",usersJson);
                
                if (usersJson != NULL) {
                    [_items removeAllObjects];
                    for (NSDictionary *userData in usersJson) {
                        RCUser *user = [[RCUser alloc] initWithNSDictionary:userData];
                        [_items addObject:user];
                    }
                    [_refreshControl endRefreshing];
                    
                    [_tblViewFriendList reloadData];
                    if (_firstRefresh) {
                        [_tblViewFriendList setContentOffset:CGPointMake(0, 0) animated:YES];
                        _firstRefresh = NO;
                    }
                }else {
                    alertStatus([NSString stringWithFormat:@"Failed to obtain friend list, please try again! %@", responseData], @"Connection Failed!", self);
                }
            }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        alertStatus(@"Failure getting friends from web service",@"Connection Failed!",self);
    }
}

#pragma mark - open new view

- (void) openFindFriendsView {
    RCFindFriendsViewController *findFriendsViewController = [[RCFindFriendsViewController alloc] initWithUser:_user];
    [self.navigationController pushViewController:findFriendsViewController animated:YES];
}

@end
