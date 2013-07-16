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
#import "RCUtilities.h"
#import "RCComment.h"
#import "RCConnectionManager.h"
#import "RCKeyboardPushUpHandler.h"
#import "RCResourceCache.h"
#import "RCCommentPostingViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "SBJson.h"

@interface RCPostDetailsViewController ()
@property (nonatomic, strong) NSMutableArray* comments;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, strong) NSURL* videoUrl;
@property (nonatomic, strong) MPMoviePlayerController *player;
@property (nonatomic, strong) UIImageView* imageViewFullPost;
@property (nonatomic, strong) UIImage*     postImage;
@property (nonatomic, assign) BOOL         didMoveCommentsBox;
@property (nonatomic, assign) CGFloat      commentsBoxMovedBy;
@property (nonatomic, assign) int          currentCommentID;
@end

@implementation RCPostDetailsViewController

@synthesize post = _post;
@synthesize postOwner = _postOwner;
@synthesize loggedInUser = _loggedInUser;
@synthesize comments = _comments;
@synthesize tapGestureRecognizer = _tapGestureRecognizer;
@synthesize landmark = _landmark;
@synthesize videoUrl = _videoUrl;
@synthesize player = _player;
@synthesize landmarkID = _landmarkID;
@synthesize imageViewFullPost = _imageViewFullPost;
@synthesize postImage = _postImage;
@synthesize didMoveCommentsBox = _didMoveCommentsBox;
@synthesize commentsBoxMovedBy = _commentsBoxMovedBy;
@synthesize currentCommentID = _currentCommentID;

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
- (IBAction) openCommentPostingView:(id) sender {
    RCCommentPostingViewController *commentPostingViewController = [[RCCommentPostingViewController alloc] init];
    commentPostingViewController.postComplete = ^(NSString* content){
        [self asynchPostComment:content];
    };
    
    [self addChildViewController:commentPostingViewController];
    [self.view addSubview:commentPostingViewController.view];
    CGRect frame = self.view.frame;
    frame.origin.y += frame.size.height;
    commentPostingViewController.view.frame = frame;
    [commentPostingViewController didMoveToParentViewController:self];
    [commentPostingViewController.lblAuthorName setText:_loggedInUser.name];
    [UIView animateWithDuration:0.5
						  delay:0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
                         commentPostingViewController.view.frame = self.view.frame;
					 }
                     completion:^(BOOL finished) {
                         ;
					 }];
    
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [_connectionManager reset];
    
    //[_keyboardPushHandler reset];
    //_keyboardPushHandler.view = self.view;
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTitle:@"Comment" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(openCommentPostingView) forControlEvents:UIControlEventTouchUpInside];
    
    _tblViewPostDiscussion.tableFooterView = [[UIView alloc] init];//button;
    [_tblViewPostDiscussion setSeparatorColor:[UIColor whiteColor]];
    _currentCommentID = -1;
    _comments = [[NSMutableArray alloc] init];
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Delete Post" style:UIBarButtonItemStylePlain target:self action:@selector(deletePost)];
    self.navigationItem.rightBarButtonItem = rightButton;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd/M/yyyy"];
    
    _lblDatePosted.text = [formatter stringFromDate:_post.createdTime];
    _lblPostSubject.text = _post.subject;
    [_lblPostSubject setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.4]];
    _lblUsername.text = _post.authorName;
    if (_landmark != nil) {
        _lblUsername.text = [NSString stringWithFormat:@"%@ @ %@", _post.authorName, _landmark.name];
        UIImage *landmarkImage = [UIImage imageNamed:[NSString stringWithFormat:@"landmarkCategory%@.png",_landmark.category]];
        [_imgViewLandmarkCategory setImage:landmarkImage];
    }
    else {
        if (_landmarkID != -1) {
            dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
            dispatch_async(queue, ^{
                _landmark = [RCLandmark getLandmark:_landmarkID];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (_landmark != nil) {
                        _lblUsername.text = [NSString stringWithFormat:@"%@ @ %@", _post.authorName, _landmark.name];
                        UIImage *landmarkImage = [UIImage imageNamed:[NSString stringWithFormat:@"landmarkCategory%@.png",_landmark.category]];
                        [_imgViewLandmarkCategory setImage:landmarkImage];
                    }
                });
            });
        }
    }
    
    //initialize comments box
    UIImage *image = [[UIImage imageNamed:@"viewPostCommentFrame.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(70,5,30,5)];
    [_imgViewCommentFrame setImage:image];
    _didMoveCommentsBox = NO;
    _commentsBoxMovedBy = 0;
    
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.view addGestureRecognizer:_tapGestureRecognizer];
    _isTapToCloseKeyboard = NO;
    _firstTimeEditPost = YES;
    
    [self getPostImageFromInternet];
    [self asynchGetCommentsRequest];
    //[self animateViewAppearance];
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
            ;/*[self animateViewDisapperance:^ {
                [self.view removeFromSuperview];
                [self removeFromParentViewController];
            }];*/
    }
}

