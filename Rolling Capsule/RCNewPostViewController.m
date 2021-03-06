//
//  RCNewPostViewController.m
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 3/6/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCUtilities.h"
#import "RCConstants.h"
#import "AppDelegate.h"
#import "RCAmazonS3Helper.h"
#import "RCNewPostViewController.h"
#import "RCKeyboardPushUpHandler.h"
#import "RCConnectionManager.h"
#import "RCLandmarkCell.h"
#import "RCOperationsManager.h"
#import "RCMediaUploadOperation.h"
#import "RCNewPostOperation.h"
#import "RCFacebookHelper.h"
#import "RCFacebookSettingsViewController.h"
#import "RCFriendListViewController.h"
#import "RCUserTableCell.h"
#import <QuartzCore/QuartzCore.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import "SBJson.h"

@interface RCNewPostViewController ()

@property (nonatomic,strong) UIImage* postImage;
@property (nonatomic,strong) NSString* postContent;
@property (nonatomic,strong) NSString* imageFileName;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, strong) NSString* privacyOption;
@property (nonatomic, strong) UIView *viewTopic;
@property (nonatomic, strong) NSURL *videoUrl;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) RCDatePickerView* datePickerView;
@property (nonatomic, strong) NSString* currentTopic;
@property (nonatomic, assign) BOOL viewFirstLoad;
@property (nonatomic, strong) RCMediaUploadOperation *mediaUploadOp;
@property (nonatomic, strong) RCNewPostOperation *postNewOp;
@property (nonatomic, strong) RCPost *post;
@property (nonatomic, strong) UIImagePickerController *imagePicker;
@property (nonatomic, strong) RCFriendListViewController *friendListPickerViewController;
@property (nonatomic, strong) RCUser* timeCapsuleReceiver;
@end

@implementation RCNewPostViewController {
    NSData *_uploadData;
    NSData *_thumbnailData;
    BOOL _isTimedRelease;
}

@synthesize imagePicker = _imagePicker;
@synthesize postImage = _postImage;
@synthesize videoUrl = _videoUrl;
@synthesize postContent = _postContent;
@synthesize imageFileName = _imageFileName;
@synthesize user = _user;
@synthesize keyboardPushHandler = _keyboardPushHandler;
@synthesize topics = _topics;
@synthesize tblViewLandmark = _collectionViewTopic;
@synthesize currentLandmark = _currentLandmark;
@synthesize postButton = _postButton;
@synthesize publicPrivacyButton = _publicPrivacyButton;
@synthesize friendPrivacyButton = _friendPrivacyButton;
@synthesize personalPrivacyButton = _personalPrivacyButton;
@synthesize privacyOption = _privacyOption;
@synthesize viewTopic = _viewTopic;
@synthesize viewFirstLoad = _viewFirstLoad;
@synthesize activityIndicator = _activityIndicator;
@synthesize currentTopic = _currentTopic;
@synthesize mediaUploadOp = _mediaUploadOp;
@synthesize postNewOp = _postNewOp;
@synthesize post = _post;
@synthesize friendListPickerViewController = _friendListPickerViewController;
@synthesize timeCapsuleReceiver = _timeCapsuleReceiver;

BOOL _isTapToCloseKeyboard = NO;
BOOL _landmarkTableVisible = NO;
BOOL _successfulPost = NO;
BOOL _firstTimeEditPost = YES;
BOOL _didFinishUploadingImage = NO;
BOOL _isMovie = NO;
BOOL _isPosting = NO;

BOOL _isShowingPrivacyOption = NO;
BOOL _isFacebookPost = NO;
static BOOL RCNewPostViewControllerAutomaticClose = YES;

+ (void) toggleAutomaticClose {    
    if (RCNewPostViewControllerAutomaticClose)
        RCNewPostViewControllerAutomaticClose = NO;
    else
        RCNewPostViewControllerAutomaticClose = YES;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)callLandmarkTable:(id)sender {
    if (_landmarkTableVisible) {
        _landmarkTableVisible = NO;
        [_viewTopic removeFromSuperview];
    } else {
        //[self asynchGetLandmarkRequest];
        if (_topics == nil || [_topics count] == 0) {
            _topics = [[NSMutableArray alloc] init];
            for (int i = 0; i < NUM_TOPICS; i++)
                [_topics addObject:[NSString stringWithUTF8String:RCTopics[i]]];
            [_collectionViewTopic reloadData];
        }
        [self.view addSubview:_viewTopic];
        _landmarkTableVisible = YES;
    }
}
- (id) initWithUser:(RCUser *)user withNibName:(NSString *)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _user = user;
        _keyboardPushHandler = [[RCKeyboardPushUpHandler alloc] init];
    }
    return self;
}

- (id) initWithUser:(RCUser *)user {
    self = [super init];
    if (self) {
        _user = user;
        _keyboardPushHandler = [[RCKeyboardPushUpHandler alloc] init];
    }
    return self;
}

