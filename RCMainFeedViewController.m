//
//  RCMainFeedViewController.m
//  Rolling Capsule
//
//  Created by Nguyen Phi Long Louis on 29/05/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCMainFeedViewController.h"
#import "RCFeedPostPreview.h"
#import "RCUser.h"
#import "RCPost.h"
#import "RCConstants.h"
#import "RCUtilities.h"
#import "SBJson.h"
#import "RCNewPostViewController.h"
#import "RCPostDetailsViewController.h"
#import "RCAmazonS3Helper.h"
#import "RCMainFeedCell.h"
#import "RCMainMenuViewController.h"
#import "RCConnectionManager.h"
#import "RCNotification.h"
#import <QuartzCore/QuartzCore.h>

@interface RCMainFeedViewController ()

@property (nonatomic, strong) RCConnectionManager *connectionManager;
@property (nonatomic, strong) NSMutableDictionary *postsByLandmark;
@property (nonatomic, assign) int currentLandmarkID;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchGestureRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, strong) UIImage *backgroundImage;
@property (nonatomic, assign) RCMainFeedViewMode      currentViewMode;
@end

@implementation RCMainFeedViewController

int _nRows;
BOOL        _firstRefresh;
BOOL        _willRefresh;
BOOL        _haveScreenshot;
@synthesize refreshControl = _refreshControl;
@synthesize user = _user;
@synthesize userCache = _userCache;
@synthesize postCache = _postCache;
@synthesize connectionManager = _connectionManager;
@synthesize postsByLandmark = _postsByLandmark;
@synthesize currentLandmarkID = _currentLandmarkID;
@synthesize chosenPosts = _chosenPosts;
@synthesize pinchGestureRecognizer = _pinchGestureRecognizer;
@synthesize longPressGestureRecognizer = _longPressGestureRecognizer;
@synthesize tapGestureRecognizer = _tapGestureRecognizer;
@synthesize backgroundImage = _backgroundImage;
@synthesize currentViewMode = _currentViewMode;

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
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [_chosenPosts removeAllObjects];
    
    [_connectionManager reset];
    _currentLandmarkID = -1;
    [_postsByLandmark removeAllObjects];
    
    _userCache = [[NSMutableDictionary alloc] init];
    _postCache = [[NSMutableDictionary alloc] init];
    
    self.navigationItem.title = @"";

    UIImage *buttonImage = [UIImage imageNamed:@"mainNavbarPostButton"];
    UIButton *postButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [postButton setFrame:CGRectMake(0,0,buttonImage.size.width, buttonImage.size.height)];
    [postButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [postButton addTarget:self action:@selector(switchToNewPostScreen) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithCustomView:postButton] ;
    self.navigationItem.rightBarButtonItem = rightButton;
    
    //prepare collection view
    
    UICollectionViewFlowLayout *flow =  (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    flow.minimumInteritemSpacing = 0.0;
    _refreshControl = [[UIRefreshControl alloc] init];//tableViewController.refreshControl;
    [_collectionView addSubview:_refreshControl];
    [_refreshControl addTarget:self
                        action:@selector(handleRefresh:)
              forControlEvents:UIControlEventValueChanged  ];
    _firstRefresh = YES;
    
    NSString* cellIdentifier = [RCMainFeedCell cellIdentifier];
    [self.collectionView registerClass:[RCMainFeedCell class] forCellWithReuseIdentifier:cellIdentifier];
    UINib *nib = [UINib nibWithNibName:cellIdentifier bundle: nil];
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:cellIdentifier];
    
    _pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    
    //set the current view mode of the view, the default view is public
    _currentViewMode = RCMainFeedViewModePublic;
    _btnViewModePublic.enabled = NO;
    
    
    //initialize miscellaneaous constants
    _nRows = 2; //the number of rows of images that are gonig to be displayed in the UICollectionView
    _willRefresh = YES; //indicate whether this view will refresh after returning from another view
    
    /*this flag indicate if the screenshot of this view has been taken
       this is used when opening light box view where a screenshot needs to be taken
       since taking screenshot is slow it is run in background and this flag
       will be set to true when it's done, after this flag is set to true, the code can open the view*/
    _haveScreenshot = NO;
    
}

