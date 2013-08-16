//
//  RCMainFeedViewController.m
//  Rolling Capsule
//
//  Created by Nguyen Phi Long Louis on 29/05/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCMainFeedViewController.h"
#import "RCUser.h"
#import "RCNotification.h"
#import "RCPost.h"
#import "RCFeed.h"
#import "RCConstants.h"
#import "RCUtilities.h"
#import "RCNewPostViewController.h"
#import "RCPostDetailsViewController.h"
#import "RCUserProfileViewController.h"
#import "RCAmazonS3Helper.h"
#import "RCMainFeedCell.h"
#import "RCMainMenuViewController.h"
#import "RCConnectionManager.h"
#import "RCUploadManager.h"
#import "RCAddLandmarkController.h"
#import "Reachability.h"
#import "UIImage+animatedGIF.h"
#import "SBJson.h"
#import "TTTAttributedLabel.h"
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>

#define NUM_RETRY_MAIN_FEED 5

@interface RCMainFeedViewController ()

@property (nonatomic, strong) RCConnectionManager *connectionManager;
@property (nonatomic, strong) NSMutableDictionary *postsByLandmark;
@property (nonatomic, strong) NSMutableDictionary *postsByRowIndex;
@property (nonatomic, strong) NSMutableArray *posts;
@property (nonatomic, assign) int currentLandmarkID;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchGestureRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGestureRecognizer;
@property (nonatomic, strong) UIImage *backgroundImage;
@property (nonatomic, assign) RCMainFeedViewMode      currentViewMode;
@property (nonatomic, strong) UIButton* postButton;
@property (nonatomic, strong) Reachability * reachability;
@property (nonatomic, strong) UILabel* lblWarningNoConnection;
@property (nonatomic, assign) BOOL didZoom;
@property (nonatomic, strong) NSTimer* autoRefresh;

@end

@implementation RCMainFeedViewController {
    // Feed page control:
    NSString    *address;
    int     currentPageNumber;
    int     currentMaxPostNumber;
    int     currentMaxDisplayedPostNumber;
    int     showThreshold;
    BOOL    willShowMoreFeeds;
    
    int         _nRows;
    BOOL        _firstRefresh;
    BOOL        _willRefresh;
    BOOL        _haveScreenshot;
    BOOL        _userCalloutVisible;
}

@synthesize refreshControl = _refreshControl;
@synthesize user = _user;
@synthesize connectionManager = _connectionManager;
@synthesize postsByLandmark = _postsByLandmark;
@synthesize currentLandmarkID = _currentLandmarkID;
@synthesize chosenPosts = _chosenPosts;
@synthesize pinchGestureRecognizer = _pinchGestureRecognizer;
@synthesize longPressGestureRecognizer = _longPressGestureRecognizer;
@synthesize tapGestureRecognizer = _tapGestureRecognizer;
@synthesize doubleTapGestureRecognizer = _doubleTapGestureRecognizer;
@synthesize backgroundImage = _backgroundImage;
@synthesize currentViewMode = _currentViewMode;
@synthesize postsByRowIndex = _postsByRowIndex;
@synthesize postButton = _postButton;
@synthesize posts = _posts;
@synthesize reachability = _reachability;
@synthesize lblWarningNoConnection = _lblWarningNoConnection;
@synthesize didZoom = _didZoom;