- (id) initWithUser:(RCUser *)user withBackgroundImage:(UIImage*) image{
    self = [super init];
    if (self) {
        _user = user;
        _keyboardPushHandler = [[RCKeyboardPushUpHandler alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //initialize tap gesture that would be used either by background image or by
    //the whole view to handle keyboard pushing up/down
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    //[self.view addGestureRecognizer:_tapGestureRecognizer];
    _isTapToCloseKeyboard = NO;
    
    //prepare text view placeholder
    _firstTimeEditPost = YES;
    
    //indicate when view was loaded to move down screen
    _viewFirstLoad = YES;
    //reset data type
    _isMovie = NO;
    _isTimedRelease = NO;
    
    //init landmark button within
    /*UIButton *paddingView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    [paddingView setImage:[UIImage imageNamed:@"landmarkEmpty.png"] forState:UIControlStateNormal];
    [paddingView addTarget:self action:@selector(openLandmarkView:) forControlEvents:UIControlEventTouchUpInside];
    _txtFieldPostSubject.leftView = paddingView;
    _txtFieldPostSubject.leftViewMode = UITextFieldViewModeAlways;*/
    
    //prepare landmark view
    _viewTopic = [[UIView alloc] initWithFrame:CGRectMake(10, 90, 300, 160)];
    UIImageView *landmarkBackground = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 300, 160)];
    [landmarkBackground setImage:[UIImage imageNamed:@"postLandmarkBackground.png"]];
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    _collectionViewTopic = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, 280, 160) collectionViewLayout:flowLayout];
    [_viewTopic addSubview:landmarkBackground];
    landmarkBackground.frame = CGRectMake(0,0,_viewTopic.frame.size.width, _viewTopic.frame.size.height);
    [_viewTopic addSubview:_collectionViewTopic];
    _collectionViewTopic.frame = CGRectMake(10,0,280,160);
    [_collectionViewTopic setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0]];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    _collectionViewTopic.allowsSelection = YES;
    _collectionViewTopic.delegate = self;
    _collectionViewTopic.dataSource = self;
    NSString* cellIdentifier = [RCLandmarkCell cellIdentifier];
    [_collectionViewTopic registerClass:[RCLandmarkCell class] forCellWithReuseIdentifier:cellIdentifier];
    UINib *nib = [UINib nibWithNibName:cellIdentifier bundle: nil];
    [_collectionViewTopic registerNib:nib forCellWithReuseIdentifier:cellIdentifier];
    
    _topics = [[NSMutableArray alloc] init];
    _landmarkTableVisible = NO;
    _currentLandmark = nil;
    
    //init activity indicator
    _activityIndicator = nil;
    
    //the view upload image in background and remember the status of the upload (fail, successful etc.)
    //this method helps reset the status to initial state (have not uploaded)
    [self resetUploadStatus];
    _uploadData = nil;
    
    //initialize label and text
    //initalize name text
    _lblLandmarkName.text = _user.name;
    //
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd/M/yyyy"];
    _lblDate.text = [formatter  stringFromDate:[NSDate date]];
    
    //initialize text field with user name as speaker
    
    [_imgViewPrivacyOptionFrame setHidden:YES];
    //[_txtViewPostContent setText:_user.name];
}

- (void) resetUploadStatus {
    _didFinishUploadingImage = NO;
    _isPosting = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [AppDelegate cleanupMemory];
    // Dispose of any resources that can be recreated.
}

