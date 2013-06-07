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

@interface RCPostDetailsViewController ()
@property (nonatomic,strong) NSMutableArray* comments;
@property (nonatomic,strong) UITextField* textField;
@end

@implementation RCPostDetailsViewController
int         _openConnections;
@synthesize post = _post;
@synthesize postOwner = _postOwner;
@synthesize loggedInUser = _loggedInUser;
@synthesize comments = _comments;
@synthesize barItemTextField = _barItemTextField;
@synthesize textField = _textField;

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
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _openConnections = 0;
    _tblViewPostDiscussion.tableFooterView = [[UIView alloc] init];
    _comments = [[NSMutableArray alloc] init];
    CGRect frame = CGRectMake(0, 0, 240, 30);
    _textField = [[UITextField alloc] initWithFrame:frame];
    _textField.placeholder = @"Write a comment...";
    _textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _textField.backgroundColor = [UIColor whiteColor];
    _textField.borderStyle = UITextBorderStyleRoundedRect;
    _textField.textColor = [UIColor blackColor];
    _textField.font = [UIFont systemFontOfSize:14.0];
    _textField.autocorrectionType = UITextAutocorrectionTypeNo;
    _textField.keyboardType = UIKeyboardTypeDefault;
    _textField.returnKeyType = UIReturnKeyDone;
    _textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _textField.delegate = self;
    
    UIBarButtonItem *textFieldItem = [[UIBarButtonItem alloc] initWithCustomView:_textField];
    UIBarButtonItem *postButton = [[UIBarButtonItem alloc] initWithTitle:@"Post" style:UIBarButtonItemStyleDone  target:self action:@selector(asynchPostComment)];
    NSArray *topBarItems = [NSArray arrayWithObjects: textFieldItem, postButton, nil];
    [_toolBar setItems:topBarItems animated:NO];
    [self getPostImageFromInternet];
    [self asynchGetCommentsRequest];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - web request
-(void) getPostImageFromInternet {
    [self startConnection];
    dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
    dispatch_async(queue, ^{
        UIImage *image = [RCAmazonS3Helper getUserMediaImage:_postOwner withLoggedinUserID:_loggedInUser.userID   withImageUrl:_post.fileUrl];
        [self endConnection];
        if (image != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_imgViewPostImage setImage:image];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                alertStatus(@"Couldn't connect to the server. Please try again later", @"Network error", self);
            });
        }
    });
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
    [_textField resignFirstResponder];
    //Asynchronous Request
    @try {
        NSString* commentContent = [_textField text];
        NSMutableString *dataSt = initQueryString(@"comment[content]", commentContent);
        addArgumentToQueryString(dataSt, @"post_id",[NSString stringWithFormat:@"%d", _post.postID]);
        NSData *postData = [dataSt dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@", RCServiceURL, RCCommentsResource]];
        
        NSURLRequest *request = CreateHttpPostRequest(url, postData);
        [self startConnection];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             bool _successfulPost;
             NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
             int responseStatusCode = [httpResponse statusCode];
             [self endConnection];
             if (responseStatusCode != RCHttpOkStatusCode) {
                 _successfulPost = NO;
             } else _successfulPost = YES;
             
             
             self.navigationItem.rightBarButtonItem.enabled = YES;
             
             NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
             NSLog(@"%@",responseData);
             
             //Temporary:
             if (_successfulPost) {
                 [_comments addObject:commentContent];
                 [_tblViewPostDiscussion reloadData];
                 _textField.text = @"";
                 
             }else {
                 alertStatus([NSString stringWithFormat:@"Please try again! %@", responseData], @"Comment Failed!", self);
             }
         }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        self.navigationItem.rightBarButtonItem.enabled = YES;
        alertStatus(@"Post Failed.",@"Post Failed!",self);
    }
}

- (void) asynchGetCommentsRequest {
    //Asynchronous Request
    @try {
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d/comments?mobile=1", RCServiceURL, RCPostsResource, _post.postID]];
        NSURLRequest *request = CreateHttpGetRequest(url);
        [self startConnection];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             [self endConnection];
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
        alertStatus(@"Failure getting friends from web service",@"Connection Failed!",self);
    }
}

-(void)startConnection {
    _openConnections++;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

-(void) endConnection {
    _openConnections--;
    if (_openConnections == 0)
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

#pragma mark - code to move views up/down appropriately when keyboard is going to cover text field

- (void)viewWillAppear:(BOOL)animated
{
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    [super viewWillDisappear:animated];
}

-(void)keyboardWillShow:(NSNotification*)notification {
    NSDictionary* userInfo = [notification userInfo];
    CGRect keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    [self setViewMovedUp:YES offset:(keyboardFrame.size.height)];
    
}

- (void) keyboardWillHide:(NSNotification*)notification {
    NSDictionary* userInfo = [notification userInfo];
    CGRect keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    [self setViewMovedUp:NO offset:(keyboardFrame.size.height)];
    
}

//method to move the view up/down whenever the keyboard is shown/dismissed
- (void) setViewMovedUp:(BOOL)movedUp offset:(double)kOffsetForKeyboard
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3]; // if you want to slide up the view
    
    CGRect rect = self.view.frame;
    if (movedUp)
    {
        rect.origin.y -= kOffsetForKeyboard;
    }
    else
    {
        // revert back to the normal state.
        rect.origin.y += kOffsetForKeyboard;
    }
    self.view.frame = rect;
    
    [UIView commitAnimations];
}

#pragma mark - ui events

- (IBAction)backgroundTap:(id)sender {
    if ([_textField isEditing])
        [_textField resignFirstResponder];
}

#pragma mark - UITextFieldDelegate methods

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [_textField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}
@end
