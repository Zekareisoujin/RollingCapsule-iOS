//
//  RCFriendRequestsViewController.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 22/6/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCFriendRequestsViewController.h"
#import "RCNotification.h"

@interface RCFriendRequestsViewController ()

@end

@implementation RCFriendRequestsViewController


@synthesize notifications = _notifications;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id) initWithNotifications:(NSArray*) notifications {
    self = [super init];
    if (self) {
        _notifications = notifications;
    }
    return self;

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
/*
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

*/
@end