- (IBAction) postNew:(id) sender {
    if (_isTimedRelease && _isFacebookPost) {
        showAlertDialog(NSLocalizedString(@"The post cannot be both time capsule and facebook release yet!",nil), NSLocalizedString(@"Error",nil));
        return;
    }
    
    _isPosting = YES;
    if (_uploadData == nil) {
        [self showAlertMessage:NSLocalizedString(@"Please choose an image or video!", nil) withTitle:NSLocalizedString(@"Incomplete post!",nil)];
        return;
    }
    if (_privacyOption == nil) {
        [self showAlertMessage:NSLocalizedString(@"Please choose a privacy option!", nil) withTitle:NSLocalizedString(@"Incomplete post!",nil)];
        return;
    }
    _postButton.enabled = NO;
    _post = [[RCPost alloc] init];
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    _post.latitude = appDelegate.currentLocation.coordinate.latitude;
    _post.longitude = appDelegate.currentLocation.coordinate.longitude;
    _post.subject = [_txtFieldPostSubject.text copy];
    _post.content = [_txtViewPostContent.text substringFromIndex:[_user.name length]+1];
    _post.fileUrl = [_imageFileName copy];
    _post.thumbnailUrl = [NSString stringWithFormat:@"%@-thumbnail", _imageFileName];
    _post.privacyOption = [_privacyOption copy];
    _post.topic = [_currentTopic copy];
    _post.postedTime = [NSDate date];
    if (_datePickerView != nil && _isTimedRelease) {
        _post.releaseDate = [_datePickerView date];
        _post.timeCapsuleReceiver = _timeCapsuleReceiver;
    }

    [RCOperationsManager addUploadOperation:_mediaUploadOp withPost:_post];
    _mediaUploadOp = nil;
    
    if (RCNewPostViewControllerAutomaticClose)
//        [self dismissViewControllerAnimated:YES completion:^{
//            NSLog(@"successfully dismissed new post view controller");
//        }];
        [self.navigationController popViewControllerAnimated:YES];
    
    if (_isFacebookPost) {
        NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
        [params setObject:_post.subject forKey:@"message"];
        [params setObject:UIImagePNGRepresentation(_postImage) forKey:@"picture"];
        
        NSString *privacyStr;
        if ([_privacyOption isEqualToString:@"public"])
            privacyStr = @"{'value':'EVERYONE'}";
        else if ([_privacyOption isEqualToString:@"friends"])
            privacyStr = @"{'value':'ALL_FRIENDS'}";
        else if ([_privacyOption isEqualToString:@"personal"])
            privacyStr = @"{'value':'SELF'}";
        
        [params setObject:privacyStr forKey:@"privacy"];
        
        [FBRequestConnection startWithGraphPath:@"me/photos"
                                     parameters:params
                                     HTTPMethod:@"POST"
                              completionHandler:^(FBRequestConnection *connection,
                                                  id result,
                                                  NSError *error)
         {
             if (error)
             {
                 //showing an alert for failure
                 postNotification(NSLocalizedString(@"Failed to post to Facebook",nil));
             }
             else
             {
                 //showing an alert for success
                 postNotification(NSLocalizedString(@"Successfully posted to Facebook",nil));
             }
         }];
        
//        [FBRequestConnection startForUploadPhoto:_postImage
//           completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
//               //[self showAlert:@"Photo Post" result:result error:error];
//               
//               NSString *msg;
//               if (error) {
//                   msg = @"Error";
//                   // For simplicity, we will use any error message provided by the SDK,
//                   // but you may consider inspecting the fberrorShouldNotifyUser or
//                   // fberrorCategory to provide better recourse to users. See the Scrumptious
//                   // sample for more examples on error handling.
//                   if (error.fberrorUserMessage) {
//                       msg = error.fberrorUserMessage;
//                   } else {
//                       msg = @"Operation failed due to a connection problem, retry later.";
//                   }
//               } else {
//                   NSDictionary *resultDict = (NSDictionary *)result;
//                   msg = @"Successfully posted: ";
//                   NSString *postId = [resultDict valueForKey:@"id"];
//                   if (!postId) {
//                       postId = [resultDict valueForKey:@"postId"];
//                   }
//                   if (postId) {
//                       msg = [NSString stringWithFormat:@"%@\nPost ID: %@", msg, postId];
//                   }
//               }
//               msg = @"Successfully posted to Facebook"; //Nevermind, post this instead of graph post ID
//               postNotification(msg);
//           }];
    }
}

#pragma mark - helper methods

- (void)showAlertMessage:(NSString *)message withTitle:(NSString *)title
{
    UIAlertView *alertView = [[UIAlertView alloc]  initWithTitle:title
                                                         message:message
                                                        delegate:nil
                                               cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                               otherButtonTitles:nil];
    [alertView show];
}

#pragma mark - UI events

- (IBAction)backgroundTouchUpInside:(id)sender {
    if ([_txtFieldPostSubject isEditing])
        [_txtFieldPostSubject resignFirstResponder];
    else
        [_txtViewPostContent resignFirstResponder];
}

- (IBAction) openLandmarkView:(id) sender {
    //[self.view removeGestureRecognizer:_tapGestureRecognizer];
    [self callLandmarkTable:sender];
}
#pragma mark - UIScrollViewDelegate
- (void) setupImageScrollView {
    UIImage *image = _postImage;
    _scrollViewImage.delegate = self;
    _imageViewPostPicture = [[UIImageView alloc] initWithImage:image];
    CGSize size = _imageViewPostPicture.frame.size;
    _scrollViewImage.contentSize = size;
    [_scrollViewImage addSubview:_imageViewPostPicture];
    _scrollViewImage.minimumZoomScale = MIN(1.0,_scrollViewImage.frame.size.height/image.size.height);
    _scrollViewImage.zoomScale = _scrollViewImage.frame.size.height/image.size.height;
    if (abs(_scrollViewImage.zoomScale - 1.0) < 1e-9) {
        [self scrollViewDidZoom:_scrollViewImage];
    }
    [_activityIndicator stopAnimating];
}
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageViewPostPicture;
}
- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    UIView *subView = _imageViewPostPicture;
    
    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width)?
    (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
    
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height)?
    (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    
    subView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX,
                                 scrollView.contentSize.height * 0.5 + offsetY);
}

