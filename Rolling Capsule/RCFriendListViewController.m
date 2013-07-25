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
#import "RCNewPostViewController.h"
#import "AppDelegate.h"

@interface RCFriendListViewController ()

@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) UIButton* postButton;
@property (nonatomic, weak) NSMutableArray* displayedItems;
@property (nonatomic, strong) NSMutableArray *friends;
@property (nonatomic, strong) NSMutableArray *requested_friends;
@property (nonatomic, strong) NSMutableArray *followees;
@end

@implementation RCFriendListViewController

@synthesize postButton = _postButton;
@synthesize displayedItems = _displayedItems;
@synthesize friends = _friends;
@synthesize requested_friends = _requested_friends;
@synthesize followees = _followees;
@synthesize user = _user;
@synthesize loggedinUser = _loggedinUser;
@synthesize refreshControl = _refreshControl;
@synthesize searchResultList = _searchResultList;

BOOL                    _firstRefresh;
RCFriendListViewMode    _viewingMode;
RCConnectionManager     *_connectionManager;
NSArray                 *controlButtonArray;
NSMutableArray          *currentDisplayedItems;

// Search bar animation
BOOL    showSearchBar;
CGRect  searchBarShowFrame;
CGRect  searchBarHideFrame;
CGRect  searchButtonShowFrame;
CGRect  searchButtonHideFrame;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //default value for userID, this is for experimental purpose only
        _user.userID = 1;
    }
    return self;
}

