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
#import "RCPostReport.h"

#import "RCConnectionManager.h"
#import "RCKeyboardPushUpHandler.h"
#import "RCResourceCache.h"
#import "RCCommentPostingViewController.h"
#import "RCFriendListViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "SBJson.h"
#import "RCUserProfileViewController.h"

@interface RCPostDetailsViewController ()
@property (nonatomic, strong) NSMutableArray* comments;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, strong) NSURL* videoUrl;
@property (nonatomic, strong) MPMoviePlayerController *player;
@property (nonatomic, strong) UIImageView* imageViewFullPost;
@property (nonatomic, strong) UIImage*     postImage;
@property (nonatomic, strong) UIImageView* descriptionMarker;
@property (nonatomic, assign) BOOL         didMoveCommentsBox;
@property (nonatomic, assign) CGFloat      commentsBoxMovedBy;
@property (nonatomic, assign) int          currentCommentID;
@property (nonatomic, assign) BOOL         didStartDraggingCommentBox;
@property (nonatomic, assign) CGFloat      originalCommentBoxPosition;
@property (nonatomic, strong) UIActivityIndicatorView* activityIndicatorView;

@end

@implementation RCPostDetailsViewController {
    int _currentReportChoice;
    BOOL _isTapToCloseKeyboard;
    BOOL _firstTimeEditPost;
    RCConnectionManager *_connectionManager;
    RCKeyboardPushUpHandler *_keyboardPushHandler;
}

@synthesize descriptionMarker = _descriptionMarker;
@synthesize activityIndicatorView = _activityIndicatorView;
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
@synthesize didStartDraggingCommentBox = _didStartDraggingCommentBox;
@synthesize originalCommentBoxPosition = _originalCommentBoxPosition;
@synthesize deleteFunction = _deleteFunction;


static BOOL RCPostDetailsViewControllerShowPostID = NO;