#pragma mark - UIImagePickerControllerDelegate methods

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    if (_activityIndicator == nil)
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:_scrollViewImage.frame];
    [self.view addSubview:_activityIndicator];
    [_activityIndicator startAnimating];
    _videoUrl = nil;
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self removePhotoSourceControlAndAddPrivacyControl];
    dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
    dispatch_async(queue, ^{
        NSLog(@"background processing before data upload");
        //check if media is a video
        NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
        _isMovie = CFStringCompare ((__bridge CFStringRef) mediaType, kUTTypeMovie, 0)
        == kCFCompareEqualTo;
        
        NSLog(@"creating media upload operation");
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        CFStringRef string = CFUUIDCreateString(NULL, theUUID);
        CFRelease(theUUID);
        _imageFileName = [(__bridge NSString*)string stringByReplacingOccurrencesOfString:@"-"withString:@""];
        if (_mediaUploadOp != nil) {
            [_mediaUploadOp cancel];
        }
        if (_isMovie) {
            _imageFileName = [NSString stringWithFormat:@"%@.mov",_imageFileName];
        }
        RCMediaUploadOperation *localMediaUploadOp = [[RCMediaUploadOperation alloc] initWithKey:_imageFileName withMediaType:_isMovie ? @"movie/mov" :  @"image/jpeg" withURL:nil];
        _mediaUploadOp = localMediaUploadOp;
        if (_isMovie)
        {
            _videoUrl =(NSURL*)[info objectForKey:UIImagePickerControllerMediaURL];
            if ([picker sourceType] == UIImagePickerControllerSourceTypeCamera) {
                ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                // Request to save the video to camera roll
                [library writeVideoAtPathToSavedPhotosAlbum:_videoUrl completionBlock:^(NSURL *assetURL, NSError *error){
                    if (error) {
                        NSLog(@"error");
                    } else {
                        NSLog(@"url %@", assetURL);
                        localMediaUploadOp.fileURL = assetURL;
                    }
                }];
            } else {
                if ([RCOperationsManager defaultUploadManager].willWriteToCoreData) {
                    NSURL *url = [info objectForKey:UIImagePickerControllerReferenceURL];
                    localMediaUploadOp.fileURL = [NSURL URLWithString:[url absoluteString]];
                }
            }
            _postImage = generateVideoThumbnail(_videoUrl);
            _uploadData = [NSData dataWithContentsOfURL:_videoUrl];
            NSLog(@"obtained upload data");
        } else {
            //save photo if newly taken
            _postImage = [info objectForKey:UIImagePickerControllerOriginalImage];
            if ([picker sourceType] == UIImagePickerControllerSourceTypeCamera) {
                ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                // Request to save the image to camera roll
                [library writeImageToSavedPhotosAlbum:[_postImage CGImage] orientation:(ALAssetOrientation)[_postImage imageOrientation] completionBlock:^(NSURL *assetURL, NSError *error){
                    if (error) {
                        NSLog(@"error");
                    } else {
                        localMediaUploadOp.fileURL = assetURL;
                    }  
                }];
            } else {
                if ([RCOperationsManager defaultUploadManager].willWriteToCoreData) {
                    NSURL *url = [info objectForKey:UIImagePickerControllerReferenceURL];
                    localMediaUploadOp.fileURL = [NSURL URLWithString:[url absoluteString]];
                }
            }
            NSLog(@"image size %f %f",_postImage.size.width, _postImage.size.height);
            _postImage = resizeImageIfTooBig(_postImage);
            _uploadData = UIImageJPEGRepresentation(_postImage, 1.0);
            
            NSLog(@"number of bytes %d",[_uploadData length]);
            
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setupImageScrollView];
        });
        
        UIImage *thumbnail;
        UIImage *rescaledThumbnail;
        if (_isMovie)
        {
            thumbnail = [info objectForKey:UIImagePickerControllerEditedImage];
            if (thumbnail == nil)
                thumbnail = generateSquareImageThumbnail(_postImage);
            rescaledThumbnail = imageWithImage(thumbnail, CGSizeMake(RCUploadImageSizeWidth,RCUploadImageSizeHeight));
        } else {
            // Get the selected image
            thumbnail = generateSquareImageThumbnail(_postImage);
            //generate thumbnail
            rescaledThumbnail =imageWithImage(thumbnail, CGSizeMake(RCUploadImageSizeWidth,RCUploadImageSizeHeight));
        }
        
        localMediaUploadOp.uploadData = _uploadData;
        localMediaUploadOp.thumbnailImage = rescaledThumbnail;
        [RCOperationsManager addUploadMediaOperation:localMediaUploadOp];
    });
}

