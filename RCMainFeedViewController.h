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
#import "UIViewController+RCCustomBackButtonViewController.h"

enum RCMainFeedViewMode {
    RCMainFeedViewModePublic,
    RCMainFeedViewModeFriends,
    RCMainFeedViewModeFollow
};
typedef enum RCMainFeedViewMode RCMainFeedViewMode;

@interface RCMainFeedViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, MKMapViewDelegate, UIGestureRecognizerDelegate>
- (IBAction)btnUserAvatarTouchUpInside:(id)sender;

@property (weak, nonatomic) IBOutlet UITableView *tblFeedList;
@property (weak, nonatomic) IBOutlet UIButton *btnViewModeFollow;
@property (weak, nonatomic) IBOutlet UILabel *lblUsername;
@property (weak, nonatomic) IBOutlet UIButton *btnViewModeFriends;
@property (weak, nonatomic) IBOutlet UIButton *btnUserAvatar;
@property (weak, nonatomic) IBOutlet UIButton *btnViewModePublic;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIButton *btnMoreFeed;

@property (nonatomic, strong) NSMutableDictionary *userCache;
@property (nonatomic, strong) NSMutableDictionary *postCache;
@property (nonatomic, strong) NSMutableSet *chosenPosts;
@property (nonatomic, strong) RCUser *user;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
- (IBAction)actionAddLandmark:(id)sender;
- (IBAction)btnViewModeChosen:(UIButton *)sender;
- (IBAction)btnCenterMapTouchUpInside:(id)sender;
- (IBAction)btnRefreshTouchUpInside:(id)sender;
- (IBAction)btnMoreFeedClicked:(id)sender;

- (void) setCurrentUser: (RCUser*) user;
@end
