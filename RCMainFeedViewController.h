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

enum RCMainFeedViewMode {
    RCMainFeedViewModePublic,
    RCMainFeedViewModeFriends,
    RCMainFeedViewModeFollow
};
typedef enum RCMainFeedViewMode RCMainFeedViewMode;

@interface RCMainFeedViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, MKMapViewDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tblFeedList;
@property (weak, nonatomic) IBOutlet UIButton *btnViewModeFollow;
@property (weak, nonatomic) IBOutlet UILabel *lblUsername;
@property (weak, nonatomic) IBOutlet UIButton *btnViewModeFriends;
- (IBAction)btnViewModeChosen:(UIButton *)sender;
- (IBAction)btnCenterMapTouchUpInside:(id)sender;
@property (weak, nonatomic) IBOutlet UIImageView *imgViewUserAvatar;
@property (weak, nonatomic) IBOutlet UIButton *btnViewModePublic;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) RCUser *user;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) NSMutableDictionary *userCache;
@property (nonatomic, strong) NSMutableDictionary *postCache;
@property (nonatomic, strong) NSMutableSet *chosenPosts;

@end