- (id)initWithUser:(RCUser *) user withLoggedinUser:(RCUser *)loggedinUser {
    self = [super init];
    if (self) {
        _user = user;
        _loggedinUser = loggedinUser;
        _connectionManager = [[RCConnectionManager alloc] init];

    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //set up custom back button
    if ([self.navigationController.viewControllers count] > 2)
        [self setupBackButton];
    
    //[_connectionManager reset];
    
    _friends = [[NSMutableArray alloc] init];
    _requested_friends = [[NSMutableArray alloc] init];
    _followees = [[NSMutableArray alloc] init];
    _tblViewFriendList.tableFooterView = [[UIView alloc] init];
    _searchResultList = [[NSMutableArray alloc] init];
    
    //add post button to navigation bar
    UIImage *postButtonImage = [UIImage imageNamed:@"buttonPost.png"];
    _postButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_postButton setFrame:CGRectMake(0,0,postButtonImage.size.width, postButtonImage.size.height)];
    [_postButton setBackgroundImage:postButtonImage forState:UIControlStateNormal];
    [_postButton addTarget:self action:@selector(switchToNewPostScreen) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithCustomView:_postButton];
    self.navigationItem.rightBarButtonItem = rightButton;
    
    controlButtonArray = [[NSArray alloc] initWithObjects:_btnFriends, _btnRequests, _btnFollowees, nil];
    
    //self.navigationItem.title = @"Friends";
    UITableViewController *tableViewController = setUpRefreshControlWithTableViewController(self, _tblViewFriendList);
    _refreshControl = tableViewController.refreshControl;
    [_refreshControl addTarget:self
                        action:@selector(handleRefresh:)
              forControlEvents:UIControlEventValueChanged  ];
    
    // Configure name & avatar display in friend list
    [_user getUserAvatarAsync:_user.userID completionHandler:^(UIImage* img){
        [_imgUserAvatar setImage:img];
    }];
    [_lblTableTitle setText:_user.name];
    
    // Configure search bar
    [_searchBar setDelegate:self];
    
    // Configure search bar BG frame
    searchBarHideFrame = searchBarShowFrame = _searchBarBackground.frame;
    searchBarHideFrame.origin.x += searchBarHideFrame.size.width*0.95;
    searchBarHideFrame.size.width = 0;
    
    // Configure search bar search button frame
    searchButtonHideFrame = _btnSearchBarCancel.frame;
    searchButtonShowFrame = _btnSearchBarToggle.frame;
    
    [self toggleSearchBar:NO animateWithDuration:0.0];
    
    // Creating new button because auto layout keep interferring with settings:
    UIButton* btnToggle = [[UIButton alloc] initWithFrame:searchButtonHideFrame];
    [btnToggle setImage:[UIImage imageNamed:@"friendListSearchBarToggle.png"] forState:UIControlStateNormal];
    [btnToggle addTarget:self action:@selector(btnSearchBarToggleTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [_btnSearchBarToggle removeFromSuperview];
    _btnSearchBarToggle = btnToggle;
    [self.view addSubview:btnToggle];
    
    UIButton* btnCancel = [[UIButton alloc] initWithFrame:searchButtonHideFrame];
    [btnCancel setImage:[UIImage imageNamed:@"friendListSearchBarCancel.png"] forState:UIControlStateNormal];
    [btnCancel addTarget:self action:@selector(btnSearchBarCancelTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [_btnSearchBarCancel removeFromSuperview];
    _btnSearchBarCancel = btnCancel;
    [self.view addSubview:btnCancel];
    
    // Load all lists once at the beginning, and default tab is friend tab:
    _viewingMode = RCFriendListViewModeFriends;
    _displayedItems = _friends;
    [self asynchGetFriendsRequest];
    [self asynchGetFolloweesRequest];
    [self asynchGetRequestedFriendsRequest];
    [self btnFriendTouchUpInside:self];
}

- (void) handleRefresh:(UIRefreshControl *) refreshControl {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:RCInfoStringDateFormat];
    NSString *lastUpdated = [NSString stringWithFormat:RCInfoStringLastUpdatedOnFormat, [formatter  stringFromDate:[NSDate date] ] ];
    
    UIColor *foregroundColor = [UIColor whiteColor];
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           foregroundColor, NSForegroundColorAttributeName, nil];
    
    NSAttributedString *attributedStr = [[NSAttributedString alloc] initWithString:lastUpdated attributes:attrs];
    [_refreshControl setAttributedTitle:attributedStr];
    
    switch (_viewingMode) {
        case RCFriendListViewModeFriends:
            [self asynchGetFriendsRequest];
            break;
        case RCFriendListViewModePendingFriends:
            [self asynchGetRequestedFriendsRequest];
            break;
        case RCFriendListViewModeFollowees:
            [self asynchGetFolloweesRequest];
            break;
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.searchDisplayController.searchResultsTableView)
        return [_searchResultList count];
    else
        return [_displayedItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //Where we configure the cell in each row
    
    RCUserTableCell *cell = [RCUserTableCell getFriendListTableCell:tableView];
    
    RCUser *user;// = [_items objectAtIndex:indexPath.row];
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        user = [_searchResultList objectAtIndex:indexPath.row];
    } else {
        user = [_displayedItems objectAtIndex:indexPath.row];
    }
    //[RCConnectionManager startConnection];
    [cell populateCellData:user
                  withLoggedInUserID:_loggedinUser.userID
                completion:^ { ;//[RCConnectionManager endConnection];
                }];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [RCUserTableCell cellHeight];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    RCUser *user;
    if (tableView == self.searchDisplayController.searchResultsTableView)
        user = [_searchResultList objectAtIndex:indexPath.row];
    else
        user = [_displayedItems objectAtIndex:indexPath.row];
    RCUserProfileViewController *detailViewController = [[RCUserProfileViewController alloc] initWithUser:user viewingUser:_loggedinUser];
    [self.navigationController pushViewController:detailViewController animated:YES];
}

/*- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *sectionName;
    switch (section)
    {
        default:
            switch (_viewingMode) {
                case RCFriendListViewModeFriends:
                    sectionName = @"Friends";
                    break;
                case RCFriendListViewModePendingFriends:
                    sectionName = @"Pending Requests";
                    break;
                case RCFriendListViewModeFollowees:
                    sectionName = @"People you follow";
                    break;
                default:
                    break;
            }
            break;
    }
    return sectionName;
}*/

#pragma mark - web request
- (void)asynchGetFriendsRequest {
    //Asynchronous Request
    [RCConnectionManager startConnection];
    @try {
            
            NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d/friends?mobile=1", RCServiceURL, RCUsersResource, _user.userID]];
            NSURLRequest *request = CreateHttpGetRequest(url);
            
            [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                                   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
            {
                [RCConnectionManager endConnection];
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
                    
                    if (_viewingMode == RCFriendListViewModeFriends)
                        [_tblViewFriendList reloadData];
                    
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
    [RCConnectionManager startConnection];
    @try {
        
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d/requested_friends?mobile=1", RCServiceURL, RCUsersResource, _user.userID]];
        NSURLRequest *request = CreateHttpGetRequest(url);
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             [RCConnectionManager endConnection];
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
                 
                 if (_viewingMode == RCFriendListViewModePendingFriends)
                    [_tblViewFriendList reloadData];
                 
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

- (void)asynchGetFolloweesRequest {
    //Asynchronous Request
    [RCConnectionManager startConnection];
    @try {
        
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d/followees?mobile=1", RCServiceURL, RCUsersResource, _user.userID]];
        NSURLRequest *request = CreateHttpGetRequest(url);
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             [RCConnectionManager endConnection];
             NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
             
             SBJsonParser *jsonParser = [SBJsonParser new];
             NSArray *usersJson = (NSArray *) [jsonParser objectWithString:responseData error:nil];
             NSLog(@"%@",usersJson);
             
             if (usersJson != NULL) {
                 [_followees removeAllObjects];
                 for (NSDictionary *userData in usersJson) {
                     RCUser *user = [[RCUser alloc] initWithNSDictionary:userData];
                     [_followees addObject:user];
                 }
                 if (_viewingMode == RCFriendListViewModeFollowees)
                     [_tblViewFriendList reloadData];
                 
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

- (IBAction)btnBackgroundTap:(id)sender {
    [_searchBar resignFirstResponder];
}

- (IBAction)btnSearchBarCancelTouchUpInside:(id)sender {
    _displayedItems = currentDisplayedItems;
    [self clearSearchBar];

}

- (IBAction)btnSearchBarToggleTouchUpInside:(id)sender {
    [self toggleSearchBar:showSearchBar animateWithDuration:0.5];
}

- (void)toggleSearchBar: (BOOL)show animateWithDuration:(NSTimeInterval)duration {
    if (!show) {
        showSearchBar = YES;
        [self btnSearchBarCancelTouchUpInside:self];
        [UIView animateWithDuration:duration animations:^{
            [_searchBarBackground setFrame:searchBarHideFrame];
            [_btnSearchBarToggle setFrame:searchButtonHideFrame];
            [_searchBarBackground.layer setOpacity:0.0];
        } completion:^(BOOL success){
            [_searchBarBackground setHidden:YES];
            [_searchBar setHidden:YES];
        }];
    }else {
        showSearchBar = NO;
        [_searchBarBackground setFrame:searchBarHideFrame];
        [_searchBarBackground setHidden:NO];
        [_searchBar setHidden:NO];
        [UIView animateWithDuration:duration animations:^{
            [_searchBarBackground setFrame:searchBarShowFrame];
            [_btnSearchBarToggle setFrame:searchButtonShowFrame];
            [_searchBarBackground.layer setOpacity:1.0];
        } completion:^(BOOL success){
            
        }];
    }
}

- (IBAction)btnFriendTouchUpInside:(id)sender {
    _viewingMode = RCFriendListViewModeFriends;
    _displayedItems = _friends;
    //[_searchBar setPlaceholder:@"Search for friends"];
    [_tableTitleBackground setImage:[UIImage imageNamed:@"friendListBarFriends"]];
    [_tableTitleLabel setText:@"Friends"];
    
    currentDisplayedItems = _displayedItems;
    [self clearSearchBar];
    [self enableControl:YES];
}

- (IBAction)btnRequestsTouchUpInside:(id)sender {
    _viewingMode = RCFriendListViewModePendingFriends;
    _displayedItems = _requested_friends;
    //[_searchBar setPlaceholder:@"Search for pending requests"];
    [_tableTitleBackground setImage:[UIImage imageNamed:@"friendListBarPending"]];
    [_tableTitleLabel setText:@"Pending requests"];
    
    currentDisplayedItems = _displayedItems;
    [self clearSearchBar];
    [self enableControl:YES];
}

- (IBAction)btnFolloweeTouchUpInside:(id)sender {
    _viewingMode = RCFriendListViewModeFollowees;
    _displayedItems = _followees;
    //[_searchBar setPlaceholder:@"Search for people you follow"];
    [_tableTitleBackground setImage:[UIImage imageNamed:@"friendListBarFollows"]];
    [_tableTitleLabel setText:@"People you follow"];
    
    currentDisplayedItems = _displayedItems;
    [self clearSearchBar];
    [self enableControl:YES];
}

- (void)enableControl: (BOOL)enable {
    for (UIButton *btn in controlButtonArray)
        btn.enabled = enable;
    switch (_viewingMode) {
        case RCFriendListViewModeFriends:
            _btnFriends.enabled = NO;
            break;
        case RCFriendListViewModeFollowees:
            _btnFollowees.enabled = NO;
            break;
        case RCFriendListViewModePendingFriends:
            _btnRequests.enabled = NO;
    }
}

- (void)clearSearchBar {
    [_btnSearchBarCancel setHidden:YES];
    [_searchBar setText:@""];
    [_searchBar resignFirstResponder];
    [_tblViewFriendList reloadData];
}

#pragma mark - search helper
- (void)filterContentForSearchText:(NSString*)searchText fromList:(NSArray*)parentList withScope:(NSString*)scope {
    // Update the filtered array based on the search text and scope.
    // Remove all objects from the filtered search array
    [_searchResultList removeAllObjects];
    // Filter the array using NSPredicate
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.name contains[c] %@",searchText];
    _searchResultList = [NSMutableArray arrayWithArray:[parentList filteredArrayUsingPredicate:predicate]];
}


#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *searchText = [_searchBar.text stringByReplacingCharactersInRange:range withString:string];
    NSLog(@"Textfield change, search text: %@", searchText);
    
    if ([searchText isEqualToString:@""]) {
        _displayedItems = currentDisplayedItems;
        [_btnSearchBarCancel setHidden:YES];
    }else {
        [self filterContentForSearchText:searchText fromList:currentDisplayedItems withScope:nil];
        _displayedItems = _searchResultList;
        [_btnSearchBarCancel setHidden:NO];
    }
    [_tblViewFriendList reloadData];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void) viewWillAppear:(BOOL)animated {
    [_tblViewFriendList reloadData];
}

- (void) switchToNewPostScreen {
    [_postButton setEnabled:NO];
    RCNewPostViewController *newPostController;
    if ([[UIScreen mainScreen] bounds].size.height < RCIphone5Height)
        newPostController = [[RCNewPostViewController alloc] initWithUser:_user withNibName:@"RCNewPostViewController4" bundle:nil];
    else
        newPostController = [[RCNewPostViewController alloc] initWithUser:_user withNibName:@"RCNewPostViewController" bundle:nil];
    newPostController.postComplete = ^{
        [_postButton setEnabled:YES];
    };
    newPostController.postCancel = ^{
        [_postButton setEnabled:YES];
    };
    
    [self presentViewController:newPostController animated:YES completion:nil];
}


@end
