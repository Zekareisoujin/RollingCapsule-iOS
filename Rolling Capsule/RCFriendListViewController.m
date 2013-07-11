//
//  RCFriendListViewController.m
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 28/5/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCConstants.h"
#import "RCUtilities.h"
#import "SBJSon.h"
#import "RCFriendListViewController.h"
#import "RCUserTableCell.h"
#import "RCFindFriendsViewController.h"
#import "RCConnectionManager.h"
#import "RCUserProfileViewController.h"
#import "AppDelegate.h"

@interface RCFriendListViewController ()

@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, weak) NSMutableArray* items;
@end

@implementation RCFriendListViewController
BOOL        _firstRefresh;
@synthesize friends = _friends;
@synthesize requested_friends = _requested_friends;
@synthesize items = _items;
@synthesize user = _user;
@synthesize refreshControl = _refreshControl;
BOOL _viewingFriends;

RCConnectionManager *_connectionManager;

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
        _connectionManager = [[RCConnectionManager alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [_connectionManager reset];
    
    _friends = [[NSMutableArray alloc] init];
    _requested_friends = [[NSMutableArray alloc] init];
    _tblViewFriendList.tableFooterView = [[UIView alloc] init];
    
    UIImage *image = [UIImage imageNamed:@"profileBtnFriendAction.png"];//resizableImageWithCapInsets:UIEdgeInsetsMake(0,20,0,10)];
    UIButton *findFriendsButton = [[UIButton alloc] initWithFrame:CGRectMake(0,0,image.size.width, image.size.height)];
    [findFriendsButton setTitle:@"Find friends" forState:UIControlStateNormal];
    [findFriendsButton setBackgroundImage:image forState:UIControlStateNormal];
    [findFriendsButton addTarget:self action:@selector(openFindFriendsView) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc]
                                    initWithCustomView:findFriendsButton];
    
    self.navigationItem.rightBarButtonItem = rightButton;
    
    //self.navigationItem.title = @"Friends";
    UITableViewController *tableViewController = setUpRefreshControlWithTableViewController(self, _tblViewFriendList);
    _refreshControl = tableViewController.refreshControl;
    [_refreshControl addTarget:self
                        action:@selector(handleRefresh:)
              forControlEvents:UIControlEventValueChanged  ];
    _firstRefresh = YES;
    _viewingFriends = YES;
    _btnFriends.enabled = NO;
    _btnFriends.backgroundColor = [UIColor yellowColor];
    _items = _friends;
    [self handleRefresh:_refreshControl];
}

- (void) handleRefresh:(UIRefreshControl *) refreshControl {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:RCInfoStringDateFormat];
    NSString *lastUpdated = [NSString stringWithFormat:RCInfoStringLastUpdatedOnFormat, [formatter  stringFromDate:[NSDate date] ] ];
    [_refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:lastUpdated]];
    if (_viewingFriends)
        [self asynchGetFriendsRequest];
    else
        [self asynchGetRequestedFriendsRequest];
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
    
    RCUserTableCell *cell = [RCUserTableCell getFriendListTableCell:tableView];
    
    RCUser *user = [_items objectAtIndex:indexPath.row];
    [_connectionManager startConnection];
    [cell populateCellData:user
                  withLoggedInUserID:_user.userID
                          completion:^ { [_connectionManager endConnection]; }];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [RCUserTableCell cellHeight];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    RCUser *user = [_items objectAtIndex:indexPath.row];
    RCUserProfileViewController *detailViewController = [[RCUserProfileViewController alloc] initWithUser:user viewingUser:_user];
    [self.navigationController pushViewController:detailViewController animated:YES];
}

#pragma mark - web request
- (void)asynchGetFriendsRequest {
    //Asynchronous Request
    [_connectionManager startConnection];
    @try {
            
            NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d/friends?mobile=1", RCServiceURL, RCUsersResource, _user.userID]];
            NSURLRequest *request = CreateHttpGetRequest(url);
            
            [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                                   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
            {
                [_connectionManager endConnection];
                NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                
                SBJsonParser *jsonParser = [SBJsonParser new];
                NSArray *usersJson = (NSArray *) [jsonParser objectWithString:responseData error:nil];
                NSLog(@"%@",usersJson);
                
                if (usersJson != NULL) {
                    [_friends removeAllObjects];
                    for (NSDictionary *userData in usersJson) {
                        RCUser *user = [[RCUser alloc] initWithNSDictionary:userData];
                        [_friends addObject:user];
                    }
                    if (_viewingFriends)
                        [_tblViewFriendList reloadData];
                    if (_firstRefresh) {
                        [_tblViewFriendList setContentOffset:CGPointMake(0, 0) animated:YES];
                        _firstRefresh = NO;
                    }
                }else {
                    alertStatus([NSString stringWithFormat:@"%@ %@",RCErrorMessageFailedToGetFriends, responseData], RCAlertMessageConnectionFailed, self);
                    
                }
                [_refreshControl endRefreshing];
            }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        alertStatus(RCErrorMessageFailedToGetFriends,RCAlertMessageConnectionFailed,self);
    }
}

- (void)asynchGetRequestedFriendsRequest {
    //Asynchronous Request
    [_connectionManager startConnection];
    @try {
        
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d/requested_friends?mobile=1", RCServiceURL, RCUsersResource, _user.userID]];
        NSURLRequest *request = CreateHttpGetRequest(url);
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             [_connectionManager endConnection];
             NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
             
             SBJsonParser *jsonParser = [SBJsonParser new];
             NSArray *usersJson = (NSArray *) [jsonParser objectWithString:responseData error:nil];
             NSLog(@"%@",usersJson);
             
             if (usersJson != NULL) {
                 [_requested_friends removeAllObjects];
                 for (NSDictionary *userData in usersJson) {
                     RCUser *user = [[RCUser alloc] initWithNSDictionary:userData];
                     [_requested_friends addObject:user];
                 }
                 if (!_viewingFriends)
                    [_tblViewFriendList reloadData];
                 if (_firstRefresh) {
                     [_tblViewFriendList setContentOffset:CGPointMake(0, 0) animated:YES];
                     _firstRefresh = NO;
                 }
             }else {
                 alertStatus([NSString stringWithFormat:@"%@ %@",RCErrorMessageFailedToGetFriends, responseData], RCAlertMessageConnectionFailed, self);
                 
             }
             [_refreshControl endRefreshing];
         }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        alertStatus(RCErrorMessageFailedToGetFriends,RCAlertMessageConnectionFailed,self);
    }
}

#pragma mark - open new view

- (void) openFindFriendsView {
    RCFindFriendsViewController *findFriendsViewController = [[RCFindFriendsViewController alloc] initWithUser:_user];
    [self.navigationController pushViewController:findFriendsViewController animated:YES];
}

- (IBAction)btnFriendTouchUpInside:(id)sender {
    _viewingFriends = YES;
    _items = _friends;
    _btnFriends.enabled = NO;
    _btnRequests.enabled = YES;
    [self handleRefresh:_refreshControl];
}

- (IBAction)btnRequestsTouchUpInside:(id)sender {
    _viewingFriends = NO;
    _items = _requested_friends;
    _btnFriends.enabled = YES;
    _btnRequests.enabled = NO;
    [self handleRefresh:_refreshControl];
}
@end
