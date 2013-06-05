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

@interface RCFindFriendsViewController ()
@property (nonatomic,strong) UIRefreshControl *refreshControl;
@end

@implementation RCFindFriendsViewController

@synthesize user = _user;
@synthesize items = _items;
@synthesize refreshControl = _refreshControl;

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
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
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
                [_refreshControl endRefreshing];
            }else {
                alertStatus([NSString stringWithFormat:@"Failed to obtain user list, please try again! %@", responseData], @"Connection Failed!", self);
            }
        }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        alertStatus(@"Failure getting friends from web service",@"Connection Failed!",self);
    }
}


#pragma mark - UISearchBar delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self handleRefresh:_refreshControl];
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


@end