#pragma mark - web request
-(void) getPostImageFromInternet {
    
    RCResourceCache *cache = [RCResourceCache centralCache];
    NSString *key = [NSString stringWithFormat:@"%@/%d", RCPostsResource, _post.postID];
    dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
    dispatch_async(queue, ^{
        NSObject* cachedObj = [cache getResourceForKey:key usingQuery:^{
            [_connectionManager startConnection];
            NSObject *object = [RCAmazonS3Helper getUserMediaImage:_postOwner withLoggedinUserID:_loggedInUser.userID   withImageUrl:_post.fileUrl];
            [_connectionManager endConnection];
            return object;
        }];
        UIImage *thumbnailImage;
        //if returned object is a string, this means the post is a movie
        if (![cachedObj isKindOfClass:[UIImage class]]) {
            NSString *thumbnailKey = [NSString stringWithFormat:@"%@-thumbnail",key];
            thumbnailImage = [cache getResourceForKey:thumbnailKey usingQuery:^{
                [_connectionManager startConnection];
                NSObject *object = [RCAmazonS3Helper getUserMediaImage:_postOwner withLoggedinUserID:_loggedInUser.userID   withImageUrl:_post.thumbnailUrl];
                [_connectionManager endConnection];
                return object;
            }];

        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (cachedObj != nil && [cachedObj isKindOfClass:[UIImage class]]) {
                _postImage = (UIImage *)cachedObj;
                [self setupImageScrollView];
            }
            else if (cachedObj != nil && [cachedObj isKindOfClass:[NSString class]]) {
                NSString *fileName = (NSString*) cachedObj;
                _videoUrl = [NSURL fileURLWithPath:fileName];
                UIButton *playVideoButton = [[UIButton alloc] initWithFrame:_scrollViewImage.frame];
                [playVideoButton addTarget:self action:@selector(playVideo:) forControlEvents:UIControlEventTouchUpInside];
                [playVideoButton setImage:[UIImage imageNamed:@"postVideoSourceButton-normal.png"] forState:UIControlStateNormal];
                _postImage = thumbnailImage;
                [self setupImageScrollView];
                //[self.view addSubview:playVideoButton];
                //[_imgViewPostImage addGestureRecognizer:tapRecognizer];
            } else if (cachedObj != nil && [cachedObj isKindOfClass:[NSURL class]]) {
                _videoUrl = (NSURL*)cachedObj;
                CGRect frame =  _scrollViewImage.frame;
                frame.origin.x += frame.size.width / 4;
                frame.size.width /= 2;
                frame.origin.y += (frame.size.height - frame.size.width) / 2;
                frame.size.height = frame.size.width;
                UIButton *playVideoButton = [[UIButton alloc] initWithFrame:frame];
                [playVideoButton addTarget:self action:@selector(playVideo:) forControlEvents:UIControlEventTouchUpInside];
                [playVideoButton setImage:[UIImage imageNamed:@"buttonPlay.png"] forState:UIControlStateNormal];
                _postImage = thumbnailImage;
                [self setupImageScrollView];
                [self.view addSubview:playVideoButton];
            }
        });
    });

}

