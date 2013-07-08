//
//  RCPostDetailsViewController.m
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 5/6/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCConstants.h"
#import "RCPostDetailsViewController.h"
#import "RCAmazonS3Helper.h"
#import "SBJson.h"
#import "RCUtilities.h"
#import "RCConnectionManager.h"
#import "RCKeyboardPushUpHandler.h"
#import "RCResourceCache.h"

@interface RCPostDetailsViewController ()
@property (nonatomic,strong) NSMutableArray* comments;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@end

@implementation RCPostDetailsViewController

@synthesize post = _post;
@synthesize postOwner = _postOwner;
@synthesize loggedInUser = _loggedInUser;
@synthesize comments = _comments;
@synthesize tapGestureRecognizer = _tapGestureRecognizer;

BOOL _isTapToCloseKeyboard;
BOOL _firstTimeEditPost;
RCConnectionManager *_connectionManager;
RCKeyboardPushUpHandler *_keyboardPushHandler;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id) initWithPost:(RCPost *)post withOwner:(RCUser*)owner withLoggedInUser:(RCUser *) loggedInUser{
    self = [super init];
    if (self) {
        _post = post;
        _postOwner = owner;
        _loggedInUser = loggedInUser;
        _connectionManager = [[RCConnectionManager alloc] init];
        _keyboardPushHandler = [[RCKeyboardPushUpHandler alloc] init];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [_connectionManager reset];
    
    [_keyboardPushHandler reset];
    _keyboardPushHandler.view = self.view;
    
    _tblViewPostDiscussion.tableFooterView = [[UIView alloc] init];
    _comments = [[NSMutableArray alloc] init];
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Delete Post" style:UIBarButtonItemStylePlain target:self action:@selector(deletePost)];
    self.navigationItem.rightBarButtonItem = rightButton;
    
    [_btnComment setImage:[UIImage imageNamed:@"viewPostCommentButton-highlighted.png"] forState:UIControlStateHighlighted];
    _lblUsername.text = _post.authorName;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd/M/yyyy"];
    _lblDatePosted.text = [formatter stringFromDate:_post.createdTime];
    _lblLandmark.text = @"";
    
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.view addGestureRecognizer:_tapGestureRecognizer];
    _isTapToCloseKeyboard = NO;
    _firstTimeEditPost = YES;
    
    [self getPostImageFromInternet];
    [self asynchGetCommentsRequest];
    [self animateViewAppearance];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - tap gesture handler
-(void) handleTap:(UITapGestureRecognizer *)tapGestureRecognizer {
    if (_isTapToCloseKeyboard){
        [self backgroundTap:nil];
        _isTapToCloseKeyboard = NO;
    }
    else {
        CGPoint point = [tapGestureRecognizer locationInView:_imgViewMainFrame];
        //CGRect frame = _imageViewPostFrame.frame;
        if (![_imgViewMainFrame pointInside:point withEvent:nil])
            [self animateViewDisapperance:^ {
                [self.view removeFromSuperview];
                [self removeFromParentViewController];
            }];
    }
}

#pragma mark - web request
-(void) getPostImageFromInternet {
    
    RCResourceCache *cache = [RCResourceCache centralCache];
    NSString *key = [NSString stringWithFormat:@"%@/%d", RCPostsResource, _post.postID];
    dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
    dispatch_async(queue, ^{
        UIImage* cachedImg = (UIImage*)[cache getResourceForKey:key usingQuery:^{
            [_connectionManager startConnection];
            UIImage *image = [RCAmazonS3Helper getUserMediaImage:_postOwner withLoggedinUserID:_loggedInUser.userID   withImageUrl:_post.fileUrl];
            [_connectionManager endConnection];
            return image;
        }];
        if (cachedImg != nil)
            dispatch_async(dispatch_get_main_queue(), ^{
                [_imgViewPostImage setImage:cachedImg];
            });
    });

}


#pragma mark - delete post
- (void) deletePost {
    confirmationDialog(@"Are you sure you want to delete this post?", @"Confirmation", self);
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0){
        [self asynchDeletePost];
    }
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    _isTapToCloseKeyboard = YES;
    if ([textView isEqual:_txtViewPostComment]) {
        // register for keyboard notifications
        
        if (_firstTimeEditPost )   {
            [textView setText:@""];
            _firstTimeEditPost = NO;
        }
    }
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1 + [_comments count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    
    int idx = [indexPath row];
    if (idx == 0)
        cell.textLabel.text = _post.content;
    else
        cell.textLabel.text = [_comments objectAtIndex:(idx-1)];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 30;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

#pragma mark - web request
- (void) asynchPostComment {
    [_txtViewPostComment resignFirstResponder];
    _btnComment.enabled = NO;
    //Asynchronous Request
    @try {
        NSString* commentContent = [_txtViewPostComment text];
        NSMutableString *dataSt = initQueryString(@"comment[content]", commentContent);
        addArgumentToQueryString(dataSt, @"post_id",[NSString stringWithFormat:@"%d", _post.postID]);
        NSData *postData = [dataSt dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@", RCServiceURL, RCCommentsResource]];
        
        NSURLRequest *request = CreateHttpPostRequest(url, postData);
        [_connectionManager startConnection];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             bool _successfulPost;
             NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
             int responseStatusCode = [httpResponse statusCode];
             [_connectionManager endConnection];
             if (responseStatusCode != RCHttpOkStatusCode) {
                 _successfulPost = NO;
             } else _successfulPost = YES;
             
             
             _btnComment.enabled = YES;
             
             NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
             NSLog(@"%@",responseData);
             
             //Temporary:
             if (_successfulPost) {
                 [_comments addObject:commentContent];
                 [_tblViewPostDiscussion reloadData];
                 _txtViewPostComment.text = @"";
                 
             }else {
                 alertStatus([NSString stringWithFormat:@"Please try again! %@", responseData], @"Comment Failed!", nil);
             }
         }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
         _btnComment.enabled = YES;
        alertStatus(@"Post Failed.",@"Post Failed!",nil);
    }
}

- (void) asynchGetCommentsRequest {
    //Asynchronous Request
    @try {
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d/comments?mobile=1", RCServiceURL, RCPostsResource, _post.postID]];
        NSURLRequest *request = CreateHttpGetRequest(url);
        [_connectionManager startConnection];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             [_connectionManager endConnection];
             [_comments removeAllObjects];
             NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
             SBJsonParser *jsonParser = [[SBJsonParser alloc] init];
             NSArray* commentsJson = (NSArray*) [jsonParser objectWithString:responseString error:nil];
             for (NSDictionary *commentHash in commentsJson) {
                 [_comments addObject:[commentHash objectForKey:@"content"]];
             }
             [_tblViewPostDiscussion reloadData];
             
         }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        alertStatus(@"Failure getting friends from web service",@"Connection Failed!",nil);
    }
}

- (void) asynchDeletePost {
    //Asynchronous Request
    @try {
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d?mobile=1", RCServiceURL, RCPostsResource, _post.postID]];
        NSURLRequest *request = CreateHttpDeleteRequest(url);
        [_connectionManager startConnection];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             [_connectionManager endConnection];
             NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
             NSLog(@"Post deletion status string: %@", responseData);
             
             if ([responseData isEqualToString:@"ok"]){
                 alertStatus(@"Post deleted successfully!", @"Success!", nil);
                 [self.view removeFromSuperview];
                 [self removeFromParentViewController];
             }else if ([responseData isEqualToString:@"error"]){
                 alertStatus(@"Please try again!", @"Deletion Failed", nil);
             }
             
              /*SBJsonParser *jsonParser = [SBJsonParser new];
              NSDictionary *jsonData = (NSDictionary *) [jsonParser objectWithString:responseData error:nil];
              NSLog(@"Post deleted: %@",jsonData);*/
             
         }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        alertStatus(@"Failure deleting post.", @"Connection Failed!", nil);
    }

}