-(void) imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - code to move views up/down appropriately when keyboard is going to cover text field
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
- (void)viewWillAppear:(BOOL)animated
{
    [_txtFieldPostSubject becomeFirstResponder];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    if (_viewFirstLoad) {
        _viewFirstLoad = NO;
        _txtViewPostContent.contentInset = UIEdgeInsetsMake(-8,0,0,0);
        CGFloat fontSize = 17.0;
        if ([[UIScreen mainScreen] bounds].size.height < RCIphone5Height) fontSize = 15.0;
        NSString *textContent = [NSString stringWithFormat:@"%@ ",_user.name];
        UIFont *boldFont = [UIFont fontWithName:@"Helvetica-Bold" size:fontSize];
        UIFont *regularFont = [UIFont fontWithName:@"Helvetica" size:fontSize];
        UIColor *foregroundColor = [UIColor whiteColor];
        
        // Create the attributes
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                               regularFont, NSFontAttributeName, foregroundColor, NSForegroundColorAttributeName,nil];
        NSDictionary *subAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                  boldFont, NSFontAttributeName,
                                  foregroundColor, NSForegroundColorAttributeName, nil];
        NSRange range = NSMakeRange(0,[_user.name length]);
        // Create the attributed string (text + attributes)
        NSMutableAttributedString *attributedText =
        [[NSMutableAttributedString alloc] initWithString:textContent
                                               attributes:attrs];
        [attributedText setAttributes:subAttrs range:range];
        
        [_txtViewPostContent setAttributedText:attributedText];
    }
    
    if ([[UIScreen mainScreen] bounds].size.height < RCIphone5Height) {
        [[NSNotificationCenter defaultCenter] addObserver:_keyboardPushHandler
                                                 selector:@selector(keyboardWillShow:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:_keyboardPushHandler
                                                 selector:@selector(keyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
    }
    
    
    NSLog(@"screen size: %d",[[UIScreen mainScreen] bounds].size.height );
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    
    [[NSNotificationCenter defaultCenter] removeObserver:_keyboardPushHandler
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:_keyboardPushHandler
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [super viewWillDisappear:animated];
}

#pragma mark - animate in the view
/*- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    
}*/



#pragma mark - UI actions

- (IBAction)btnActionChooseCameraSource:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        _imagePicker = [[UIImagePickerController alloc] init];
        _imagePicker.delegate = self;
        _imagePicker.allowsEditing = YES;
        
        [_imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
        [_txtViewPostContent resignFirstResponder];
        [self presentViewController:_imagePicker animated:YES completion:nil];
    } else {
        showAlertDialog(NSLocalizedString(@"Camera not available",nil), NSLocalizedString(@"Error",nil));
    }
}

- (IBAction)btnActionChoosePhotoLibrarySource:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        _imagePicker = [[UIImagePickerController alloc] init];
        _imagePicker.delegate = self;
        _imagePicker.videoQuality = UIImagePickerControllerQualityTypeMedium;
        _imagePicker.allowsEditing = YES;
        _imagePicker.videoMaximumDuration = RCMaxVideoLength;
        NSMutableArray *currentMediaTypesArray = [[NSMutableArray alloc] initWithArray:_imagePicker.mediaTypes];
        [currentMediaTypesArray addObject:(NSString *) kUTTypeMovie];
        _imagePicker.mediaTypes =[[NSArray alloc] initWithArray:currentMediaTypesArray];
        [_imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        [_txtViewPostContent resignFirstResponder];
        [self presentViewController:_imagePicker animated:YES completion:nil];
    } else {
        showAlertDialog(NSLocalizedString(@"Photo library not available",nil), NSLocalizedString(@"Error", nil) );
    }

}

- (IBAction)btnActionChooseVideSource:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        _imagePicker = [[UIImagePickerController alloc] init];
        _imagePicker.delegate = self;
        _imagePicker.videoQuality = UIImagePickerControllerQualityTypeMedium;
        _imagePicker.mediaTypes =[[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
        _imagePicker.videoMaximumDuration = RCMaxVideoLength;
        [_imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
        [_txtViewPostContent resignFirstResponder];
        [self presentViewController:_imagePicker animated:YES completion:nil];
    } else {
        showAlertDialog(NSLocalizedString(@"Camera not available",nil), NSLocalizedString(@"Error",nil));
    }
}

- (IBAction)btnPrivacyOptionTouchedUpInside:(id)sender {
    [_btnPrivacyOption setEnabled:NO];
    if (!_isShowingPrivacyOption) {
        if (_datePickerView != nil && !_datePickerView.hidden)
            [self openDatePickerView:nil];
        
        _isShowingPrivacyOption = YES;
        [_imgViewPrivacyOptionFrame setHidden:NO];
        [self backgroundTouchUpInside:self];
        [UIView animateWithDuration:0.3 animations:^{
            [_imgViewPrivacyOptionFrame.layer setOpacity:1.0];
            [_txtFieldPostSubject.layer setOpacity:0.0];
            [_txtViewPostContentFrame.layer setOpacity:0.0];
        } completion:^(BOOL finished) {
            [_txtFieldPostSubject setHidden:YES];
            [_txtViewPostContentFrame setHidden:YES];
            [_btnPrivacyOption setEnabled:YES];
        }];
        
    }else {
        _isShowingPrivacyOption = NO;
        [_txtFieldPostSubject setHidden:NO];
        [_txtViewPostContentFrame setHidden:NO];
        [_txtFieldPostSubject becomeFirstResponder];
        [UIView animateWithDuration:0.3 animations:^{
            [_imgViewPrivacyOptionFrame.layer setOpacity:0.0];
            [_txtFieldPostSubject.layer setOpacity:1.0];
            [_txtViewPostContentFrame.layer setOpacity:1.0];
        } completion:^(BOOL finished) {
            [_imgViewPrivacyOptionFrame setHidden:YES];
            [_btnPrivacyOption setEnabled:YES];
        }];
    }
    
}

- (IBAction)btnFacebookOptionTouchedUpInside:(id)sender {
    [_btnFacebookOption setEnabled:NO];
    if (_isFacebookPost) {
        _isFacebookPost = NO;
        [_btnFacebookOption setBackgroundImage:[UIImage imageNamed:@"facebookIconDisabled"] forState:UIControlStateNormal];
        [_btnFacebookOption setEnabled:YES];
    }else {
        if ([FBSession.activeSession isOpen]) {
            // Session is open
            [RCFacebookHelper validatePublishPermissionAndPerformAction:^{
                _isFacebookPost = YES;
                [_btnFacebookOption setBackgroundImage:[UIImage imageNamed:@"facebookIcon"] forState:UIControlStateNormal];
                [_btnFacebookOption setEnabled:YES];
            }];
        } else {
            // Session is closed
            showConfirmationDialog(NSLocalizedString(@"You are not logged in to Facebook yet. Do you want to go to settings?", nil), NSLocalizedString(@"Facebook",nil) , self);
        }
    }
}

// alert view delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [_btnFacebookOption setEnabled:YES];
    if (buttonIndex == 1){
        RCFacebookSettingsViewController *facebookSettingsViewController = [[RCFacebookSettingsViewController alloc] init];
        [self.navigationController pushViewController:facebookSettingsViewController animated:YES];
    }
}

- (IBAction)openFriendList:(UIButton*) sender {
    _friendListPickerViewController = [[RCFriendListViewController alloc] initWithUser:_user withLoggedinUser:[RCUser currentUser]];
    RCFriendListViewController* viewController = _friendListPickerViewController;
    [self presentViewController:viewController animated:YES completion:nil];
    [viewController.btnFollowees setHidden:YES];
    [viewController.btnRequests setHidden:YES];
    [viewController.btnFriends setHidden:YES];
    UIButton* doneButton = [[UIButton alloc] initWithFrame:viewController.btnFriends.frame];
    CGRect frame = doneButton.frame;
    frame.size.width *= 2;
    doneButton.frame = frame;
    [doneButton setImage:[UIImage imageNamed:@"backButton"] forState:UIControlStateNormal ] ;
    [doneButton addTarget:self action:@selector(closeFriendList) forControlEvents:UIControlEventTouchUpInside];
    [viewController.view addSubview:doneButton];
    viewController.tblViewFriendList.delegate = self;
}

- (void) closeFriendList {
    [self dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - UITableViewDelegate used for picking friends

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [RCUserTableCell cellHeight];
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self dismissViewControllerAnimated:YES completion:nil];
    _timeCapsuleReceiver = [_friendListPickerViewController userAtTableIndexPath:indexPath];
    _datePickerView.txtFieldSendToFriend.text = _timeCapsuleReceiver.name;
}

- (IBAction) openDatePickerView:(UIButton*) sender {
    static CGFloat moveBackBy = 0;
    if (!_isTimedRelease) {
        if (_isShowingPrivacyOption)
            [self btnPrivacyOptionTouchedUpInside:nil];
        
        BOOL open = YES;
        if (_datePickerView == nil) {
            NSArray *nibContents = [[NSBundle mainBundle] loadNibNamed:@"RCDatePickerView" owner:self options:nil];
            _datePickerView = (RCDatePickerView*)nibContents[0];
            [_datePickerView prepareView];
            [_datePickerView setDelegate:self];
            [self.view addSubview:_datePickerView];
            CGRect frame = _datePickerView.frame;
            frame.origin.x = (self.view.frame.size.width - frame.size.width) / 2.0;
            frame.origin.y = [self.view convertPoint:sender.frame.origin fromView:sender].y - frame.size.height - 3;
            moveBackBy = - frame.origin.y;
            _datePickerView.frame = frame;
            _datePickerView.alpha = 0.0;
            [_datePickerView.btnAddFriend addTarget:self action:@selector(openFriendList:) forControlEvents:UIControlEventTouchUpInside];
            
        } else {
            if (!_datePickerView.hidden)
                open = NO;
            else
                [_datePickerView setHidden:NO];
        }
        [UIView animateWithDuration:0.5
                      delay:0
                    options:UIViewAnimationOptionCurveEaseInOut
                 animations:^{
                     if (!open) {
                         CGRect frame2 =_datePickerView.frame;
                         CGRect frame =  self.viewMainFrame.frame;
                         frame.origin.y -= moveBackBy;
                         frame2.origin.y -= moveBackBy;
                         _datePickerView.frame = frame2;
                         self.viewMainFrame.frame = frame;
                     } else {
                         CGRect frame2 =_datePickerView.frame;
                         CGRect frame =  self.viewMainFrame.frame;
                         frame.origin.y += moveBackBy;
                         frame2.origin.y += moveBackBy;
                         _datePickerView.frame = frame2;
                         self.viewMainFrame.frame = frame;
                     }

                     if (open)
                         _datePickerView.alpha = 1.0;
                     else {
                         _datePickerView.alpha= 0.0;
                                                  }
                 }
                 completion:^(BOOL finished) {
                     if (!open)
                         [_datePickerView setHidden:YES];
                 }];
    }else {
        _isTimedRelease = NO;
        [_timeCapsule setImage:[UIImage imageNamed:@"postButtonTimeCapsuleInactive.png"] forState:UIControlStateNormal];
        _datePickerView.txtFieldSendToFriend.text = @"";
        _timeCapsuleReceiver = nil;
        _btnPrivacyOption.enabled = YES;
        showAlertDialog(NSLocalizedString(@"You have deactivated capsule release mode for this post",nil), NSLocalizedString(@"Notice",nil));
    }
}

- (void) removePhotoSourceControlAndAddPrivacyControl {
    /*[_btnCameraSource setHidden:YES];
    [_btnPhotoLibrarySource setHidden:YES];
    [_btnVideoSource setHidden:YES];*/
    
    
    [_timeCapsule setImage:[UIImage imageNamed:@"postButtonTimeCapsuleInactive.png"] forState:UIControlStateNormal];
    [_timeCapsule setImage:[UIImage imageNamed:@"postButtonTimeCapsule-highlighted.png"] forState:UIControlStateHighlighted];
    [_timeCapsule setImage:[UIImage imageNamed:@"postButtonTimeCapsule-highlighted.png"] forState:UIControlStateDisabled];
    //[self.view addSubview:_imgViewPrivacyControlFrame];
    
    [_imgViewPrivacyControlFrame setHidden:NO];
    CGRect frame = _imgViewControlFrame.frame;
    frame.origin.x = _imgViewControlFrame.frame.size.width + _imgViewControlFrame.frame.origin.x;
    //frame.origin.y = 0;
    _imgViewPrivacyControlFrame.frame = frame;
    [UIView animateWithDuration:0.6
						  delay:0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
                         CGRect frame3 = _imgViewControlFrame.frame;
                         frame3.origin.x -= frame3.size.width;
                         _imgViewControlFrame.frame = frame3;
                         CGRect frame2 = frame;
                         frame2.origin.x -= frame2.size.width;
                         _imgViewPrivacyControlFrame.frame = frame2;
                     } completion:^(BOOL finished){
                         _isShowingPrivacyOption = YES;
                         [self setPostPrivacyOption:_publicPrivacyButton];
                     }];
}

