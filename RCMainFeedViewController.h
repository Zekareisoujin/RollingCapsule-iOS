//
//  RCMainFeedViewController.h
//  Rolling Capsule
//
//  Created by Nguyen Phi Long Louis on 29/05/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "RCUser.h"

@interface RCMainFeedViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

- (id)initWithUser:(RCUser *) user;

@property (weak, nonatomic) IBOutlet UITableView *tblFeedList;
@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) RCUser *user;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) NSMutableDictionary *userCache;
@property (nonatomic, strong) NSMutableDictionary *postCache;

@end