+ (NSString*) debugTag {
    return @"MainFeedView";
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _connectionManager = [[RCConnectionManager alloc] init];
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        _connectionManager = [[RCConnectionManager alloc] init];
        _postsByLandmark = [[NSMutableDictionary alloc] init];
        _chosenPosts = [[NSMutableSet alloc] init];
        _postsByRowIndex = [[NSMutableDictionary alloc] init];
        _posts = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //setup connectivity notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkChanged:) name:kReachabilityChangedNotification object:nil];
    
    _reachability = [Reachability reachabilityForInternetConnection];
    [_reachability startNotifier];
    
    //setup custom back button when necessary
    if ([self.navigationController.viewControllers count] > 2)
        [self setupBackButton];
    
    //reset view data
    [_chosenPosts removeAllObjects];
    _currentLandmarkID = -1;
    
    //customizing navigation bar
    self.navigationItem.title = @"";
    
    //add post button to navigation bar
    UIImage *postButtonImage = [UIImage imageNamed:@"buttonPost.png"];
    _postButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_postButton setFrame:CGRectMake(0,0,postButtonImage.size.width, postButtonImage.size.height)];
    [_postButton setBackgroundImage:postButtonImage forState:UIControlStateNormal];
    [_postButton addTarget:self action:@selector(switchToNewPostScreen) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithCustomView:_postButton] ;
    self.navigationItem.rightBarButtonItem = rightButton;
    
    //initializing display elements
    [_btnUserAvatar setImage:[UIImage standardLoadingImage] forState:UIControlStateNormal];
    
    //prepare collection view
    UICollectionViewFlowLayout *flow =  (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    flow.minimumInteritemSpacing = 0.0;
    _refreshControl = [[UIRefreshControl alloc] init];//tableViewController.refreshControl;
    //[_collectionView addSubview:_refreshControl];
    [_refreshControl addTarget:self
                        action:@selector(handleRefresh:)
              forControlEvents:UIControlEventValueChanged  ];
    _firstRefresh = YES;
    
    
    //prepare collection view cell
    NSString* cellIdentifier = [RCMainFeedCell cellIdentifier];
    [self.collectionView registerClass:[RCMainFeedCell class] forCellWithReuseIdentifier:cellIdentifier];
    UINib *nib = [UINib nibWithNibName:cellIdentifier bundle: nil];
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:cellIdentifier];
    
    //initialize regonizer for geesture on map
    _pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    _doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [_doubleTapGestureRecognizer setNumberOfTapsRequired:2];
    //[_tapGestureRecognizer requireGestureRecognizerToFail:_doubleTapGestureRecognizer];
    
    //set the current view mode of the view, the default view is public
    _currentViewMode = RCMainFeedViewModePublic;
    _btnViewModePublic.enabled = NO;
    
    
    //initialize miscellaneaous constants
    _nRows = [[NSUserDefaults standardUserDefaults] integerForKey:RCMainFeedRowCountSetting];
    if (_nRows == 0) _nRows = 3; //default settings
    _willRefresh = YES; //indicate whether this view will refresh after returning from another view
    showThreshold = 8;
    
    [self showMoreFeedButton:NO animate:NO];
    
    //set up visual components for displaying hidden capsule
    _userCalloutVisible = NO;
    _mapView.showsUserLocation = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRefresh:) name:RCNotificationNameMediaUploaded object:nil];
    
}

- (IBAction) showHiddenCapsulesMessage:(id) sender{
    if (_userCalloutVisible)
        [_mapView deselectAnnotation:_mapView.userLocation animated:YES];
    else
        [_mapView selectAnnotation:_mapView.userLocation animated:YES];
}

- (void)networkChanged:(NSNotification *)notification
{
    
    NetworkStatus remoteHostStatus = [_reachability currentReachabilityStatus];
    
    if(remoteHostStatus == NotReachable) {
        NSLog(@"not reachable");
        [self showNoConnectionWarningMessage];
    }
    else {
        [self hideNoConnectionWarningMessage];
        if (remoteHostStatus == ReachableViaWiFi) {
            NSLog(@"wifi");
            }
        else if (remoteHostStatus == ReachableViaWWAN) { NSLog(@"wwan"); }
    }
}

- (void) handleRefresh:(UIRefreshControl*) refreshControl {
    if (_autoRefresh != nil)
        [_autoRefresh invalidate];

    [self btnCenterMapTouchUpInside:nil];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:RCInfoStringDateFormat];
    NSString *lastUpdated = [NSString stringWithFormat:RCInfoStringLastUpdatedOnFormat, [formatter  stringFromDate:[NSDate date] ] ];
    [_refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:lastUpdated]];
    [self toggleButtonRefresh:YES];
    willShowMoreFeeds = NO;
    if (_currentViewMode == RCMainFeedViewModeCommented) {
        _posts = [[NSMutableArray alloc] init];

        NSMutableArray* commentedPosts = [RCNotification getNotifiedPosts];
        [_posts addObjectsFromArray:commentedPosts];
        currentMaxDisplayedPostNumber = [_posts count];
        NSLog(@"notified post [self reloadData");
        [self reloadData];
        if ([_reachability currentReachabilityStatus] == NotReachable) {
            [self showNoConnectionWarningMessage];
            return;
        }
        [RCNotification loadMissingNotifiedPostsForList:_posts withCompletion:^{
            NSLog(@"notified posts reload data, this is when images in notifications are loaded");
            [_collectionView reloadData];
        }];
        [self toggleButtonRefresh:NO];
    } else {
        [self loadFeed:NUM_RETRY_MAIN_FEED];
	}
}

