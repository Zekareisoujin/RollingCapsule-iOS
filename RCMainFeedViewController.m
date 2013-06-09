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

@interface RCMainFeedViewController ()

@end

@implementation RCMainFeedViewController

BOOL        _firstRefresh;
@synthesize refreshControl = _refreshControl;
@synthesize user = _user;
@synthesize userCache = _userCache;
@synthesize postCache = _postCache;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithUser:(RCUser *) user {
    self = [super init];
    if (self) {
        _user = user;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _userCache = [[NSMutableDictionary alloc] init];
    _postCache = [[NSMutableDictionary alloc] init];
    
    // Do any additional setup after loading the view from its nib.
    _items = [[NSMutableArray alloc] init];
    _tblFeedList.tableFooterView = [[UIView alloc] init];
    self.navigationItem.title = @"News Feed";

    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"New Post" style:UIBarButtonItemStylePlain target:self action:@selector(switchToNewPostScreen)];
    self.navigationItem.rightBarButtonItem = rightButton;
    
    UITableViewController *tableViewController = setUpRefreshControlWithTableViewController(self, _tblFeedList);
    _refreshControl = tableViewController.refreshControl;
    [_refreshControl addTarget:self
                        action:@selector(handleRefresh:)
              forControlEvents:UIControlEventValueChanged  ];
    _firstRefresh = YES;
    [self handleRefresh:_refreshControl];
    //[self asynchFetchFeeds];
}

- (void) handleRefresh:(UIRefreshControl*) refreshControl {
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
    [cell getAvatarImageFromInternet:_user withLoggedInUserID:post.userID usingCollection:_userCache];
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
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@?mobile=1", RCServiceURL]];
        NSURLRequest *request = CreateHttpGetRequest(url);
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
        {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            [_refreshControl endRefreshing];
            
            NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
            
            SBJsonParser *jsonParser = [SBJsonParser new];
            NSDictionary *jsonData = (NSDictionary *) [jsonParser objectWithString:responseData error:nil];
            //NSLog(@"%@",jsonData);
            
            if (jsonData != NULL) {
                [_items removeAllObjects];
                NSArray *postList = (NSArray *) [jsonData objectForKey:@"post_list"];
                for (NSDictionary *postData in postList) {
                    RCPost *post = [[RCPost alloc] initWithNSDictionary:postData];
                    [_items addObject:post];
                }
                [_tblFeedList reloadData];
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

@end