- (void) setupImageScrollView {
    UIImage *image = _postImage;
    _scrollViewImage.delegate = self;
    _imageViewFullPost = [[UIImageView alloc] initWithImage:image];
    CGSize size = _imageViewFullPost.frame.size;
    _scrollViewImage.contentSize = size;
    [_scrollViewImage addSubview:_imageViewFullPost];
    _scrollViewImage.minimumZoomScale = MIN(1.0,_scrollViewImage.frame.size.width/image.size.width);
    _scrollViewImage.zoomScale = _scrollViewImage.frame.size.width/image.size.width;
    if (abs(_scrollViewImage.zoomScale - 1.0) < 1e-9) {
        [self scrollViewDidZoom:_scrollViewImage];
    }
}

- (void) setupImageFullScreenView {
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    [appDelegate disableSideMenu];
    UIImage *image = _postImage;
    //_scrollViewImage = [[UIScrollView alloc] initWithFrame:self.navigationController.view.frame];
    _scrollViewImage.delegate = self;
    [_scrollViewImage setBackgroundColor:[UIColor blackColor]];
    _imageViewFullPost = [[UIImageView alloc] initWithImage:image];
    _scrollViewImage.contentSize = _imageViewFullPost.frame.size;
    [_scrollViewImage addSubview:_imageViewFullPost];
    _scrollViewImage.minimumZoomScale = MIN(1.0,_scrollViewImage.frame.size.width/image.size.width);
    _scrollViewImage.zoomScale = _scrollViewImage.minimumZoomScale;
    [self.navigationController.view addSubview:_scrollViewImage];
    //[self.view addSubview:_scrollViewImage];
    _scrollViewImage.frame = self.navigationController.view.frame;
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    //[closeButton setBackgroundImage:[UIImage imageNamed:@"magnifyingGlass.png"] forState:UIControlStateNormal];
    [closeButton setBackgroundImage:[UIImage imageNamed:@"btnTransparent-normal"] forState:UIControlStateNormal];
    [closeButton setTitle:@"Done" forState:UIControlStateNormal];
    [closeButton setBackgroundColor:[UIColor clearColor]];
    [closeButton addTarget:self action:@selector(closeImageFullScreen:) forControlEvents:UIControlEventTouchUpInside];
    [self.navigationController.view addSubview:closeButton];
    closeButton.frame = CGRectMake(10, 10, 60, 25);
}

- (void) closeImageFullScreen: (UIButton*) closeButton {
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    [appDelegate enableSideMenu];
    [closeButton removeFromSuperview];
    [_scrollViewImage removeFromSuperview];
}

#pragma mark - UIScrollView delegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageViewFullPost;
}
- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    UIView *subView = _imageViewFullPost;
    
    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width)?
    (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
    
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height)?
    (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    
    subView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX,
                                 scrollView.contentSize.height * 0.5 + offsetY);
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

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1 + [_comments count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    int idx = [indexPath row];
    
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0];
    if (idx == 0) {
        if ([cell.textLabel respondsToSelector:@selector(setAttributedText:)])
            [cell.textLabel setAttributedText:[self generateAttributesStringForUser:_post.authorName forComment:_post.content]];
         else
            [cell.textLabel setText:[NSString stringWithFormat:@"%@: %@",_post.authorName,_post.content]];
    } else {
        RCComment *comment = [_comments objectAtIndex:(idx-1)];
        if ([cell.textLabel respondsToSelector:@selector(setAttributedText:)])
            [cell.textLabel setAttributedText:[self generateAttributesStringForUser:comment.authorName forComment:comment.content]];
         else
            [cell.textLabel setText:[NSString stringWithFormat:@"%@: %@",comment.authorName,comment.content]];
    }
    
    
    
    //label.adjustsFontSizeToFitWidth = YES;
    //label.adjustsLetterSpacingToFitWidth = NO;  // this crashes on iOS 6.1
    

    return cell;
}
    