- (void) loadFeed:(int) nRetry {
    RCFeed *feed = [self feedByCurrentViewMode];
    _posts = feed.postList;
    currentMaxDisplayedPostNumber = currentMaxPostNumber = [_posts count];
    NSLog(@"loading feed current view mode is %d",_currentViewMode);
    [self reloadData];
    //CAREFUL sync (concurrent crash) issue may happen here
    if ([_reachability currentReachabilityStatus] == NotReachable) {
        [self showNoConnectionWarningMessage];
        return;
    }
    
    [_lblNoPost setHidden:YES];
    [feed fetchFeedFromBackend:RCFeedFetchModeReset completion:^{
        if ([feed isEqual:[self feedByCurrentViewMode]]) {
            if (feed.errorType != RCFeedNoError && nRetry > 0) {
                [self loadFeed:nRetry-1];
            } else {
                currentMaxDisplayedPostNumber = currentMaxPostNumber = [feed.postList count];
                _posts = feed.postList;
                
                [_lblNoPost setHidden:([_posts count] > 0 || ([_reachability currentReachabilityStatus] == NotReachable))];
                switch (_currentViewMode) {
                    case RCMainFeedViewModePublic:
                        [_lblNoPost setText:RCMainFeedNoPostPublic];
                        break;
                    case RCMainFeedViewModeFriends:
                        [_lblNoPost setText:RCMainFeedNoPostFriends];
                        break;
                    case RCMainFeedViewModeFollow:
                        [_lblNoPost setText:RCMainFeedNoPostFollows];
                        break;
                    case RCMainFeedViewModeCommented:
                        [_lblNoPost setText:RCMainFeedNoPostCommented];
                        break;
                    default:
                        break;
                }
                
                NSLog(@"reload feed after successful refresh");
                [self reloadData];
                [self toggleButtonRefresh:NO];
                [self updateUserUIElements:[RCUser currentUser]];
            }
        }
    }];
}

- (void) reloadData {
    NSLog(@"in [self reloadData]");
    [_chosenPosts removeAllObjects];
    [_mapView removeAnnotations:_mapView.annotations];
    [_postsByRowIndex removeAllObjects];
    int i = 0;
    for (RCPost*post in _posts) {
        [_postsByRowIndex setObject:[NSNumber numberWithInt:i] forKey:[NSNumber numberWithInt:post.postID]];
        [_mapView addAnnotation:post];
        i++;
    }
    if ([RCNotification numberOfNewNotifications] > 0)
        [_imgViewNewNotificationNotice setHidden:NO];
    else
        [_imgViewNewNotificationNotice setHidden:YES];
    NSLog(@"before reloading collection view reloadData");
    [_collectionView reloadData];

}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([scrollView isEqual:_collectionView]) {
        UICollectionViewCell* cell = [_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:currentMaxDisplayedPostNumber-1 inSection:0]];
        if (cell != nil) {
            //NSLog(@"show more feed button");
            [self showMoreFeedButton:YES animate:YES];
        } else {
            [self showMoreFeedButton:NO animate:YES];
        }
    }
}

- (RCFeed*) feedByCurrentViewMode {
    RCFeed *feed = nil;
    switch (_currentViewMode) {
        case RCMainFeedViewModePublic:
            feed = [RCFeed locationFeed];
            [RCFeed updateLocation];
            break;
        case RCMainFeedViewModeFriends:
            feed = [RCFeed friendFeed];
            break;
        case RCMainFeedViewModeFollow:
            feed = [RCFeed followFeed];
            break;
        default:break;
    }
    return feed;
}

