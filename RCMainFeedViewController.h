//
//  RCMainFeedViewController.h
//  Rolling Capsule
//
//  Created by Nguyen Phi Long Louis on 29/05/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RCMainFeedViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic,assign) int userID;
@property (weak, nonatomic) IBOutlet UITableView *tblFeedList;
@property (nonatomic, strong) NSMutableArray *items;

- (id)initWithUserID:(int) userID;

@end
