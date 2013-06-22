//
//  RCFriendRequestsViewController.h
//  memcap
//
//  Created by Trinh Tuan Phuong on 22/6/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RCFriendRequestsViewController : UIViewController

@property (nonatomic, strong) NSArray* notifications;

- (id) initWithNotifications:(NSArray*) notifications;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
