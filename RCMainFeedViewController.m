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
    if ([_reachability currentReachabilityStatus] == NotReachable) {
        [self showNoConnectionWarningMessage];
        return;
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:RCInfoStringDateFormat];
    NSString *lastUpdated = [NSString stringWithFormat:RCInfoStringLastUpdatedOnFormat, [formatter  stringFromDate:[NSDate date] ] ];
    [_refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:lastUpdated]];
    [self toggleButtonRefresh:YES];
    if (_currentViewMode == RCMainFeedViewModeCommented) {
        [_chosenPosts removeAllObjects];
        [_postsByRowIndex removeAllObjects];
        [_posts removeAllObjects];
        [_mapView removeAnnotations:_mapView.annotations];

        NSMutableArray* commentedPosts = [RCNotification getNotifiedPosts];
        [_posts addObjectsFromArray:commentedPosts];
        [_collectionView reloadData];
        [RCNotification loadMissingNotifiedPostsForList:_posts withCompletion:^{
            [_collectionView reloadData];
        }];
        [self toggleButtonRefresh:NO];
    } else 
        [self asynchFetchFeeds:NUM_RETRY_MAIN_FEED];
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

- (void) processNotificationListJson:(NSArray*) notificationListJson {
    [RCNotification clearNotifications];
    for (NSDictionary *notificationJson in notificationListJson) {
        [RCNotification parseNotification:notificationJson];
    }
}

- (void) asynchFetchFeeds:(int)nRetry {
    BOOL failed = YES;
    while (failed && nRetry--) {
        failed = NO;
        //Asynchronous Request
        @try {
            currentPageNumber = 1;
            currentMaxDisplayedPostNumber = currentMaxPostNumber = currentPageNumber * RCPostPerPage;
            
            [RCConnectionManager startConnection];
            AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
            CLLocationCoordinate2D zoomLocation = appDelegate.currentLocation.coordinate;

            switch(_currentViewMode) {
                case RCMainFeedViewModePublic:
                    address = [[NSString alloc] initWithFormat:@"%@?mobile=1&latitude=%f&longitude=%f&%@", RCServiceURL, zoomLocation.latitude, zoomLocation.longitude, RCLevelsQueryString];
                    break;
                case RCMainFeedViewModeFollow:
                    address = [[NSString alloc] initWithFormat:@"%@?mobile=1&view_follow=1", RCServiceURL];
                    break;
                case RCMainFeedViewModeFriends:
                    address = [[NSString alloc] initWithFormat:@"%@?mobile=1", RCServiceURL];
                    break;
                default:
                    return;
                    break;
            }
            NSLog(@"Main-Feed: get feed address:%@",address);
            NSURL *url=[NSURL URLWithString:address];
            NSURLRequest *request = CreateHttpGetRequest(url);
            
            [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                                   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
            {
                [RCConnectionManager endConnection];
                [_refreshControl endRefreshing];
                
                NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                if ([responseData isEqualToString:@"Unauthorized"]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
                        [appDelegate.menuViewController btnActionLogOut:nil];
                    });
                    return;
                }                
                SBJsonParser *jsonParser = [SBJsonParser new];
                NSDictionary *jsonData = (NSDictionary *) [jsonParser objectWithString:responseData error:nil];
                
#if DEBUG==1
                NSLog(@"%@%@",[RCMainFeedViewController debugTag], responseData);
#endif
                
                if (jsonData != NULL) {
                    [_chosenPosts removeAllObjects];
                    [_postsByRowIndex removeAllObjects];
                    [_posts removeAllObjects];
                    [_mapView removeAnnotations:_mapView.annotations];
                    
                    NSArray* notificationListJson = [jsonData objectForKey:@"notification_list"];
                    [self processNotificationListJson:notificationListJson];

                    NSArray *postList = (NSArray *) [jsonData objectForKey:@"post_list"];
                    int numCapsules = [[jsonData objectForKey:@"unreleased_capsules_count"] intValue];
                    if (numCapsules > 0) {
                        [self showCapsuleCounter];
                        _lblCapsuleCount.text = [NSString stringWithFormat:@"%d",numCapsules];
                    }
                    NSDictionary *userDictionary = (NSDictionary *) [jsonData objectForKey:@"user"];
                    //_user = [[RCUser alloc] initWithNSDictionary:userDictionary];
                    _user = [RCUser getUserWithNSDictionary:userDictionary];
                    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                    [_lblUsername setText: _user.name];
                    [_lblUsername addLinkToURL:[NSURL URLWithString:[NSString stringWithFormat:@"memcap:/%@/%d?user[name]=%@",RCUsersResource,_user.userID, urlEncodeValue(_user.name)]] withRange:NSMakeRange(0,[_lblUsername.text length])];
                    
                    [_user getUserAvatarAsync:_user.userID completionHandler:^(UIImage* img){
                         dispatch_async(dispatch_get_main_queue(), ^{
                             [_btnUserAvatar setImage:img forState:UIControlStateNormal];
                         });
                     }];
                    
                    [appDelegate setCurrentUser:_user];
                    for (NSDictionary *postData in postList) {
                        RCPost *post = [RCPost getPostWithNSDictionary:postData];
                        [_postsByRowIndex setObject:[NSNumber numberWithInt:[_posts count]] forKey:[NSNumber numberWithInt:post.postID]];
                        [_posts addObject:post];
                        [_mapView addAnnotation:post];
                    }
                    willShowMoreFeeds = ([_posts count] == currentMaxPostNumber);
                    
                    
                    [_collectionView reloadData];
                    [self toggleButtonRefresh:NO];
                    
                    return;
                } else {
                    NSLog(@"error: %@",error);
                    if (nRetry == 0) {
                        postNotification(RCErrorMessageFailedToGetFeed);
                        [self toggleButtonRefresh:NO];
                    }else {
                        [self asynchFetchFeeds:nRetry];
                    }
                }
                _autoRefresh = [NSTimer scheduledTimerWithTimeInterval:10*60 block:^(NSTimeInterval time){
                    [self handleRefresh:_refreshControl];
                } repeats:NO];
            }];
        }
        @catch (NSException * e) {
            NSLog(@"Exception: %@", e);
            failed = YES;
        }
    }
    if (failed) {
        postNotification(RCErrorMessageFailedToGetFeed);
        _autoRefresh = [NSTimer scheduledTimerWithTimeInterval:10*60 block:^(NSTimeInterval time){
            [self handleRefresh:_refreshControl];
        } repeats:NO];
    }
}

