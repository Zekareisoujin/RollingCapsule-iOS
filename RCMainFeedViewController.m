//
//  RCMainFeedViewController.m
//  Rolling Capsule
//
//  Created by Nguyen Phi Long Louis on 29/05/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCMainFeedViewController.h"
#import "RCPostCommentCell.h"
#import "RCUser.h"
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
#import "RCNotification.h"
#import "RCAddLandmarkController.h"
#import "RCOperationsManager.h"
#import "Reachability.h"
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>
#import "SBJson.h"

@interface RCMainFeedViewController ()

@property (nonatomic, strong) RCConnectionManager *connectionManager;
@property (nonatomic, strong) NSMutableDictionary *postsByLandmark;
@property (nonatomic, strong) NSMutableDictionary *landmarks;
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
@end

@implementation RCMainFeedViewController

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
@synthesize landmarks = _landmarks;
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
        _landmarks = [[NSMutableDictionary alloc] init];
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
    
    //miscellaneous helper preparation
    [_connectionManager reset];
    
    
    //reset view data
    [_chosenPosts removeAllObjects];
    _currentLandmarkID = -1;
    [_postsByLandmark removeAllObjects];
    [_landmarks removeAllObjects];
    
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
    _nRows = 2; //the number of rows of images that are gonig to be displayed in the UICollectionView
    _willRefresh = YES; //indicate whether this view will refresh after returning from another view
    showThreshold = 8;
    
    [self showMoreFeedButton:NO animate:NO];
    
    _mapView.showsUserLocation = YES;
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
    [self btnCenterMapTouchUpInside:nil];
    if ([_reachability currentReachabilityStatus] == NotReachable) {
        [self showNoConnectionWarningMessage];
        return;
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:RCInfoStringDateFormat];
    NSString *lastUpdated = [NSString stringWithFormat:RCInfoStringLastUpdatedOnFormat, [formatter  stringFromDate:[NSDate date] ] ];
    [_refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:lastUpdated]];
	[self asynchFetchFeeds];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
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