- (void) updateUserUIElements:(RCUser *)user {
    self.user = user;
    [_lblUsername setText: _user.name];
    [_lblUsername setLinkAttributes:[[_lblUsername attributedText] attributesAtIndex:0 effectiveRange:nil]];
    [_lblUsername setActiveLinkAttributes:[[_lblUsername attributedText] attributesAtIndex:0 effectiveRange:nil]];
    [_lblUsername addLinkToURL:[NSURL URLWithString:[NSString stringWithFormat:@"memcap:/%@/%d?user[name]=%@",RCUsersResource,_user.userID, urlEncodeValue(_user.name)]] withRange:NSMakeRange(0,[_lblUsername.text length])];
    [_lblUsername setDelegate:(AppDelegate*)[[UIApplication sharedApplication] delegate]];
    [_lblUsername setAdjustsFontSizeToFitWidth:YES];
    
    [_user getUserAvatarAsync:_user.userID completionHandler:^(UIImage* retAvatar){
        dispatch_async(dispatch_get_main_queue(),^{
            [_btnUserAvatar setImage:retAvatar forState:UIControlStateNormal];
        });
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [AppDelegate cleanupMemory];
    // Dispose of any resources that can be recreated.
}

- (void) showNoConnectionWarningMessage {
    _btnRefresh.enabled = NO;
        if (_lblWarningNoConnection == nil) {
        _lblWarningNoConnection = [[UILabel alloc] init];
        _lblWarningNoConnection.text = @"No Internet Connection";
        _lblWarningNoConnection.textAlignment = NSTextAlignmentCenter;
        _lblWarningNoConnection.textColor = [ UIColor whiteColor];
        [_lblWarningNoConnection setBackgroundColor:[UIColor colorWithRed:200.0/255.0 green:50.0/255.0 blue:50.0/255.0 alpha:0.9]];
    }
    
    [self.view addSubview:_lblWarningNoConnection];
    _lblWarningNoConnection.frame = CGRectMake(0,42,self.view.frame.size.width,0);
    [UIView animateWithDuration:0.5 animations:^{
        CGRect frame2 = _lblWarningNoConnection.frame;
        frame2.size.height += 20;
        _lblWarningNoConnection.frame = frame2;
    }];
}

- (void) hideNoConnectionWarningMessage {
    [UIView animateWithDuration:0.5 animations:^{
        CGRect frame = _lblWarningNoConnection.frame;
        frame.size.height = 0;
        _lblWarningNoConnection.frame = frame;
    } completion:^(BOOL finished){
        [_lblWarningNoConnection removeFromSuperview];
        _btnRefresh.enabled = YES;
    }];
}

- (void) switchToNewPostScreen {
    RCNewPostViewController *newPostController;
    if ([[UIScreen mainScreen] bounds].size.height < RCIphone5Height)
        newPostController = [[RCNewPostViewController alloc] initWithUser:_user withNibName:@"RCNewPostViewController4" bundle:nil];
    else
        newPostController = [[RCNewPostViewController alloc] initWithUser:_user withNibName:@"RCNewPostViewController" bundle:nil];

    [self.navigationController pushViewController:newPostController animated:YES];
}

#pragma mark - UICollectionView Datasource
// 1
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    return currentMaxDisplayedPostNumber;
}
// 2
- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}
// 3
- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString* cellIdentifier = [RCMainFeedCell cellIdentifier];
    RCMainFeedCell *cell = [cv dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    RCPost *post;
    post = [_posts objectAtIndex:indexPath.row];
    [cell initCellAppearanceForPost:post];
    if ([_chosenPosts count] != 0) {
        if ([_chosenPosts containsObject:[[NSNumber alloc] initWithInt:post.postID]]) {
            [cell changeCellState:RCCellStateFloat];
        } else {
            [cell changeCellState:RCCellStateDimmed];
        }
    }
    
    // Pulling next page if necessary:
    if (indexPath.row == (currentMaxPostNumber - 1)) {
        RCFeed *feed = [self feedByCurrentViewMode];
        int formerPostCount = currentMaxPostNumber;
        currentMaxPostNumber = -1;
        [feed fetchFeedFromBackend:RCFeedFetchModeAppendBack completion:^{
            if ([feed isEqual:[self feedByCurrentViewMode]]) {
                if ([feed.postList count] != formerPostCount) {
                    currentMaxPostNumber = [feed.postList count];
                    willShowMoreFeeds = YES;
                    [self scrollViewDidScroll:_collectionView];
                }
            }
        }];
    }
    
    return cell;
}
// 4
/*- (UICollectionReusableView *)collectionView:
 (UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
 {
 return [[UICollectionReusableView alloc] init];
 }*/

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
}

#pragma mark – UICollectionViewDelegateFlowLayout

// 1
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    float width = (collectionView.frame.size.height-42) / _nRows;
    CGSize retval = CGSizeMake(width,width);
    return retval;
}

// 3
- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(20, 10, 20, 10);//UIEdgeInsetsM
}