- (NSMutableAttributedString *) generateAttributesStringForUser:(NSString*)userName forComment:(NSString*) comment {
    NSString *textContent = [NSString stringWithFormat:@"%@ %@",userName, comment];
    
    UIFont *boldFont = [UIFont fontWithName:@"Helvetica-Bold" size:17.0];
    UIFont *regularFont = [UIFont fontWithName:@"Helvetica" size:17.0];
    UIColor *foregroundColor = [UIColor blackColor];
    
    // Create the attributes
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           regularFont, NSFontAttributeName, nil];
    NSDictionary *subAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                              boldFont, NSFontAttributeName,
                              foregroundColor, NSForegroundColorAttributeName, nil];
    NSRange range = NSMakeRange(0,[userName length]);
    // Create the attributed string (text + attributes)
    NSMutableAttributedString *attributedText =
    [[NSMutableAttributedString alloc] initWithString:textContent
                                           attributes:attrs];
    [attributedText setAttributes:subAttrs range:range];
    return attributedText;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    //magic number
    CGFloat extra = 20.0;
    NSString *cellText;
    if (indexPath.row > 0) {
        RCComment *comment = (RCComment*)[_comments objectAtIndex:indexPath.row - 1];
        cellText = comment.content;
    }
    else {
        cellText = [NSString stringWithFormat:@"%@ %@",_post.authorName,_post.content];
        if ([[UILabel alloc] respondsToSelector:@selector(setAttributedText:)])
        {
            //this is because when drawing attributed text the label seems to be further away from the boundary for some reason
            extra += 10;
        }
    }
    
    UIFont *cellFont = [UIFont fontWithName:@"Helvetica" size:17.0];
    CGSize constraintSize = CGSizeMake(_tblViewPostDiscussion.frame.size.width, MAXFLOAT);
    CGSize labelSize = [cellText sizeWithFont:cellFont constrainedToSize:constraintSize lineBreakMode:NSLineBreakByWordWrapping];
    
    return labelSize.height + extra;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