- (void) handleRefresh:(UIRefreshControl*) refreshControl {
    [self btnCenterMapTouchUpInside:nil];
    
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

- (void) asynchFetchFeeds {
    //Asynchronous Request
    @try {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        CLLocationCoordinate2D zoomLocation = appDelegate.currentLocation.coordinate;

        NSString *address = [[NSString alloc] initWithFormat:@"%@?mobile=1&latitude=%f&longitude=%f&%@", RCServiceURL, zoomLocation.latitude, zoomLocation.longitude, RCLevelsQueryString];
        NSLog(@"Main-Feed: get feed address:%@",address);
        NSURL *url=[NSURL URLWithString:address];
        NSURLRequest *request = CreateHttpGetRequest(url);
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
        {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            [_refreshControl endRefreshing];
            
            NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
            
            SBJsonParser *jsonParser = [SBJsonParser new];
            NSDictionary *jsonData = (NSDictionary *) [jsonParser objectWithString:responseData error:nil];
            NSLog(@"%@%@",[RCMainFeedViewController debugTag], jsonData);
            
            if (jsonData != NULL) {
                [_postsByLandmark removeAllObjects];
                NSLog(@"current annotations:%@",_mapView.annotations);
                NSLog(@"currentlandmark %d",_currentLandmarkID);
                int pastCurrentLandmark = _currentLandmarkID;
                NSArray *postList = (NSArray *) [jsonData objectForKey:@"post_list"];
                NSArray *landmarkList = (NSArray*) [jsonData objectForKey:@"landmark_list"];
                NSDictionary *userDictionary = (NSDictionary *) [jsonData objectForKey:@"user"];
                _user = [[RCUser alloc] initWithNSDictionary:userDictionary];
                AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                _lblUsername.text = _user.name;
                
                //set user avataer image in background
                dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
                dispatch_async(queue, ^{
                    UIImage *image = [RCAmazonS3Helper getAvatarImage:_user withLoggedinUserID:_user.userID];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_imgViewUserAvatar setImage:image];
                    });
                });
                
                [appDelegate setCurrentUser:_user];
                
                for (NSDictionary *postData in postList) {
                    RCPost *post = [[RCPost alloc] initWithNSDictionary:postData];
                    id key = [[NSNumber alloc] initWithInteger:post.landmarkID];
                    NSMutableArray *postList = (NSMutableArray *)[_postsByLandmark objectForKey:key];
                    if (postList != nil) {
                        [postList addObject:post];
                    } else {
                        NSMutableArray* postList = [[NSMutableArray alloc] init];
                        [postList addObject:post];
                        [_postsByLandmark setObject:postList forKey:key];
                    }
                    NSLog(@"%@ post coordinates %f %f",[RCMainFeedViewController debugTag], post.coordinate.latitude, post.coordinate.longitude);
                }
                
                [_mapView removeAnnotations:_mapView.annotations];
                NSLog(@"current landmark Id %d",_currentLandmarkID);
                _currentLandmarkID = -1;
                for (NSDictionary *landmarkData in landmarkList) {
                    RCLandmark *landmark = [[RCLandmark alloc] initWithNSDictionary:landmarkData];
                    [_mapView addAnnotation:landmark];
                    if (landmark.landmarkID == pastCurrentLandmark)
                        _currentLandmarkID = landmark.landmarkID;
                    NSLog(@"%@: landmark coordinates %f %f",[RCMainFeedViewController debugTag], landmark.coordinate.latitude, landmark.coordinate.longitude);
                }
                NSLog(@"current landmark Id %d",_currentLandmarkID);
                NSArray *notificationList = (NSArray*) [jsonData objectForKey:@"notifications"]
                ;
                if (notificationList != nil) {
                    NSMutableArray* notifications = [[NSMutableArray alloc] init];
                    for (NSDictionary *notificationData in notificationList) {
                        RCNotification *notification = [[RCNotification alloc] initWithNSDictionary:notificationData];
                        [notifications addObject:notification];
                    }
                    
                    [appDelegate setNotificationList:notifications];
                }
                NSLog(@"before reload currentlandmark %d",_currentLandmarkID);
                [_tblFeedList reloadData];
                [_collectionView reloadData];
                if (_firstRefresh){
                    [_tblFeedList setContentOffset:CGPointMake(0, 0) animated:YES];
                    _firstRefresh = NO;
                }
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
    RCNewPostViewController *newPostController = [[RCNewPostViewController alloc] initWithUser:_user withBackgroundImage:nil];
    [self addChildViewController:newPostController];
    newPostController.view.frame = self.view.frame;
    newPostController.postComplete = ^{ [self handleRefresh:_refreshControl]; };
    [self.view addSubview:newPostController.view];
    [newPostController didMoveToParentViewController:self];
}

#pragma mark - UICollectionView Datasource
// 1
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    return section == 0 ? [[_postsByLandmark objectForKey:[[NSNumber alloc] initWithInteger:_currentLandmarkID]] count] : 0;
}
// 2
- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}
// 3
- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString* cellIdentifier = [RCMainFeedCell cellIdentifier];
    RCMainFeedCell *cell = [cv dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    NSArray* items = [_postsByLandmark objectForKey:[[NSNumber alloc] initWithInteger:_currentLandmarkID]];
    RCPost *post = [items objectAtIndex:indexPath.row];
    [_connectionManager startConnection];
    [cell getPostContentImageFromInternet:_user withPostContent:post usingCollection:nil completion:^{
        [_connectionManager endConnection];
    }];
    if ([_chosenPosts count] != 0) {
        if ([_chosenPosts containsObject:[[NSNumber alloc] initWithInt:post.postID]]) {
            [cell changeCellState:RCCellStateFloat];
        } else {
            [cell changeCellState:RCCellStateDimmed];
        }
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
    RCLandmark *landmark = (RCLandmark *)view.annotation;
    _currentLandmarkID = landmark.landmarkID;
    [_collectionView reloadData];
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
    [_collectionView addGestureRecognizer:_pinchGestureRecognizer];
    [_collectionView addGestureRecognizer:_tapGestureRecognizer];
    [_collectionView addGestureRecognizer:_longPressGestureRecognizer];
    
    //refresh if necessary, views like post where the main feed should refresh when finish
    //would set the _willRefresh parameter
    if (_willRefresh) {
        [self handleRefresh:_refreshControl];
        _willRefresh = NO;
    }
}

#pragma mark - pinch gesture recognizer

- (IBAction)handlePinch:(UIPinchGestureRecognizer *)recognizer {
    NSLog(@"Main-feed:pinch scale %f",recognizer.scale);
}

- (IBAction)handleTap:(UITapGestureRecognizer *)recognizer {
    CGPoint point = [recognizer locationInView:_collectionView];
    NSIndexPath *indexPath = [_collectionView indexPathForItemAtPoint:point];
    
    //if there's no item at point of tap
    if (indexPath != nil) {
        int idx = [indexPath row];
        NSArray* items = (NSArray*)[_postsByLandmark objectForKey:[[NSNumber alloc] initWithInt:_currentLandmarkID]];
        RCPost *post = [items objectAtIndex:idx];
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
                NSArray* items = (NSArray*)[_postsByLandmark objectForKey:[[NSNumber alloc] initWithInt:_currentLandmarkID]];
                RCPost *iteratingPost = [items objectAtIndex:index];
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
            int idx = [indexPath row];
            NSArray* items = (NSArray*)[_postsByLandmark objectForKey:[[NSNumber alloc] initWithInt:_currentLandmarkID]];
            
            RCPost *post = [items objectAtIndex:idx];
            RCUser *owner = [[RCUser alloc] init];
            owner.userID = post.userID;
            
            //[_collectionView removeGestureRecognizer:recognizer];
            RCPostDetailsViewController *postDetailsViewController = [[RCPostDetailsViewController alloc] initWithPost:post withOwner:owner withLoggedInUser:_user];
            [self addChildViewController:postDetailsViewController];
            postDetailsViewController.view.frame = self.view.frame;
            [self.view addSubview:postDetailsViewController.view];
            [postDetailsViewController didMoveToParentViewController:self];
            
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
    
}

- (IBAction)btnCenterMapTouchUpInside:(id)sender {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    CLLocationCoordinate2D zoomLocation = appDelegate.currentLocation.coordinate;
    NSLog(@"current location %f %f", zoomLocation.longitude, zoomLocation.latitude);
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, 0.5*METERS_PER_MILE, 0.5*METERS_PER_MILE);
    [_mapView setRegion:viewRegion animated:YES];
}
@end
