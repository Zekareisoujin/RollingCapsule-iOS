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
#import "RCConnectionManager.h"

@interface RCMainFeedViewController ()

@property (nonatomic, strong) RCConnectionManager *connectionManager;

@end

@implementation RCMainFeedViewController

BOOL        _firstRefresh;
@synthesize refreshControl = _refreshControl;
@synthesize user = _user;
@synthesize userCache = _userCache;
@synthesize postCache = _postCache;
@synthesize connectionManager = _connectionManager;

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
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [_connectionManager reset];
    
    _userCache = [[NSMutableDictionary alloc] init];
    _postCache = [[NSMutableDictionary alloc] init];
    
    // Do any additional setup after loading the view from its nib.
    _items = [[NSMutableArray alloc] init];
    _tblFeedList.tableFooterView = [[UIView alloc] init];
    self.navigationItem.title = @"News Feed";

    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"New Post" style:UIBarButtonItemStylePlain target:self action:@selector(switchToNewPostScreen)];
    self.navigationItem.rightBarButtonItem = rightButton;
    
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
    [self handleRefresh:_refreshControl];
}

- (void) handleRefresh:(UIRefreshControl*) refreshControl {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    CLLocationCoordinate2D zoomLocation = appDelegate.currentLocation.coordinate;
    NSLog(@"current location %f %f", zoomLocation.longitude, zoomLocation.latitude);
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, 0.5*METERS_PER_MILE, 0.5*METERS_PER_MILE);
    [_mapView setRegion:viewRegion animated:YES];
    
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"RCFeedPostPreview";
    
    RCFeedPostPreview *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"RCFeedPostPreview" owner:self options:nil];
        cell = [nib objectAtIndex:0];
        //cell = [[RCFeedPostPreview alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    RCPost *post = [_items objectAtIndex:indexPath.row];
    cell.lblUserProfileName.text = post.authorName;
    cell.lblPostContent.text = post.content;
    
    RCUser *rowUser = [[RCUser alloc] init];
    rowUser.userID = post.userID;
    rowUser.email = post.authorEmail;
    [cell getAvatarImageFromInternet:rowUser withLoggedInUserID:_user.userID usingCollection:_userCache];
    [cell getPostContentImageFromInternet:_user withPostContent:post usingCollection:_postCache];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 270;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    int idx = [indexPath row];
    RCPost *post = [_items objectAtIndex:idx];
    RCUser *owner = [[RCUser alloc] init];
    owner.userID = post.userID;
    //owner.name = self.
    RCPostDetailsViewController *postDetailsViewController = [[RCPostDetailsViewController alloc] initWithPost:post withOwner:owner withLoggedInUser:_user];
    [self.navigationController pushViewController:postDetailsViewController animated:YES];
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
                [_items removeAllObjects];
                NSLog(@"current annotations:%@",_mapView.annotations);
                [_mapView removeAnnotations:_mapView.annotations];
                NSArray *postList = (NSArray *) [jsonData objectForKey:@"post_list"];
                NSArray *landmarkList = (NSArray*) [jsonData objectForKey:@"landmark_list"];
                NSDictionary *userDictionary = (NSDictionary *) [jsonData objectForKey:@"user"];
                _user = [[RCUser alloc] initWithNSDictionary:userDictionary];
                AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                [appDelegate setCurrentUser:_user];
                for (NSDictionary *postData in postList) {
                    RCPost *post = [[RCPost alloc] initWithNSDictionary:postData];
                    [_items addObject:post];
                    NSLog(@"%@ post coordinates %f %f",[RCMainFeedViewController debugTag], post.coordinate.latitude, post.coordinate.longitude);
                }
                for (NSDictionary *landmarkData in landmarkList) {
                    RCPost *post = [[RCPost alloc] init];
                    post.latitude = [[landmarkData objectForKey:@"latitude"] doubleValue];
                    post.longitude = [[landmarkData objectForKey:@"longitude"] doubleValue];
                    [_mapView addAnnotation:post];
                    NSLog(@"%@: landmark coordinates %f %f",[RCMainFeedViewController debugTag], post.coordinate.latitude, post.coordinate.longitude);
                }
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

- (void) switchToNewPostScreen {
    RCNewPostViewController *newPostController = [[RCNewPostViewController alloc] initWithUser:_user];
    [self.navigationController pushViewController:newPostController animated:YES];
}

#pragma mark - UICollectionView Datasource
// 1
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    return section == 0 ? [_items count] : 0;
}
// 2
- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}
// 3
- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString* cellIdentifier = [RCMainFeedCell cellIdentifier];
    RCMainFeedCell *cell = [cv dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    RCPost *post = [_items objectAtIndex:indexPath.row];
    [_connectionManager startConnection];
    //UIImageView *imageView = cell.imageView;
    //cell.imageView.frame = imageView.frame = CGRectMake(imageView.frame.origin.x, imageView.frame.origin.y,70, 70);
    [cell getPostContentImageFromInternet:_user withPostContent:post usingCollection:nil completion:^{
        [_connectionManager endConnection];
    }];
    cell.backgroundColor = [UIColor blackColor];
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
    // TODO: Select Item
}
- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    // TODO: Deselect item
}

#pragma mark – UICollectionViewDelegateFlowLayout

// 1
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    //NSString *searchTerm = self.searches[indexPath.section]; FlickrPhoto *photo =
    //self.searchResults[searchTerm][indexPath.row];
    // 2
    //RCMainFeedCell *cell = (RCMainFeedCell *)[collectionView cellForItemAtIndexPath:indexPath];
    CGSize retval = CGSizeMake(126,126);//RCUploadImageSizeWidth, RCUploadImageSizeWidth);
    //retval.height += 35; retval.width += 35;
    return retval;
}

// 3
- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(10, 20, 10, 20);
}

@end
