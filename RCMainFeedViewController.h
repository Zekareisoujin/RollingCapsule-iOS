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
    RCMainFeedViewModeFollow,
    RCMainFeedViewModeCommented
};
typedef enum RCMainFeedViewMode RCMainFeedViewMode;

@interface RCMainFeedViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, MKMapViewDelegate, UIGestureRecognizerDelegate, UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imgViewNewNotificationNotice;
- (IBAction)btnUserAvatarTouchUpInside:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *btnRefresh;

@property (weak, nonatomic) IBOutlet UITableView *tblFeedList;
@property (weak, nonatomic) IBOutlet UIButton *btnViewModeFollow;
@property (weak, nonatomic) IBOutlet UIView *viewCapsuleCount;
@property (weak, nonatomic) IBOutlet UIImageView *imgViewCapsuleCount;
@property (weak, nonatomic) IBOutlet UIButton *btnShowHiddenCapsulesMessage;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *lblUsername;
@property (weak, nonatomic) IBOutlet UILabel *lblCapsuleCount;
@property (weak, nonatomic) IBOutlet UIButton *btnViewModeCommented;
@property (weak, nonatomic) IBOutlet UIButton *btnViewModeFriends;
@property (weak, nonatomic) IBOutlet UIButton *btnUserAvatar;
@property (weak, nonatomic) IBOutlet UIButton *btnViewModePublic;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIButton *btnMoreFeed;
@property (weak, nonatomic) IBOutlet UILabel *lblNoPost;

@property (nonatomic, strong) NSMutableSet *chosenPosts;
@property (nonatomic, strong) RCUser *user;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
- (IBAction)actionAddLandmark:(id)sender;
- (IBAction)btnViewModeChosen:(UIButton *)sender;
- (IBAction)btnCenterMapTouchUpInside:(id)sender;
- (IBAction)btnRefreshTouchUpInside:(id)sender;
- (IBAction)btnMoreFeedClicked:(id)sender;
- (IBAction) showHiddenCapsulesMessage:(id) sender;
- (void) setCurrentUser: (RCUser*) user;
@end