#pragma mark - tap gesture handler
-(void) handleTap:(UITapGestureRecognizer *)tapGestureRecognizer {
    if (_isTapToCloseKeyboard){
        [self backgroundTouchUpInside:nil];
        _isTapToCloseKeyboard = NO;
        [self.view removeGestureRecognizer:_tapGestureRecognizer];
    }
    else {
        CGPoint point = [tapGestureRecognizer locationInView:_imageViewPostFrame];
        //CGRect frame = _imageViewPostFrame.frame;
        if (![_imageViewPostFrame pointInside:point withEvent:nil])
            [self closeBtnTouchUpInside:nil];
    }
}

#pragma mark - UITextView delegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    _isTapToCloseKeyboard = YES;
    //[self.view addGestureRecognizer:_tapGestureRecognizer];
    if ([textView isEqual:_txtViewPostContent]) {
        // register for keyboard notifications

        /*if (_firstTimeEditPost )   {
            //[textView setText:@""];
            _firstTimeEditPost = NO;
        }*/
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)string
{
    NSString *resultString = [textView.text stringByReplacingCharactersInRange:range withString:string];
    NSLog(@"resulting string would be: %@", resultString);
    //TODO optimize
    NSString *prefixString = [NSString stringWithFormat:@"%@ ",_user.name];
    NSRange prefixStringRange = [resultString rangeOfString:prefixString];
    if (prefixStringRange.location == 0) {
        // prefix found at the beginning of result string
        return YES;
    }
    return NO;
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    _isTapToCloseKeyboard = YES;
    //[self.view addGestureRecognizer:_tapGestureRecognizer];
    // register for keyboard notifications
    /*[[NSNotificationCenter defaultCenter] addObserver:_keyboardPushHandler
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:_keyboardPushHandler
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];*/
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    /*[[NSNotificationCenter defaultCenter] removeObserver:_keyboardPushHandler
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:_keyboardPushHandler
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];*/
}
- (BOOL)textFieldShouldReturn :(UITextField*) textField {
    //[self.view removeGestureRecognizer:_tapGestureRecognizer];
    //[textField resignFirstResponder];
    [_txtViewPostContent becomeFirstResponder];
    return NO;
}
- (IBAction)closeBtnTouchUpInside:(id)sender {
   
    NSLog(@"clicked close on newpostviewcontroller");
//    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == _txtFieldPostSubject) {
        NSUInteger newLength = [textField.text length] + [string length] - range.length;
        return (newLength <= 48);
    }
    return YES;
}

