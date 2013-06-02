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

@interface RCMainFeedViewController ()

@end

@implementation RCMainFeedViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithUserID:(int) userID {
    self = [super init];
    if (self) {
        _userID = userID;
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
    UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithTitle:@"Get news"
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(openFindFriendsView)];
    self.navigationItem.rightBarButtonItem = anotherButton;
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

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 120;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //nothing yet
}

- (void) asynchFetchFeeds {
    //Asynchronous Request
    @try {
        
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@?mobile=1", RCServiceURL]];
        
        NSURLRequest *request = CreateHttpGetRequest(url);
        
        NSURLConnection *connection = [[NSURLConnection alloc]
                                       initWithRequest:request
                                       delegate:self
                                       startImmediately:YES];
        _receivedData = [[NSMutableData alloc] init];
        
        if(!connection) {
            NSLog(@"Connection Failed.");
        } else {
            NSLog(@"Connection Succeeded.");
        }
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        alertStatus(@"Failure getting friends from web service",@"Connection Failed!",self);
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
 	//NSLog(@"Received response: %@", response);
 	
    [_receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
 	//NSLog(@"Received %d bytes of data", [data length]);
 	
    [_receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
 	NSLog(@"Error receiving response: %@", error);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSString *responseData = [[NSString alloc]initWithData:_receivedData encoding:NSUTF8StringEncoding];
    
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
    }else {
        alertStatus([NSString stringWithFormat:@"Failed to obtain news feed, please try again! %@", responseData], @"Connection Failed!", self);
    }
}


@end