+ (void) toggleShowPostID {
    if (RCPostDetailsViewControllerShowPostID)
        RCPostDetailsViewControllerShowPostID = NO;
    else
        RCPostDetailsViewControllerShowPostID = YES;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _currentReportChoice = 0;
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
        _currentReportChoice = 0;
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
                         [self resetUIViewsState];
					 }];
    
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTitle:@"Comment" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(openCommentPostingView) forControlEvents:UIControlEventTouchUpInside];
    
    _tblViewPostDiscussion.tableFooterView = [[UIView alloc] init];//button;
    //_tblViewPostDiscussion.contentInset = UIEdgeInsetsMake(0,-8,0,-8);

    //[_tblViewPostDiscussion setSeparatorColor:[UIColor whiteColor]];
    _currentCommentID = -1;
    _comments = [[NSMutableArray alloc] init];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd/M/yyyy"];
    
    _lblDatePosted = [[UILabel alloc] init];
    [_lblDatePosted setBackgroundColor:[UIColor clearColor]];
    [_lblDatePosted setTextColor:[UIColor whiteColor]];

    _lblDatePosted.font = [UIFont fontWithName:_lblPostSubject.font.fontName size:13.0];
    _lblDatePosted.text =  [formatter stringFromDate:_post.postedTime == nil ? _post.createdTime : _post.postedTime];
    _lblPostSubject.text = _post.subject;
    [_lblDatePosted sizeToFit];
    [_lblPostSubject setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.4]];
    if (_post.topic == nil)
        _lblUsername.text = _post.authorName;
    else
        _lblUsername.text = [NSString stringWithFormat:@"%@ @ %@",_post.authorName, _post.topic];
    
    if (RCPostDetailsViewControllerShowPostID) {
        NSString *formerText = _lblUsername.text;
        _lblUsername.text = [NSString stringWithFormat:@"%d %@", _post.postID, formerText];
    }
    
    [_lblUsername sizeToFit];
    [self.viewCoverStrip addSubview:_lblDatePosted];
    CGRect dateLabelFrame = _lblDatePosted.frame;
    dateLabelFrame.origin.x = _lblUsername.frame.origin.x + _lblUsername.frame.size.width + 15.0;
    dateLabelFrame.origin.y = _lblUsername.frame.origin.y + (_lblUsername.frame.size.height - dateLabelFrame.size.height);
    _lblDatePosted.frame = dateLabelFrame;
    
    //setup release time if there's one:
    if (_post.isTimeCapsule && [_post.releaseDate compare:[NSDate date]] == NSOrderedDescending) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setTimeZone:[NSTimeZone systemTimeZone]];
        [formatter setDateFormat:@"hh:mm a 'on' dd/MM/yyyy"];
        NSString *dtString = [formatter stringFromDate:_post.releaseDate];
        _post.content = [NSString stringWithFormat:@"Released at %@.", dtString];
    }
    
    if (_post.topic != nil)
        [_imgViewLandmarkCategory setImage:[UIImage imageNamed:[NSString stringWithFormat:@"topicCategory%@.png",_post.topic]]];
    
    UIView *sview = [[UIView alloc] initWithFrame:_lblUsername.frame];
    [sview addGestureRecognizer:_tapGestureRecognizer];
    [self.viewCoverStrip addSubview:sview];
    
    //initialize comments box
    UIImage *image = [[UIImage imageNamed:@"viewPostCommentFrame.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(70,5,30,5)];
    [_imgViewCommentFrame setImage:image];
    
    [self getPostImageFromInternet];
    [self asynchGetCommentsRequest];
    
    //prepare follow and friend button
    [_btnFollow setHidden:YES];
    _btnFriendsWith.enabled = NO;
    if (_loggedInUser.userID != _postOwner.userID) {
        [_loggedInUser getUserFollowRelationAsync:_postOwner completionHandler:^(BOOL isFollowing, int followID, NSString* errorMsg) {
            if (errorMsg == nil) {
                if (!isFollowing)
                    [_btnFollow setEnabled:YES];
            }else
                postNotification(errorMsg);
        }];
    }
    
    //prepare comment button for drag
    _didStartDraggingCommentBox = NO;
    [_btnComment addTarget:self action:@selector(imageTouch:withEvent:) forControlEvents:UIControlEventTouchDown];
    UIPanGestureRecognizer *rec = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [rec setMaximumNumberOfTouches:2];
    [self.view addGestureRecognizer:rec];
    
    //display loading animation
    _activityIndicatorView = [[UIActivityIndicatorView alloc] init];
    [_scrollViewImage addSubview:_activityIndicatorView];
    _activityIndicatorView.frame = CGRectMake(0,0,_scrollViewImage.frame.size.width,_scrollViewImage.frame.size.height);
    [_activityIndicatorView startAnimating];
    
    //remove delete button if not correct user
    if (_postOwner.userID != _loggedInUser.userID) {
        [_btnDelete setHidden:YES];
    } else {
        [_btnWhistle setHidden:YES];
    }
}

- (void) setupDescriptionMarker:(UIView*) markView {
    CGRect tableFrame = [_tblViewPostDiscussion rectForRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    //CGRect tableFrame = [_tblViewPostDiscussion convertRect:tableFrame1]
    //CGRect tableFrame = cell.frame;
    _descriptionMarker = [[UIImageView alloc] initWithFrame:CGRectMake(tableFrame.origin.x - 12, tableFrame.origin.y, 10, 20)];
    [_descriptionMarker setImage:[UIImage imageNamed:@"viewPostDescriptionMarker.png"]];
    [self.view addSubview:_descriptionMarker];
}

- (IBAction) imageTouchUp:(id) sender withEvent:(UIEvent *) event {
    
}
- (IBAction) imageTouch:(id) sender withEvent:(UIEvent *) event {
    _didStartDraggingCommentBox = YES;
}
- (void) handlePan: (UIPanGestureRecognizer*) rec {
    if (_didStartDraggingCommentBox) {
        if ([rec state] == UIGestureRecognizerStateEnded) {
            _didStartDraggingCommentBox = NO;
            if (abs(_commentsBoxMovedBy) < 40) {
                [self commentButtonTouchUpInside:nil];
            }
        }
        if ([rec state] == UIGestureRecognizerStateBegan || [rec state] == UIGestureRecognizerStateChanged) {
            CGPoint cur = [rec locationInView:self.view];
            //CGPoint translation = [rec translationInView:self.view];
            if (cur.y <= _originalCommentBoxPosition) {
                _didMoveCommentsBox = YES;
                CGFloat movedBy = cur.y - [_btnComment center].y;
                _commentsBoxMovedBy -= movedBy;
                [_btnComment setCenter:CGPointMake([_btnComment center].x, cur.y)];
                CGRect frame2 = _imgViewCommentFrame.frame;
                CGRect frame3 = _tblViewPostDiscussion.frame;
                frame2.size.height = (frame2.size.height - movedBy);
                frame3.size.height = (frame3.size.height - movedBy);
                frame2.origin.y += movedBy;
                frame3.origin.y += movedBy;
                
                _imgViewCommentFrame.frame = frame2;
                _tblViewPostDiscussion.frame = frame3;
            }
        }
    }
}
#pragma mark - code to move views up/down appropriately when keyboard is going to cover text field

- (void)viewWillAppear:(BOOL)animated
{
    [self resetUIViewsState];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    //prepare comment button for drag
    //[self setupDescriptionMarker:nil];
    
    _originalCommentBoxPosition = [_btnComment center].y;
    [super viewDidAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [AppDelegate cleanupMemory];
    // Dispose of any resources that can be recreated.
}

#pragma mark - tap gesture handler
-(void) handleTap:(UITapGestureRecognizer *)tapGestureRecognizer {
    RCUserProfileViewController *userProfileView = [[RCUserProfileViewController alloc] initWithUser:_postOwner viewingUser:_loggedInUser];
    [self.navigationController pushViewController:userProfileView animated:YES];
}

#pragma mark - web request
-(void) getPostImageFromInternet {
    RCResourceCache *cache = [RCResourceCache centralCache];
    NSString *key = [NSString stringWithFormat:@"%@/%@", RCMediaResource, _post.fileUrl];
    
    dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
    dispatch_async(queue, ^{
        NSObject* cachedObj = [cache getResourceForKey:key usingQuery:^{
            [RCConnectionManager startConnection];
            NSObject *object = [RCAmazonS3Helper getUserMediaImage:_postOwner withLoggedinUserID:[RCUser currentUser].userID   withImageUrl:_post.fileUrl];
            [RCConnectionManager endConnection];
            return object;
        }];
        UIImage *thumbnailImage;
        //if returned object is a string, this means the post is a movie
        if (![cachedObj isKindOfClass:[UIImage class]]) {
            NSString *thumbnailKey = [NSString stringWithFormat:@"%@/%@", RCMediaResource, _post.thumbnailUrl];
            thumbnailImage = [cache getResourceForKey:thumbnailKey usingQuery:^{
                [RCConnectionManager startConnection];
                NSObject *object = [RCAmazonS3Helper getUserMediaImage:_postOwner withLoggedinUserID:[RCUser currentUser].userID   withImageUrl:_post.thumbnailUrl];
                [RCConnectionManager endConnection];
                return object;
            }];

        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (cachedObj != nil && [cachedObj isKindOfClass:[UIImage class]]) {
                _postImage = (UIImage *)cachedObj;
                [self setupImageScrollView];
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
                [self.view bringSubviewToFront:_btnComment];
                [self.view bringSubviewToFront:_imgViewCommentFrame];
                [self.view bringSubviewToFront:_tblViewPostDiscussion];
                [self.view bringSubviewToFront:_tblViewPostDiscussion];
                [self.view bringSubviewToFront:_btnPostComment];
            }
        });
    });

}

- (void) setupImageScrollView {
    [_activityIndicatorView removeFromSuperview];
    [_activityIndicatorView stopAnimating];
    UIImage *image = _postImage;
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

#pragma mark - UIScrollViewDelegate
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
- (IBAction)deletePost:(id)sender {
    showConfirmationDialog(@"Are you sure you want to delete this post?", @"Confirmation", self);
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1){
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
    TTTAttributedLabel *textLabel = [[TTTAttributedLabel alloc] initWithFrame:cell.textLabel.frame];
    
    textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    textLabel.numberOfLines = 0;
    textLabel.font = [UIFont fontWithName:@"Helvetica" size:17.0];
    if (idx == 0) {
        if ([textLabel respondsToSelector:@selector(setAttributedText:)])
            [textLabel setAttributedText:[self generateAttributedStringForUser:_post.authorName forComment:_post.content withDate:nil]];
        else
            [textLabel setText:[NSString stringWithFormat:@"%@: %@",_post.authorName,_post.content]];
        textLabel.activeLinkAttributes = textLabel.linkAttributes = [textLabel.attributedText attributesAtIndex:0 effectiveRange:nil];
        [textLabel addLinkToURL:[NSURL URLWithString:[NSString stringWithFormat:@"memcap:/%@/%d?user[name]=%@",RCUsersResource, _post.userID, urlEncodeValue(_post.authorName)]] withRange:NSMakeRange(0,[_post.authorName length])];
    } else {
        RCComment *comment = [_comments objectAtIndex:(idx-1)];
        if ([textLabel respondsToSelector:@selector(setAttributedText:)])
            [textLabel setAttributedText:[self generateAttributedStringForUser:comment.authorName forComment:comment.content withDate:comment.createdTime]];
        else
            [textLabel setText:[NSString stringWithFormat:@"%@: %@",comment.authorName,comment.content]];
        textLabel.activeLinkAttributes = textLabel.linkAttributes = [textLabel.attributedText attributesAtIndex:0 effectiveRange:nil];
        [textLabel addLinkToURL:[NSURL URLWithString:[NSString stringWithFormat:@"memcap:/%@/%d?user[name]=%@",RCUsersResource, comment.userID, urlEncodeValue(comment.authorName)]] withRange:NSMakeRange(0,[comment.authorName length])];
    }
    [cell addSubview:textLabel];
    CGSize size = [textLabel sizeThatFits:CGSizeMake(_tblViewPostDiscussion.frame.size.width, MAXFLOAT)];
    textLabel.frame = CGRectMake(0,0,size.width,size.height);
    textLabel.delegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    return cell;
}
    
- (NSMutableAttributedString *) generateAttributedStringForUser:(NSString*)userName forComment:(NSString*)comment withDate:(NSDate*)timeStamp {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone systemTimeZone]];
    [formatter setDateFormat:@"dd/M/yyyy hh:mm a"];
    NSString* dateString = [formatter stringFromDate:timeStamp];
    NSString *textContent;
    if (timeStamp != nil)
        textContent = [NSString stringWithFormat:@"%@ %@\n%@",userName, comment, dateString];
    else 
        textContent = [NSString stringWithFormat:@"%@ %@",userName, comment];
    
    UIFont *boldFont = [UIFont fontWithName:@"Helvetica-Bold" size:17.0];
    UIFont *regularFont = [UIFont fontWithName:@"Helvetica" size:17.0];
    UIColor *foregroundColor = [UIColor blackColor];
    if (timeStamp == nil) {
        foregroundColor = [UIColor colorWithRed:(0.0/255.0) green:0.0 blue:255.0 alpha:1.0];
        //boldFont = [UIFont fontWithName:@"Optima-Bold" size:17.0];
        //regularFont = [UIFont fontWithName:@"Optima-Italic" size:17.0];
    }
    
    // Create the attributes
    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           regularFont, NSFontAttributeName, nil];
    NSDictionary *subAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                              boldFont, NSFontAttributeName,
                              foregroundColor, NSForegroundColorAttributeName, nil];
    
    NSRange nameRange = NSMakeRange(0,[userName length]);
    
    // Create the attributed string (text + attributes)
    NSMutableAttributedString *attributedText =
    [[NSMutableAttributedString alloc] initWithString:textContent
                                           attributes:attrs];
    [attributedText setAttributes:subAttrs range:nameRange];
    
    if (timeStamp != nil) {
        UIFont *timestampFont = [UIFont fontWithName:@"Helvetica" size:15.0];
        UIColor *timestampColor = [UIColor grayColor];
        NSDictionary *timestampAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                        timestampFont, NSFontAttributeName,
                                        timestampColor, NSForegroundColorAttributeName, nil];
        NSRange timestampRange = NSMakeRange([textContent length] - [dateString length], [dateString length]);
        [attributedText setAttributes:timestampAttrs range:timestampRange];
    }
    return attributedText;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    int idx = indexPath.row;
    NSAttributedString *attributedText;
    if (idx == 0) {
        attributedText = [self generateAttributedStringForUser:_post.authorName forComment:_post.content withDate:nil];
    } else {
        RCComment *comment = [_comments objectAtIndex:(idx-1)];
        attributedText = [self generateAttributedStringForUser:comment.authorName forComment:comment.content withDate:comment.createdTime];
    }
    TTTAttributedLabel *lbl = [[TTTAttributedLabel alloc] init];
    lbl.lineBreakMode = NSLineBreakByWordWrapping;
    lbl.numberOfLines = 0;
    [lbl setAttributedText:attributedText];
    CGSize size =[lbl sizeThatFits:CGSizeMake(_tblViewPostDiscussion.frame.size.width,MAXFLOAT)];
    return size.height + 20.0;

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
        NSData *postData = [dataSt dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
        
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@", RCServiceURL, RCCommentsResource]];
        
        NSURLRequest *request = CreateHttpPostRequest(url, postData);
        [RCConnectionManager startConnection];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             bool _successfulPost;
             NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
             int responseStatusCode = [httpResponse statusCode];
             [RCConnectionManager endConnection];
             if (responseStatusCode != RCHttpOkStatusCode) {
                 _successfulPost = NO;
             } else _successfulPost = YES;
             
             NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
             NSLog(@"%@",responseData);
             
             //Temporary:
             if (_successfulPost) {
                 SBJsonParser *jsonParser = [[SBJsonParser alloc] init];
                 NSDictionary* commentJson = (NSDictionary*) [jsonParser objectWithString:responseData error:nil];
                 _currentCommentID = [[commentJson objectForKey:@"id"] intValue];
                [self asynchGetCommentsRequest];
             }else {
                 postNotification([NSString stringWithFormat:@"Please try again! %@", responseData]);
             }
         }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        postNotification(@"Post Failed.");
    }
}