#pragma mark - MKMapViewDelegate
- (void) processTogglingPost:(RCPost*) post {
    int index = [[_postsByRowIndex objectForKey:[NSNumber numberWithInt:post.postID]] intValue];
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    [self selectPostAtIndexPath:indexPath];
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    if ([view.annotation isKindOfClass:[MKUserLocation class]]){
        _userCalloutVisible = YES;
    }
    if ([view.annotation isKindOfClass:[RCPost class]]){
        @try {
            [self processTogglingPost:(RCPost*)view.annotation];
        }@catch (NSException* exception) {
            NSLog(@"excpetion occured selecting post %d in view mode %d",((RCPost*)view.annotation).postID, _currentViewMode);
        }
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    if ([view.annotation isKindOfClass:[MKUserLocation class]]){
        _userCalloutVisible = NO;
    }
    if ([view.annotation isKindOfClass:[RCPost class]]){
        @try {
            [self processTogglingPost:(RCPost*)view.annotation];
        }@catch (NSException* exception) {
            NSLog(@"excpetion occured selecting post %d in view mode %d",((RCPost*)view.annotation).postID, _currentViewMode);
        }
    }
}

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        if ([_lblCapsuleCount.text length] > 0 && !_lblCapsuleCount.hidden && !_viewCapsuleCount.hidden) {
            NSString* countText = _lblCapsuleCount.text;
            countText = [countText isEqualToString:@"0"] ? @"No" : countText;
            [(MKUserLocation*)annotation setTitle: [NSString stringWithFormat:@"%@ hidden capsule(s)", countText]];
        } else
            [(MKUserLocation*)annotation setTitle:@"Current location"];
        return nil;
    }
    
    if ([annotation isKindOfClass:[RCPost class]]) {
        RCPost *post = (RCPost*) annotation;
        NSString *annotationIdentifier = @"landmark";
        MKAnnotationView *postButton = (MKAnnotationView*) [mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
        if (postButton == nil)
            postButton = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
        if (post.topic != nil) {
            postButton.canShowCallout = YES;
            NSString *imageName = [NSString stringWithFormat:@"topicCategory%@.png",post.topic];
            UIImage *scaledLandmarkImage = imageWithImage([UIImage imageNamed:imageName], CGSizeMake(35,35));
            [postButton setImage:scaledLandmarkImage];
            return (MKAnnotationView*)postButton;
        } else return nil;
        
    }
    return nil;
}

#pragma mark - view event

- (void) viewWillAppear:(BOOL)animated {

    //add gesture recognizer
    [super viewWillAppear:animated];
    [_collectionView addGestureRecognizer:_pinchGestureRecognizer];
    [_collectionView addGestureRecognizer:_tapGestureRecognizer];
    [_collectionView addGestureRecognizer:_longPressGestureRecognizer];
    [_collectionView addGestureRecognizer:_doubleTapGestureRecognizer];
    
    //prepare user UI element
    if (_user != nil) {
        [self updateUserUIElements:_user];
    }
}

- (void) viewWillDisappear:(BOOL)animated {
    [self hideNoConnectionWarningMessage];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (_willRefresh) {
        [self handleRefresh:_refreshControl];
        _willRefresh = NO;
    }
}

#pragma mark - pinch gesture recognizer