- (void) asynchFetchFeedNextPage {
    //Asynchronous Request
    @try {
        currentPageNumber++;
        currentMaxPostNumber = currentPageNumber * RCPostPerPage;
        
        [RCConnectionManager startConnection];
        NSString *nextPage = [NSString stringWithFormat:@"%d", currentPageNumber];
        NSMutableString *nextPageAddress = [[NSMutableString alloc] initWithString:address];
        addArgumentToQueryString(nextPageAddress, @"page", nextPage);
        
        NSLog(@"Main-Feed: get feed address:%@",address);
        NSURL *url=[NSURL URLWithString:nextPageAddress];
        NSURLRequest *request = CreateHttpGetRequest(url);
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             [RCConnectionManager endConnection];
             [_refreshControl endRefreshing];
             
             NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
             if ([responseData isEqualToString:@"Unauthorized"]) {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
                     [appDelegate.menuViewController btnActionLogOut:nil];
                 });
                 return;
             }
             SBJsonParser *jsonParser = [SBJsonParser new];
             NSDictionary *jsonData = (NSDictionary *) [jsonParser objectWithString:responseData error:nil];
#if DEBUG==1
             NSLog(@"%@%@",[RCMainFeedViewController debugTag], responseData);
#endif
             
             if (jsonData != NULL) {
                 NSArray *postList = (NSArray *) [jsonData objectForKey:@"post_list"];

                 [_btnUserAvatar setImage:[_user getUserAvatar:_user.userID] forState:UIControlStateNormal];
                 
                 if ([postList count] == 0) {
                     willShowMoreFeeds = NO;
                     [_btnMoreFeed setHidden:YES];
                 }
                 
                 for (NSDictionary *postData in postList) {
                     RCPost *post = [RCPost getPostWithNSDictionary:postData];
                     [_postsByRowIndex setObject:[NSNumber numberWithInt:[_posts count]] forKey:[NSNumber numberWithInt:post.postID]];
                     [_posts addObject:post];
                     [_mapView addAnnotation:post];
                 }
                 
                 //[_collectionView reloadData];
             }else {
                 postNotification([NSString stringWithFormat:@"%@ %@",RCErrorMessageFailedToGetFeed, responseData]);
             }
         }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        postNotification(RCErrorMessageFailedToGetFeed);
    }

}