#pragma mark - code to move views up/down appropriately when keyboard is going to cover text field

- (void)viewWillAppear:(BOOL)animated
{
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:_keyboardPushHandler
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:_keyboardPushHandler
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    if ([[UIScreen mainScreen] bounds].size.height < RCIphone5Height) {
        [_closeButton setHidden:YES];
        [_closeButton setEnabled:NO];
        CGRect closeFrame = _closeButton.frame;
        closeFrame.origin.y += 20;
        UIButton *newCloseButton = [[UIButton alloc] initWithFrame:closeFrame];
        [newCloseButton setImage:[UIImage imageNamed:@"closeButton.png"] forState:UIControlStateNormal];
        [newCloseButton addTarget:self action:@selector(btnCloseTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:newCloseButton];
        CGRect frame = self.view.frame;
        //move view up so that the whole post frame fits in iphone 4 screen
        //here we basically move the y coordinate back by exactly the amount
        //with which the post frame is away from screen top edge
        //leaving some gap in between
        frame.origin.y = -_imgViewMainFrame.frame.origin.y + 2;
        frame.size.height +=  _imgViewMainFrame.frame.origin.y - 2;
        self.view.frame = frame;
        
    }
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:_keyboardPushHandler
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:_keyboardPushHandler
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    [super viewWillDisappear:animated];
}

#pragma mark - ui events

- (IBAction)backgroundTap:(id)sender {
    [_txtViewPostComment resignFirstResponder];
}

#pragma mark - UITextFieldDelegate methods

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [textField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}
- (IBAction)btnCloseTouchUpInside:(id)sender {
    [self animateViewDisapperance:^ {
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
    }];
}
- (IBAction)commentButtonTouchUpInside:(id)sender {
    [self asynchPostComment];
}
@end