#pragma mark - web request
- (void) asynchPostComment:(NSString*) commentContent {
    //Asynchronous Request
    @try {
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
                 SBJsonParser *jsonParser = [[SBJsonParser alloc] init];
                 NSDictionary* commentJson = (NSDictionary*) [jsonParser objectWithString:responseData error:nil];
                 _currentCommentID = [[commentJson objectForKey:@"id"] intValue];
                [self asynchGetCommentsRequest];
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
                 RCComment *comment = [[RCComment alloc] initWithNSDictionary:commentHash];
                 if (comment.commentID == _currentCommentID) {
                     NSIndexPath *indexPath = [NSIndexPath indexPathForRow:([_comments count]+1) inSection:0];
                     [_tblViewPostDiscussion scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
                     _currentCommentID = -1;
                 }
                 [_comments addObject:comment];
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
    [self dismissViewControllerAnimated:YES completion:nil];/*[self animateViewDisapperance:^ {
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
    }];*/
}

- (IBAction)commentButtonTouchUpInside:(id)sender {
    [UIView animateWithDuration:0.5
						  delay:0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
                         CGRect frame1 = _imgViewCommentFrame.frame;
                         CGRect frame2 = _tblViewPostDiscussion.frame;
                         CGRect frame3 = _btnComment.frame;
                         CGFloat moveBy;
                         if (_didMoveCommentsBox) {
                             _didMoveCommentsBox = NO;
                             moveBy = -_commentsBoxMovedBy;
                         }
                         else {
                             moveBy = 200 - _commentsBoxMovedBy;
                             _didMoveCommentsBox = YES;
                         }
                         frame3.origin.y -= moveBy;
                         frame1.origin.y -= moveBy;
                         frame1.size.height += moveBy;
                         frame2.origin.y -= moveBy;
                         frame2.size.height += moveBy;
                         _commentsBoxMovedBy += moveBy;
                         _imgViewCommentFrame.frame = frame1;
                         _tblViewPostDiscussion.frame = frame2;
                         _btnComment.frame = frame3;
					 }
                     completion:^(BOOL finished) {
                         ;
					 }];
    //[self asynchPostComment];
}

-(IBAction) playVideo:(id)sender
{
    
    _player=[[MPMoviePlayerController alloc] initWithContentURL:_videoUrl];
    [_player setShouldAutoplay:NO];
    [_player setScalingMode:MPMovieScalingModeAspectFit];
    _player.controlStyle=MPMovieControlStyleDefault;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayBackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:_player];
    
    // Register that the load state changed (movie is ready)
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(moviePlayerLoadStateChanged:)
     name:MPMoviePlayerLoadStateDidChangeNotification
     object: _player];
    
    
    [self.view addSubview:_player.view];
    [_player setFullscreen:YES animated:YES];
    
    [_player prepareToPlay];
    
    
}
//https://rcusersmedia.s3.amazonaws.com/0FFDE01D57FD4452B737CD46DDE8DD91.mov?AWSAccessKeyId=AKIAJVYGWBMHL24XPXYA&Expires=1373727042&Signature=vEL0U9%2FF1rsoLaZjbYbYzVKMguk%3D
//https://rcusersmedia.s3.amazonaws.com/0FFDE01D57FD4452B737CD46DDE8DD91?AWSAccessKeyId=AKIAJVYGWBMHL24XPXYA&Expires=1373726466&Signature=k5cQgBxd3rfetQaM2yme0UukT5Q%3D
//http://d1ftqtsbckf6jv.cloudfront.net/using_glossaries.mp4
-(IBAction) playVideoFromInternet:(id)sender
{
    NSURL *url=[[NSURL alloc] initWithString:@"https://rcusersmedia.s3.amazonaws.com/0FFDE01D57FD4452B737CD46DDE8DD91.mov?AWSAccessKeyId=AKIAJVYGWBMHL24XPXYA&Expires=1373727042&Signature=vEL0U9%2FF1rsoLaZjbYbYzVKMguk%3D"];
    
    _player=[[MPMoviePlayerController alloc] initWithContentURL:url];
    
    [_player setShouldAutoplay:NO];
    
    [_player setScalingMode:MPMovieScalingModeAspectFit];
    
    _player.controlStyle=MPMovieControlStyleDefault;
    
    [[NSNotificationCenter defaultCenter] addObserver:nil selector:@selector(moviePlayBackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:_player];
    
    // Register that the load state changed (movie is ready)
    [[NSNotificationCenter defaultCenter]
     addObserver:nil
     selector:@selector(moviePlayerLoadStateChanged:)
     name:MPMoviePlayerLoadStateDidChangeNotification
     object: _player];
    
    
    [self.view addSubview:_player.view];
    [_player setFullscreen:YES animated:YES];
    
    [_player prepareToPlay];
    
    
}

- (void) moviePlayBackDidFinish:(NSNotification *) notification {
    NSLog(@"movie playback done");
    //[notification.userInfo obj]
    NSNumber *finishReason = (NSNumber *)[notification.userInfo objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
    if ([finishReason integerValue] == MPMovieFinishReasonPlaybackError) {
        RCResourceCache *cache = [RCResourceCache centralCache];
        NSString *key = [NSString stringWithFormat:@"%@/%d", RCPostsResource, _post.postID];
        dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
        dispatch_async(queue, ^{
            [cache invalidateKey:key];
            _videoUrl = (NSURL*) [cache getResourceForKey:key usingQuery:^{
                [_connectionManager startConnection];
                NSObject *object = [RCAmazonS3Helper getUserMediaImage:_postOwner withLoggedinUserID:_loggedInUser.userID   withImageUrl:_post.fileUrl];
                [_connectionManager endConnection];
                return object;
            }];
            dispatch_async(dispatch_get_main_queue(), ^{
                _player.contentURL = _videoUrl;
                [_player play];
            });
        });

    }
}

- (void) moviePlayerLoadStateChanged:(id) sender {
    NSLog(@"movie player load state changed");
}
@end