- (IBAction)handlePinch:(UIPinchGestureRecognizer *)recognizer {
    NSLog(@"Main-feed:pinch scale %f",recognizer.scale);
    if ([recognizer state] == UIGestureRecognizerStateBegan) {
        _didZoom = NO;
    } else {
        int maximumRow = [UIScreen mainScreen].bounds.size.height < RCIphone5Height ? 3 : 4;
        if (recognizer.scale > 1.5 && _nRows > 1 && !_didZoom) {
            _nRows--;
            _didZoom = YES;
            NSLog(@"reload data after zoom -- rows");
            [_collectionView reloadData];
        }
        if (recognizer.scale < 0.8 && _nRows < maximumRow && !_didZoom) {
            _didZoom = YES;
            _nRows++;
            NSLog(@"reload data after zoom ++ rows");
            [_collectionView reloadData];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setInteger:_nRows forKey:RCMainFeedRowCountSetting];
    float width = (_collectionView.frame.size.height-42) / _nRows;
    int numCell = [[UIScreen mainScreen] bounds].size.width / width + 0.5;
    numCell++;
    showThreshold = numCell * _nRows;
}

- (void) selectPostAtIndexPath:(NSIndexPath*) indexPath {
    int idx = [indexPath row];
    RCPost *post = [_posts objectAtIndex:idx];
    
    RCMainFeedCell* currentCell = (RCMainFeedCell *)[_collectionView cellForItemAtIndexPath:indexPath];
    
    NSNumber *key = [[NSNumber alloc] initWithInt:post.postID];
    if ([_chosenPosts containsObject:key]) {
        [_chosenPosts removeObject:key];
        if ([_chosenPosts count] == 0) {
            [currentCell changeCellState:RCCellStateNormal];
            for (UICollectionViewCell* cell in _collectionView.visibleCells) {
                RCMainFeedCell *feedCell = (RCMainFeedCell *)cell;
                [feedCell changeCellState:RCCellStateNormal];
            }
        } else {
            [currentCell changeCellState:RCCellStateDimmed];
        }
    } else {
        [currentCell changeCellState:RCCellStateFloat];
        for (RCPost* post in _chosenPosts)
            [_mapView deselectAnnotation:post animated:YES];
        [_chosenPosts removeAllObjects];
        [_chosenPosts addObject:[[NSNumber alloc] initWithInt:post.postID]];
        for (UICollectionViewCell* cell in _collectionView.visibleCells) {
            RCMainFeedCell *feedCell = (RCMainFeedCell *)cell;
            int index = [[_collectionView indexPathForCell:cell] row];
            RCPost *iteratingPost = [_posts objectAtIndex:index];
            NSNumber *key = [[NSNumber alloc] initWithInt:iteratingPost.postID];
            //if post not chosen then dim
            if (![_chosenPosts containsObject:key])
                [feedCell changeCellState:RCCellStateDimmed];
        }
        [_collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
        
    }
}

- (IBAction)handleTap:(UITapGestureRecognizer *)recognizer {
    CGPoint point = [recognizer locationInView:_collectionView];
    NSIndexPath *indexPath = [_collectionView indexPathForItemAtPoint:point];
    if (recognizer.numberOfTouches > 1) return;
    //if there's no item at point of tap
    if (indexPath != nil) {
        RCPost *post = [_posts objectAtIndex:indexPath.row];
        if ([_chosenPosts containsObject:[NSNumber numberWithInt:post.postID]])
            [_mapView deselectAnnotation:post animated:YES];
        else
            [_mapView selectAnnotation:post animated:YES];
    }
}

- (IBAction)handleLongPress:(UIGestureRecognizer *)recognizer {
    if ((recognizer.state == UIGestureRecognizerStateBegan && recognizer == _longPressGestureRecognizer) || recognizer == _doubleTapGestureRecognizer) {
        CGPoint point = [recognizer locationInView:_collectionView];
        NSIndexPath *indexPath = [_collectionView indexPathForItemAtPoint:point];
        
        //if index path for cell not found
        if (indexPath != nil ) {
            [_collectionView removeGestureRecognizer:_pinchGestureRecognizer];
            [_collectionView removeGestureRecognizer:_tapGestureRecognizer];
            [_collectionView removeGestureRecognizer:_longPressGestureRecognizer];
            [_collectionView removeGestureRecognizer:_doubleTapGestureRecognizer];
            RCPost *post;
            
            post = [_posts objectAtIndex:indexPath.row];
            RCUser *owner = [RCUser getUserOwnerOfPost:post];
            //check if this is a post with notification
            NSMutableArray* associatedNotifications = [RCNotification notificationsForResource:[NSString stringWithFormat:@"posts/%d",post.postID]];
            if (associatedNotifications != nil) {                
                for (RCNotification* notification in associatedNotifications)
                    if (notification != nil) {
                        [notification updateViewedProperty];
                    }
            }
            
            RCPostDetailsViewController *postDetailsViewController = [[RCPostDetailsViewController alloc] initWithPost:post withOwner:owner withLoggedInUser:_user editable:NO];
            postDetailsViewController.deleteFunction = ^{
                [self handleRefresh:_refreshControl];
            };
            postDetailsViewController.landmarkID = post.landmarkID;
            [self.navigationController pushViewController:postDetailsViewController animated:YES];
        }
    }
}

- (IBAction)btnViewModeChosen:(UIButton *)sender {
    
    if ([sender isEqual:_btnViewModePublic]) {
        NSString* trimString = [_lblCapsuleCount.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] ];
        if ([trimString length] > 0)
            [_viewCapsuleCount setHidden:NO];
        _currentViewMode = RCMainFeedViewModePublic;
        _btnViewModeFriends.enabled = YES;
        _btnViewModeFollow.enabled = YES;
        _btnViewModeCommented.enabled = YES;
    } else {
        [self hideCapsuleCounter];
        if ([sender isEqual:_btnViewModeFriends]) {
            _currentViewMode = RCMainFeedViewModeFriends;
            _btnViewModePublic.enabled = YES;
            _btnViewModeFollow.enabled = YES;
            _btnViewModeCommented.enabled = YES;
        } else if ([sender isEqual:_btnViewModeFollow]) {
            _currentViewMode = RCMainFeedViewModeFollow;
            _btnViewModeFriends.enabled = YES;
            _btnViewModePublic.enabled = YES;
            _btnViewModeCommented.enabled = YES;
        } else if ([sender isEqual:_btnViewModeCommented]) {
            _currentViewMode = RCMainFeedViewModeCommented;
            _btnViewModeFriends.enabled = YES;
            _btnViewModePublic.enabled = YES;
            _btnViewModeFollow.enabled = YES;
        }
    }
    sender.enabled = NO;
    [self handleRefresh:_refreshControl];
}

- (IBAction)btnCenterMapTouchUpInside:(id)sender {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    CLLocationCoordinate2D zoomLocation = appDelegate.currentLocation.coordinate;
    NSLog(@"current location %f %f", zoomLocation.longitude, zoomLocation.latitude);
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, 0.5*METERS_PER_MILE, 0.5*METERS_PER_MILE);
    [_mapView setRegion:viewRegion animated:YES];
}

