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
#import "Constants.h"
#import "Util.h"
#import "SBJson.h"
#import "RCNewPostViewController.h"
#import "RCAmazonS3Helper.h"

@interface RCMainFeedViewController ()

@end

@implementation RCMainFeedViewController

BOOL        _firstRefresh;
@synthesize refreshControl = _refreshControl;
@synthesize user = _user;

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
    [formatter setDateFormat:@"dd-MMM, hh:mm:ssa"];
    NSString *lastUpdated = [NSString stringWithFormat:@"Last updated on %@", [formatter  stringFromDate:[NSDate date] ] ];
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
    
    dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
    dispatch_async(queue, ^{
        NSURL *imageUrl = [NSURL URLWithString:post.authorAvatar];
        UIImage *image = [UIImage imageWithData: [NSData dataWithContentsOfURL:imageUrl]];
        dispatch_async(dispatch_get_main_queue(), ^{
            cell.imgUserAvatar.image = image;
        });
    });
    dispatch_async(queue, ^{
        if ((NSNull *)post.fileUrl != [NSNull null]) {
            UIImage *image = [RCAmazonS3Helper getUserMediaImage:[[RCUser alloc] init] withLoggedinUserID:_user.userID withImageUrl:post.fileUrl];
            //UIImage *image = [UIImage imageWithData: [NSData dataWithContentsOfURL:imageUrl]];
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.imgPostContent.image = image;
            });
        }
    });

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 270;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //nothing yet
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
                alertStatus([NSString stringWithFormat:@"Failed to obtain news feed, please try again! %@", responseData], @"Connection Failed!", self);
            }
        }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        alertStatus(@"Failure getting friends from web service",@"Connection Failed!",self);
    }
}

- (void) switchToNewPostScreen {
    RCNewPostViewController *newPostController = [[RCNewPostViewController alloc] initWithUser:_user];
    [self.navigationController pushViewController:newPostController animated:YES];
}

@end