- (void) asynchFetchFeeds {
    int nRetry = 5;
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
                NSLog(@"%@%@",[RCMainFeedViewController debugTag], responseData);
                
                if (jsonData != NULL) {
                    [_postsByLandmark removeAllObjects];
                    [_chosenPosts removeAllObjects];
                    NSArray *postList = (NSArray *) [jsonData objectForKey:@"post_list"];
                    NSDictionary *userDictionary = (NSDictionary *) [jsonData objectForKey:@"user"];
                    _user = [[RCUser alloc] initWithNSDictionary:userDictionary];
                    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                    _lblUsername.text = _user.name;
                    
                    [_user getUserAvatarAsync:_user.userID completionHandler:^(UIImage* img){
                         dispatch_async(dispatch_get_main_queue(), ^{
                             [_btnUserAvatar setImage:img forState:UIControlStateNormal];
                         });
                     }];
                    //[_btnUserAvatar setImage:[_user getUserAvatar:_user.userID] forState:UIControlStateNormal];
                    
                    [appDelegate setCurrentUser:_user];
                    [_posts removeAllObjects];
                    for (NSDictionary *postData in postList) {
                        RCPost *post = [[RCPost alloc] initWithNSDictionary:postData];
                        [_posts addObject:post];
                        RCPhotoDownloadOperation *op = [[RCPhotoDownloadOperation alloc] initWithPhotokey:post.thumbnailUrl withOwnerID:_user.userID];
                        //[op start];
                        op.delegate = post;
                        //[_landmarks setObject:op forKey:[NSNumber numberWithInt:post.postID]];
                        [RCOperationsManager addOperation:op];
                        [post addObserver:self forKeyPath:@"thumbnailImage" options:NSKeyValueObservingOptionNew context:nil];
                        //NSLog(@"%@ post coordinates %f %f",[RCMainFeedViewController debugTag], post.coordinate.latitude, post.coordinate.longitude);
                    }
                    willShowMoreFeeds = ([_posts count] == currentMaxPostNumber);
                    
                    [_mapView removeAnnotations:_mapView.annotations];
                    [_collectionView reloadData];
                    
                    return;
                } else {
                    NSLog(@"error: %@",error);
                    alertStatus(RCErrorMessageFailedToGetFeed,RCAlertMessageServerError,self);
                }
            }];
        }
        @catch (NSException * e) {
            NSLog(@"Exception: %@", e);
            failed = YES;
        }
    }
    if (failed)
        alertStatus(RCErrorMessageFailedToGetFeed,RCAlertMessageConnectionFailed,self);
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:[RCPost class]]) {
        RCPost* updatedPost = (RCPost*) object;
        for (RCMainFeedCell* cell in _collectionView.visibleCells) {
            NSIndexPath *path = [_collectionView indexPathForCell:cell];
            RCPost *post = [_posts objectAtIndex:path.row];
            if (post.postID == updatedPost.postID)
                [cell.imageView setImage:updatedPost.thumbnailImage];
        }
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
             NSLog(@"%@%@",[RCMainFeedViewController debugTag], responseData);
             
             if (jsonData != NULL) {
                 NSLog(@"current annotations:%@",_mapView.annotations);
                 NSLog(@"currentlandmark %d",_currentLandmarkID);
                 //int pastCurrentLandmark = _currentLandmarkID;
                 NSArray *postList = (NSArray *) [jsonData objectForKey:@"post_list"];

                 [_btnUserAvatar setImage:[_user getUserAvatar:_user.userID] forState:UIControlStateNormal];
                 
                 if ([postList count] == 0) {
                     willShowMoreFeeds = NO;
                     [_btnMoreFeed setHidden:YES];
                 }
                 
                 for (NSDictionary *postData in postList) {
                     RCPost *post = [[RCPost alloc] initWithNSDictionary:postData];
                     [_posts addObject:post];
                 }
                 
                 //[_collectionView reloadData];
             }else {
                 alertStatus([NSString stringWithFormat:@"%@ %@",RCErrorMessageFailedToGetFeed, responseData], RCAlertMessageConnectionFailed, self);
             }
         }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        alertStatus(RCErrorMessageFailedToGetFeed,RCAlertMessageConnectionFailed,self);
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
    [_postButton setEnabled:NO];
    RCNewPostViewController *newPostController;
    if ([[UIScreen mainScreen] bounds].size.height < RCIphone5Height)
        newPostController = [[RCNewPostViewController alloc] initWithUser:_user withNibName:@"RCNewPostViewController4" bundle:nil];
    else
        newPostController = [[RCNewPostViewController alloc] initWithUser:_user withNibName:@"RCNewPostViewController" bundle:nil];
    newPostController.postComplete = ^{
        [_postButton setEnabled:YES];
        [self handleRefresh:_refreshControl];
    };
    newPostController.postCancel = ^{
        [_postButton setEnabled:YES];
    };

    [self presentViewController:newPostController animated:YES completion:nil];
    /*[self addChildViewController:newPostController];
    newPostController.view.frame = self.view.frame;
        [self.view addSubview:newPostController.view];
    [newPostController didMoveToParentViewController:self];*/
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
    [RCConnectionManager startConnection];
    [cell getPostContentImageFromInternet:_user withPostContent:post usingCollection:nil completion:^{ [RCConnectionManager endConnection];}];
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
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    if ([view.annotation isKindOfClass:[RCLandmark class]]){
        RCLandmark *landmark = (RCLandmark *)view.annotation;
        _currentLandmarkID = landmark.landmarkID;
        [_collectionView reloadData];
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    _currentLandmarkID = -1;
    [_collectionView reloadData];
}

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    if ([annotation isKindOfClass:[RCLandmark class]]) {
        RCLandmark *landmark = (RCLandmark*) annotation;
        NSString *annotationIdentifier = @"landmark";
        MKAnnotationView *landmarkButton = (MKAnnotationView*) [mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
        if (landmarkButton == nil)
            landmarkButton = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
        NSString *imageName = [NSString stringWithFormat:@"landmarkCategory%@.png",landmark.category];
        UIImage *scaledLandmarkImage = imageWithImage([UIImage imageNamed:imageName], CGSizeMake(20,20));
        [landmarkButton setImage:scaledLandmarkImage];
        return (MKAnnotationView*)landmarkButton;
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
        _lblUsername.text = _user.name;
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
    
    float width = (_collectionView.frame.size.height-42) / _nRows;
    int numCell = [[UIScreen mainScreen] bounds].size.width / width + 0.5;
    showThreshold = numCell * _nRows;
}

- (IBAction)handleTap:(UITapGestureRecognizer *)recognizer {
    CGPoint point = [recognizer locationInView:_collectionView];
    NSIndexPath *indexPath = [_collectionView indexPathForItemAtPoint:point];
    
    //if there's no item at point of tap
    if (indexPath != nil) {
        int idx = [indexPath row];
        RCPost *post = [_posts objectAtIndex:idx];
        NSNumber *key = [[NSNumber alloc] initWithInt:post.postID];
        RCMainFeedCell* currentCell = (RCMainFeedCell *)[_collectionView cellForItemAtIndexPath:indexPath];
        
        if ([_chosenPosts containsObject:key]) {
            [_chosenPosts removeObject:key];
            [_mapView removeAnnotation:post];
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
            MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(post.coordinate, 0.5*METERS_PER_MILE, 0.5*METERS_PER_MILE);
            [_mapView setRegion:viewRegion animated:YES];
            [currentCell changeCellState:RCCellStateFloat];
            [_chosenPosts addObject:[[NSNumber alloc] initWithInt:post.postID]];
            [_mapView addAnnotation:post];
            for (UICollectionViewCell* cell in _collectionView.visibleCells) {
                RCMainFeedCell *feedCell = (RCMainFeedCell *)cell;
                int index = [[_collectionView indexPathForCell:cell] row];
                RCPost *iteratingPost = [_posts objectAtIndex:index];
                NSNumber *key = [[NSNumber alloc] initWithInt:iteratingPost.postID];
                //if post not chosen then dim
                if (![_chosenPosts containsObject:key])
                    [feedCell changeCellState:RCCellStateDimmed];
            }
        }
    }
}

- (IBAction)handleLongPress:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [recognizer locationInView:_collectionView];
        NSIndexPath *indexPath = [_collectionView indexPathForItemAtPoint:point];
        
        //if index path for cell not found
        if (indexPath != nil ) {
            RCPost *post;
            post = [_posts objectAtIndex:indexPath.row];
            RCUser *owner = [[RCUser alloc] init];
            owner.userID = post.userID;
            owner.name = post.authorName;
            
            //[_collectionView removeGestureRecognizer:recognizer];
            RCPostDetailsViewController *postDetailsViewController = [[RCPostDetailsViewController alloc] initWithPost:post withOwner:owner withLoggedInUser:_user];
            if (post.landmarkID == -1)
                postDetailsViewController.landmark = nil;
            else
                postDetailsViewController.landmark = [_landmarks objectForKey:[NSNumber numberWithInt:post.landmarkID]];
            postDetailsViewController.deleteFunction = ^{
                [self handleRefresh:_refreshControl];
            };
            postDetailsViewController.landmarkID = post.landmarkID;
            //[self presentViewController:postDetailsViewController animated:YES completion:nil];
            [self.navigationController pushViewController:postDetailsViewController animated:YES];
            
        }
    }
}

- (IBAction)btnViewModeChosen:(UIButton *)sender {
    if ([sender isEqual:_btnViewModePublic]) {
        _currentViewMode = RCMainFeedViewModePublic;
        _btnViewModeFriends.enabled = YES;
        _btnViewModeFollow.enabled = YES;
    } else if ([sender isEqual:_btnViewModeFriends]) {
        _currentViewMode = RCMainFeedViewModeFriends;
        _btnViewModePublic.enabled = YES;
        _btnViewModeFollow.enabled = YES;
    } else if ([sender isEqual:_btnViewModeFollow]) {
        _currentViewMode = RCMainFeedViewModeFollow;
        _btnViewModeFriends.enabled = YES;
        _btnViewModePublic.enabled = YES;
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

- (void) setCurrentUser: (RCUser*) user {
    _user = user;
}

- (void) showMoreFeedButton: (BOOL)show animate:(BOOL)animate {
    float duration = (animate?1.0:0.0);
    
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

@end