- (void) asynchGetCommentsRequest {
    //Asynchronous Request
    @try {
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d/comments?mobile=1", RCServiceURL, RCPostsResource, _post.postID]];
        NSURLRequest *request = CreateHttpGetRequest(url);
        [RCConnectionManager startConnection];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             [RCConnectionManager endConnection];
             [_comments removeAllObjects];
             NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
             SBJsonParser *jsonParser = [[SBJsonParser alloc] init];
             NSArray* commentsJson = (NSArray*) [jsonParser objectWithString:responseString error:nil];
             NSIndexPath* scrollIndexPath = nil;
             for (NSDictionary *commentHash in commentsJson) {
                 RCComment *comment = [[RCComment alloc] initWithNSDictionary:commentHash];
                 [_comments addObject:comment];
                 if (comment.commentID == _currentCommentID) {
                     scrollIndexPath = [NSIndexPath indexPathForRow:([_comments count]) inSection:0];
                     _currentCommentID = -1;
                 }
             }
             [_tblViewPostDiscussion reloadData];
             if (scrollIndexPath != nil)
                 [_tblViewPostDiscussion scrollToRowAtIndexPath:scrollIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
             
         }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        postNotification(@"Failure getting friends from web service");
    }
}

- (void) asynchDeletePost {
    //Asynchronous Request
    @try {
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d?mobile=1", RCServiceURL, RCPostsResource, _post.postID]];
        NSURLRequest *request = CreateHttpDeleteRequest(url);
        [RCConnectionManager startConnection];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             [RCConnectionManager endConnection];
             NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
             NSLog(@"Post deletion status string: %@", responseData);
             
             if ([responseData isEqualToString:@"ok"]){
                 postNotification(@"Post deleted successfully!");
                 [self.navigationController popViewControllerAnimated:YES];
                 if (_deleteFunction != nil)
                     _deleteFunction();
             }else if ([responseData isEqualToString:@"error"]){
                 postNotification(@"Please try again!");
             }
             
              /*SBJsonParser *jsonParser = [SBJsonParser new];
              NSDictionary *jsonData = (NSDictionary *) [jsonParser objectWithString:responseData error:nil];
              NSLog(@"Post deleted: %@",jsonData);*/
             
         }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        postNotification(@"Failure deleting post.");
    }

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
    //[self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popViewControllerAnimated:YES];

}