#pragma mark - post privacy options
- (IBAction) setPostPrivacyOption:(UIButton*) sender {
    if ([sender isEqual:_publicPrivacyButton])
        _privacyOption = @"public";
    if ([sender isEqual:_friendPrivacyButton])
        _privacyOption = @"friends";
    if ([sender isEqual:_personalPrivacyButton])
        _privacyOption = @"personal";
    NSMutableArray *buttons = [[NSMutableArray alloc] init];
    [buttons addObject:_publicPrivacyButton];
    [buttons addObject:_friendPrivacyButton];
    [buttons addObject:_personalPrivacyButton];
    NSMutableArray *buttonFileNames = [[NSMutableArray alloc] init];
    [buttonFileNames addObject:@"postPublicPrivacyButton-2"];
    [buttonFileNames addObject:@"postFriendPrivacyButton-2"];
    [buttonFileNames addObject:@"postPersonalPrivacyButton-2"];
    int i = 0;
    for (UIButton *button in buttons) {
        if([button isEqual:sender]) {
            [button setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@-highlighted.png",[buttonFileNames objectAtIndex:i]]] forState:UIControlStateDisabled];
            button.enabled = NO;
        }
        else {
            button.enabled = YES;
            [button setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@.png",[buttonFileNames objectAtIndex:i]]] forState:UIControlStateNormal];
        }
        i++;
    }
    
    [_btnPrivacyOption setBackgroundImage:sender.imageView.image forState:UIControlStateNormal];
    [self btnPrivacyOptionTouchedUpInside:self];
}

#pragma mark - UICollectionView Datasource
// 1
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    return [_topics count] + 1;//section == 0 ? [[_postsByLandmark objectForKey:[[NSNumber alloc] initWithInteger:_currentLandmarkID]] count] : 0;
}
// 2
- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}
// 3
- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString* cellIdentifier = [RCLandmarkCell cellIdentifier];
    RCLandmarkCell *cell = [cv dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    int idx = [indexPath row] - 1;
    if (idx < 0) {
        if (_currentTopic == nil)
            [cell.imgViewChosenMark setImage:[UIImage imageNamed:@"postLandmarkChosenBackground.png"]];
        else
            [cell.imgViewChosenMark setImage:nil];
        [cell.imgViewCategory setImage:[UIImage imageNamed:@"topicCancel.png"]];
        cell.lblLandmarkTitle.text = @"No topic";        
    } else {
        NSString *topic = [_topics objectAtIndex:idx];
        NSString *imageName = [NSString stringWithFormat:@"topicCategory%@.png", topic];
        [cell.imgViewCategory setImage:[UIImage imageNamed:imageName]];
        
        if ([topic isEqualToString:_currentTopic])
            [cell.imgViewChosenMark setImage:[UIImage imageNamed:@"postLandmarkChosenBackground.png"]];
        else
            [cell.imgViewChosenMark setImage:nil];
        cell.lblLandmarkTitle.lineBreakMode = NSLineBreakByWordWrapping;
        cell.lblLandmarkTitle.numberOfLines = 0;
        cell.lblLandmarkTitle.text = topic;
        NSLog(@"width of text label %f", cell.lblLandmarkTitle.frame.size.width);
        NSLog(@"width of cell %f", cell.frame.size.width);
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
    int idx = [indexPath row] - 1;
    UIButton *button = _btnChooseLandmark;//(UIButton*)_txtFieldPostSubject.leftView;
    if (idx >= 0) {
        NSString *topic = [_topics objectAtIndex:idx];
        _currentTopic = topic;
        NSString *imageName = [NSString stringWithFormat:@"topicCategory%@.png", topic];
        [button setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
        _lblLandmarkName.text = [NSString stringWithFormat:@"%@ @ %@",_user.name,topic];
    } else {
        _currentTopic = nil;
        [button setImage:[UIImage imageNamed:@"buttonTopic.png"] forState:UIControlStateNormal];
        _lblLandmarkName.text = _user.name;
    }
    [_viewTopic removeFromSuperview];
    _landmarkTableVisible = NO;
}

#pragma mark – UICollectionViewDelegateFlowLayout

// 1
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    float height = (collectionView.frame.size.height-42);
    float width = (collectionView.frame.size.width - 22) / 3;
    CGSize retval = CGSizeMake(width,height);
    return retval;
}

// 3
- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(30,10,10,10);
}