- (IBAction)btnUserAvatarTouchUpInside:(id)sender {
    RCUserProfileViewController *userProfileViewController = [[RCUserProfileViewController alloc] initWithUser:_user viewingUser:_user];
    [self.navigationController pushViewController:userProfileViewController animated:YES];
}

- (IBAction)actionAddLandmark:(id)sender {
    RCAddLandmarkController *addLandmarkController = [[RCAddLandmarkController alloc] init];
    [self.navigationController pushViewController:addLandmarkController animated:YES];
}

- (IBAction)btnRefreshTouchUpInside:(id)sender {
    [self handleRefresh:_refreshControl];
}

- (IBAction)btnMoreFeedClicked:(id)sender {
    [self showMoreFeedButton:NO animate:NO];
    willShowMoreFeeds = NO;
    for (int i = currentMaxDisplayedPostNumber; i < [_posts count]; i++) {
        RCPost *post = [_posts objectAtIndex:i];
        [_postsByRowIndex setObject:[NSNumber numberWithInt:i] forKey:[NSNumber numberWithInt:post.postID]];
        [_mapView addAnnotation:post];
    }
    currentMaxDisplayedPostNumber = [_posts count];
    NSLog(@"reload data after cliking more feed button");
    [_collectionView reloadData];
}

- (void) toggleButtonRefresh: (BOOL)animate {
    if (animate) {
        [_btnRefresh setEnabled:NO];
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"buttonRefresh" withExtension:@"gif"];
        [_btnRefresh setImage:[UIImage animatedImageWithAnimatedGIFURL:url] forState:UIControlStateNormal];
    }else {
        [_btnRefresh setEnabled:YES];
        [_btnRefresh setImage:[UIImage imageNamed:@"buttonRefresh.gif"] forState:UIControlStateNormal];
    }
}

- (void) setCurrentUser: (RCUser*) user {
    _user = user;
}

- (void) showMoreFeedButton: (BOOL)show animate:(BOOL)animate {
    float duration = (animate?0.5:0.0);
    
    if (show && willShowMoreFeeds) {
        [_btnMoreFeed setHidden:NO];
        [UIView animateWithDuration:duration animations:^{
            [_btnMoreFeed.layer setOpacity:1.0];
        }];
    }else {
        [UIView animateWithDuration:duration animations:^{
            [_btnMoreFeed.layer setOpacity:0.0];
        }completion:^(BOOL complete){
            if (complete)
                [_btnMoreFeed setHidden:show];
        }];
    }
}

- (void) showCapsuleCounter {
    [_viewCapsuleCount setHidden:NO];
    [_btnShowHiddenCapsulesMessage setHidden:NO];
}

- (void) hideCapsuleCounter {
    [_viewCapsuleCount setHidden:YES];
    [_btnShowHiddenCapsulesMessage setHidden:YES];
}

@end