- (IBAction)commentButtonTouchUpInside:(id)sender {
    _didStartDraggingCommentBox = NO;
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
- (void) resetUIViewsState {
    _didMoveCommentsBox = NO;
    _commentsBoxMovedBy = 0;
    _didStartDraggingCommentBox = NO;
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
        NSString *key = [NSString stringWithFormat:@"%@/%@", RCMediaResource, _post.fileUrl];
        dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
        dispatch_async(queue, ^{
            [cache invalidateKey:key];
            _videoUrl = (NSURL*) [cache getResourceForKey:key usingQuery:^{
                [RCConnectionManager startConnection];
                NSObject *object = [RCAmazonS3Helper getUserMediaImage:_postOwner withLoggedinUserID:[RCUser currentUser].userID   withImageUrl:_post.fileUrl];
                [RCConnectionManager endConnection];
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

- (IBAction)btnFriendsWithTouchUpInside:(id)sender {
    [RCUser addFriendAsCurrentUserAsync:_postOwner completionHandler:^(int friendID, NSString *errorMsg) {
        if (errorMsg == nil) {
            [_btnFriendsWith setEnabled:NO];
        }else
            postNotification(errorMsg);
    }];
}

- (IBAction)btnFollowTouchUpInside:(id)sender {
    [RCUser followUserAsCurrentUserAsync:_postOwner completionHandler:^(int followID, NSString *errorMsg) {
        if (errorMsg == nil) {
            [_btnFollow setEnabled:NO];
        }else
            postNotification(errorMsg);
    }];
}

- (IBAction)btnWhistleTouchUpInside:(id)sender {
    if ([_viewReport isHidden]) {
        [_viewReport setHidden:NO];
    } else {
        [_viewReport setHidden:YES];
    }
}
- (IBAction)btnReportInappropriateTouchUpInside:(id)sender {
    _currentReportChoice = 0;
    [_lblReportInappropriate setBackgroundColor:[UIColor colorWithRed:81.0/255.0 green:18.0/255.0 blue:36.0/255.0 alpha:1.0]];
    [_lblReportCopyrightContent setBackgroundColor:[UIColor clearColor]];
}

- (IBAction)btnReportSubmitTouchUpInside:(id)sender {
    NSString* category = _currentReportChoice == 0 ? @"Inappropriate" : @"Copyright content";
    //post to website the report here
    [_viewReport setHidden:YES];
    [RCConnectionManager startConnection];
    [RCPostReport postReportCategory:category withReason:@"automatic flag by user from ios app" forPost:_post withSuccessHandler:^ {
        [RCConnectionManager endConnection];
        [_btnWhistle setHidden:YES];
    } withFailureHandler:^(NSString *errorMessage) {
        [RCConnectionManager endConnection];
        showAlertDialog(([NSString stringWithFormat:@"Could not post report because %@. %@", errorMessage, RCErrorMessagePleaseTryAgain]), @"Error");
    }];
    
}

- (IBAction)btnReportCopyrightContentTouchUpInside:(id)sender {
    _currentReportChoice = 1;
    [_lblReportCopyrightContent setBackgroundColor:[UIColor colorWithRed:81.0/255.0 green:18.0/255.0 blue:36.0/255.0 alpha:1.0]];
    [_lblReportInappropriate setBackgroundColor:[UIColor clearColor]];
}
@end