- (void)convertVideoToLowQuailtyWithInputURL:(NSURL*)inputURL
outputURL:(NSURL*)outputURL
handler:(void (^)(AVAssetExportSession*))handler
{
    [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void)
     {
         handler(exportSession);
     }];
}

#pragma mark - RCDatePickerDelegate
- (void) didPickDate:(NSDate *)pickedDateTime success:(BOOL)success {
    [self openDatePickerView:nil];
    if (success) {
        _isTimedRelease = YES;
        [_timeCapsule setImage:[UIImage imageNamed:@"postButtonTimeCapsuleActive.png"] forState:UIControlStateNormal];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"HH:mm, dd/MM/yyyy"];
        
        showAlertDialog([NSString stringWithFormat:NSLocalizedString(@"You have scheduled your post to be released at %@", nil), [dateFormatter stringFromDate:pickedDateTime]], NSLocalizedString(@"Notice",nil));
        if (_timeCapsuleReceiver != nil) {
            [_btnPrivacyOption setBackgroundImage:[UIImage imageNamed:@"postPersonalPrivacyButton-2"] forState:UIControlStateDisabled];
            _btnPrivacyOption.enabled = NO;
        }
    }else {
        showAlertDialog(NSLocalizedString(@"The release date has already passed", nil) , NSLocalizedString(@"Notice",nil));
    }
}
@end