- (UIImage*) takeScreenshot {
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
        UIGraphicsBeginImageContextWithOptions(self.view.frame.size, NO, [UIScreen mainScreen].scale);
    else
        UIGraphicsBeginImageContext(self.view.frame.size);
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void) switchToNewPostScreen {
    RCNewPostViewController *newPostController;
    if ([[UIScreen mainScreen] bounds].size.height < RCIphone5Height)
        newPostController = [[RCNewPostViewController alloc] initWithUser:_user withNibName:@"RCNewPostViewController4" bundle:nil];
    else
        newPostController = [[RCNewPostViewController alloc] initWithUser:_user withNibName:@"RCNewPostViewController" bundle:nil];

    [self presentViewController:newPostController animated:YES completion:nil];
}

#pragma mark - UICollectionView Datasource
// 1
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    int nPosts;
    switch (_currentViewMode) {
        default:
            nPosts = [_posts count];
            break;
    };
    return nPosts;
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
        [self asynchFetchFeedNextPage];
    }
    
    if (indexPath.row == (currentMaxDisplayedPostNumber - 1)){
        [self showMoreFeedButton:YES animate:YES];
    }else if (indexPath.row < (currentMaxDisplayedPostNumber - 1 - showThreshold)) {
        if (!_btnMoreFeed.isHidden)
            [self showMoreFeedButton:NO animate:YES];
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
        [self processTogglingPost:(RCPost*)view.annotation];
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    if ([view.annotation isKindOfClass:[MKUserLocation class]]){
        _userCalloutVisible = NO;
    }
    if ([view.annotation isKindOfClass:[RCPost class]]){
        [self processTogglingPost:(RCPost*)view.annotation];
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
    
    //prepare user UI element
    if (_user != nil) {
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
            [_collectionView reloadData];
        }
        if (recognizer.scale < 0.8 && _nRows < maximumRow && !_didZoom) {
            _didZoom = YES;
            _nRows++;
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
        /*dispatch_time_t dt = dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC);
        dispatch_after(dt, dispatch_get_main_queue(), ^(void)
        {
            [_mapView setCenterCoordinate:post.coordinate animated:YES];
        });*/
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
    
    //if there's no item at point of tap
    if (indexPath != nil) {
        RCPost *post = [_posts objectAtIndex:indexPath.row];
        if ([_chosenPosts containsObject:[NSNumber numberWithInt:post.postID]])
            [_mapView deselectAnnotation:post animated:YES];
        else
            [_mapView selectAnnotation:post animated:YES];
        //[self selectPostAtIndexPath:indexPath];
    }
}

- (IBAction)handleLongPress:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [recognizer locationInView:_collectionView];
        NSIndexPath *indexPath = [_collectionView indexPathForItemAtPoint:point];
        
        //if index path for cell not found
        if (indexPath != nil ) {
            [_collectionView removeGestureRecognizer:_pinchGestureRecognizer];
            [_collectionView removeGestureRecognizer:_tapGestureRecognizer];
            [_collectionView removeGestureRecognizer:_longPressGestureRecognizer];
            RCPost *post;
            
            post = [_posts objectAtIndex:indexPath.row];
            RCUser *owner = [RCUser getUserOwnerOfPost:post];
            //check if this is a post with notification
            RCNotification* notification = [RCNotification notificationForResource:[NSString stringWithFormat:@"posts/%d",post.postID]];
            if (notification != nil) {
                [notification updateViewedProperty];
            }
            
            RCPostDetailsViewController *postDetailsViewController = [[RCPostDetailsViewController alloc] initWithPost:post withOwner:owner withLoggedInUser:_user];
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
    //[self showMoreFeedButton:NO animate:NO];
    currentMaxDisplayedPostNumber = currentMaxPostNumber;
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
        [_btnMoreFeed setHidden:!show];
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
