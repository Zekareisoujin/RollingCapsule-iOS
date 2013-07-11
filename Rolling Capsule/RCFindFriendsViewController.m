//
//  RCFindFriendsViewController.m
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 29/5/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCUtilities.h"
#import "RCConstants.h"
#import "SBJson.h"
#import "RCFindFriendsViewController.h"
#import "RCUserProfileViewController.h"
#import "RCUserTableCell.h"
#import "RCConnectionManager.h"

@interface RCFindFriendsViewController ()
@property (nonatomic,strong) UIRefreshControl *refreshControl;
@end

@implementation RCFindFriendsViewController

@synthesize user = _user;
@synthesize items = _items;
@synthesize refreshControl = _refreshControl;

RCConnectionManager *_connectionManager;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithUser:(RCUser *)user {
    self = [super init];
    if (self) {
        _user = user;
        _connectionManager = [[RCConnectionManager alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //set up back button when necessary
    if ([self.navigationController.viewControllers count] > 2)
        [self setupBackButton];
    
    [_connectionManager reset];
    
    self.navigationItem.title = @" ";
    _items = [[NSMutableArray alloc] init];
    _tblViewFoundUsers.tableFooterView = [[UIView alloc] init];
    UITableViewController *tblViewController = setUpRefreshControlWithTableViewController(self, _tblViewFoundUsers);
    _refreshControl = tblViewController.refreshControl;
    [_refreshControl addTarget:self
                        action:@selector(handleRefresh:)
              forControlEvents:UIControlEventValueChanged];

}

- (void) handleRefresh:(UIRefreshControl *) refreshControl {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"d-MMM, h:mm:ss-a"];
    NSString *lastUpdated = [NSString stringWithFormat:@"Last updated on %@", [formatter  stringFromDate:[NSDate date] ] ];
    refreshControl.attributedTitle= [[NSAttributedString alloc] initWithString:lastUpdated];
    [self asynchFindUsersRequest:[_searchBarFriends text]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - web request
- (void)asynchFindUsersRequest:(NSString *)searchString {
    [_connectionManager startConnection];
    //Asynchronous Request
    @try {
        
        NSString *escapedSearchString = (NSString *)CFBridgingRelease
        (CFURLCreateStringByAddingPercentEscapes(NULL,
                                                 (__bridge CFStringRef) searchString,
                                                 NULL,
                                                 CFSTR("!*'();:@&=+$,/?%#[]"),
                                                 kCFStringEncodingUTF8));
        
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d/find_users?mobile=1&search_string=%@", RCServiceURL, RCUsersResource, _user.userID, escapedSearchString]];
        
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
                [_items removeAllObjects];
                for (NSDictionary *userData in usersJson) {
                    RCUser *user = [[RCUser alloc] initWithNSDictionary:userData];
                    [_items addObject:user];
                }
                [_tblViewFoundUsers reloadData];
            }else {
                alertStatus([NSString stringWithFormat:@"%@ %@",RCErrorMessageFailedToGetUsers, responseData], RCAlertMessageConnectionFailed, self);
            }
            [_refreshControl endRefreshing];
        }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        alertStatus(RCErrorMessageFailedToGetUsers,RCAlertMessageConnectionFailed,self);
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        [_refreshControl endRefreshing];
    }
}


#pragma mark - UISearchBar delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self handleRefresh:_refreshControl];
    [searchBar resignFirstResponder];
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
                          completion:^{[_connectionManager endConnection];}];
    
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


@end
