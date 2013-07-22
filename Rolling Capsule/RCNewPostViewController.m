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
#import <QuartzCore/QuartzCore.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <MediaPlayer/MediaPlayer.h>
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

@end

@implementation RCNewPostViewController

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
@synthesize postComplete = _postComplete;
@synthesize postCancel = _postCancel;
@synthesize viewFirstLoad = _viewFirstLoad;
@synthesize activityIndicator = _activityIndicator;
@synthesize currentTopic = _currentTopic;

BOOL _isTapToCloseKeyboard = NO;
BOOL _landmarkTableVisible = NO;
BOOL _successfulPost = NO;
BOOL _firstTimeEditPost = YES;
BOOL _didFinishUploadingImage = NO;
BOOL _isMovie = NO;
BOOL _isPosting = NO;
BOOL _isTimedRelease = NO;



S3PutObjectResponse *_putObjectResponse;
AmazonClientException *_amazonException;
RCConnectionManager *_connectionManager;
NSData *_uploadData;
NSData *_thumbnailData;

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
        //[self.view addGestureRecognizer:_tapGestureRecognizer];
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
        _connectionManager = [[RCConnectionManager alloc] init];
    }
    return self;
}

- (id) initWithUser:(RCUser *)user {
    self = [super init];
    if (self) {
        _user = user;
        _keyboardPushHandler = [[RCKeyboardPushUpHandler alloc] init];
        _connectionManager = [[RCConnectionManager alloc] init];
    }
    return self;
}

- (id) initWithUser:(RCUser *)user withBackgroundImage:(UIImage*) image{
    self = [super init];
    if (self) {
        _user = user;
        _keyboardPushHandler = [[RCKeyboardPushUpHandler alloc] init];
        _connectionManager = [[RCConnectionManager alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [_connectionManager reset];
    
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
    
    
    //[_txtViewPostContent setText:_user.name];
}

- (void) resetUploadStatus {
    _didFinishUploadingImage = NO;
    _amazonException = nil;
    _isPosting = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction) postNew:(id) sender {
    _isPosting = YES;
    if (_uploadData == nil) {
        [self showAlertMessage:@"Please choose an image or video!" withTitle:@"Incomplete post!"];
        return;
    }
    if (_privacyOption == nil) {
        [self showAlertMessage:@"Please choose a privacy option!" withTitle:@"Incomplete post!"];
        return;
    }
    [_connectionManager startConnection];
    _postButton.enabled = NO;
    dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
    dispatch_async(queue, ^{
        NSLog(@"infinite loop waiting for upload to finish");
        if (_didFinishUploadingImage) {
            [self uploadPostMetadata];
            //NSLog(@"waiting for upload finish");
        }
        
    });
}

- (void) uploadPostMetadata {
    if (_amazonException != nil) {
        [_connectionManager endConnection];
        _postButton.enabled = YES;
        [self showAlertMessage:@"Failed to upload image, please try again later!" withTitle:RCUploadError];
        [self resetUploadStatus];
        dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
        dispatch_async(queue, ^{
            [self uploadImageToS3:_uploadData withThumbnail:_thumbnailData dataBeingMovie:_isMovie];
            [self processCompletionOfDataUpload];
        });
        return;
    }
    else if (_putObjectResponse.error != nil) {
        
        [_connectionManager endConnection];
        _postButton.enabled = YES;
        [self showAlertMessage:_putObjectResponse.error.description withTitle:@"Upload Error"];
        [self resetUploadStatus];
        dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
        dispatch_async(queue, ^{
            [self uploadImageToS3:_uploadData withThumbnail:_thumbnailData dataBeingMovie:_isMovie];
            [self processCompletionOfDataUpload];
           
        });
        return;
    }
    [self performSelectorOnMainThread:@selector(asynchPostNewResuest) withObject:nil waitUntilDone:YES];
}

- (void) processCompletionOfDataUpload {
     NSLog(@"finished uploading image/video data");
    _didFinishUploadingImage = YES;
    if (_isPosting) {
        [self uploadPostMetadata];
    }
    
}

#pragma mark - upload method

- (void)uploadImageToS3:(NSData *)imageData withThumbnail:thumbnailData dataBeingMovie:(BOOL) isMovie
{
    AmazonS3Client *s3 = [RCAmazonS3Helper s3:_user.userID forResource:[NSString stringWithFormat:@"%@/*", RCAmazonS3UsersMediaBucket]];
    if (s3 != nil) {
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        CFStringRef string = CFUUIDCreateString(NULL, theUUID);
        CFRelease(theUUID);
        _imageFileName = [(__bridge NSString*)string stringByReplacingOccurrencesOfString:@"-"withString:@""];
        if (isMovie) {
            _imageFileName = [NSString stringWithFormat:@"%@.mov",_imageFileName];
        }
        // Upload image data.  Remember to set the content type.
        S3PutObjectRequest *por = [[S3PutObjectRequest alloc] initWithKey:_imageFileName
                                                                 inBucket:RCAmazonS3UsersMediaBucket];
        por.contentType = isMovie ? @"movie/mov" : @"image/jpeg";
        por.data = imageData;
        
        S3PutObjectRequest *porThumbnail = [[S3PutObjectRequest alloc] initWithKey:[NSString stringWithFormat:@"%@-thumbnail",_imageFileName]
                                                                 inBucket:RCAmazonS3UsersMediaBucket];
        porThumbnail.contentType = @"image/jpeg";
        porThumbnail.data = thumbnailData;

        
        @try {
            NSLog(@"before calling data s3 putObject");
            _putObjectResponse = [s3 putObject:por];
            NSLog(@"done uploading data to s3 result %@",_putObjectResponse);
            if (_putObjectResponse.error != nil)
            {
                NSLog(@"Error: %@", _putObjectResponse.error);
            }
            if (thumbnailData != nil)
            {
                NSLog(@"before calling thumbnail s3 putObject");
                _putObjectResponse = [s3 putObject:porThumbnail];
                NSLog(@"done uploading thumbnail to s3 result %@",_putObjectResponse);
            }
            if (_putObjectResponse.error != nil)
            {
                NSLog(@"Error: %@", _putObjectResponse.error);
            }
        }@catch (AmazonClientException *exception) {
            NSLog(@"New-Post: Error: %@", exception);
            NSLog(@"New-Post: Debug Description: %@",exception.debugDescription);
            _amazonException = exception;
        }
    } else {
        NSString* errorString = @"Failed to obtain S3 credentails from backend";
        NSLog(@"New-Post: Error: %@", errorString);
        _amazonException = [AmazonClientException exceptionWithMessage:errorString];
    }
}

#pragma mark - helper methods

- (void)showAlertMessage:(NSString *)message withTitle:(NSString *)title
{
    UIAlertView *alertView = [[UIAlertView alloc]  initWithTitle:title
                                                         message:message
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
    [alertView show];
}

#pragma mark - post web request

- (void) asynchPostNewResuest {
    //Asynchronous Request
    @try {
        
        NSString* prefix = [NSString stringWithFormat:@"%@ ",_user.name];
        _postContent = [[_txtViewPostContent text] substringFromIndex:[prefix length]];
        NSString *postSubject = [_txtFieldPostSubject text];
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        CLLocationDegrees latitude = appDelegate.currentLocation.coordinate.latitude;
        CLLocationDegrees longitude = appDelegate.currentLocation.coordinate.longitude;
        NSString* latSt = [[NSString alloc] initWithFormat:@"%f",latitude];
        NSString* longSt = [[NSString alloc] initWithFormat:@"%f",longitude];
        NSString* thumbnail = (_thumbnailData != nil) ? [NSString stringWithFormat:@"%@-thumbnail",_imageFileName] : _imageFileName ;
        NSMutableString *dataSt = initQueryString(@"post[content]", _postContent);
        addArgumentToQueryString(dataSt, @"post[rating]", @"5");
        addArgumentToQueryString(dataSt, @"post[latitude]", latSt);
        addArgumentToQueryString(dataSt, @"post[longitude]", longSt);
        addArgumentToQueryString(dataSt, @"post[file_url]", _imageFileName);
        addArgumentToQueryString(dataSt, @"post[privacy_option]", _privacyOption);
        addArgumentToQueryString(dataSt, @"post[thumbnail_url]", thumbnail);
        addArgumentToQueryString(dataSt, @"post[subject]", postSubject);
        if (_currentTopic != nil)
            addArgumentToQueryString(dataSt, @"post[topic]", _currentTopic);
        if (_datePickerView != nil) {
            NSString* releaseDate = [_datePickerView dateTimeString];
            if (releaseDate != nil) {
                addArgumentToQueryString(dataSt, @"post[release]", releaseDate);
            }
        }
        if (_currentLandmark != nil) {
            addArgumentToQueryString(dataSt, @"landmark_id", [NSString stringWithFormat:@"%d",_currentLandmark.landmarkID]);
        }
        NSData *postData = [dataSt dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
        
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@", RCServiceURL, RCPostsResource]];
        
        NSURLRequest *request = CreateHttpPostRequest(url, postData);
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
        {
            NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
            int responseStatusCode = [httpResponse statusCode];
            if (responseStatusCode != RCHttpOkStatusCode) {
                _successfulPost = NO;
            } else _successfulPost = YES;
            
            [_connectionManager endConnection];
            _postButton.enabled = YES;
            
            NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"%@",responseData);
            
            //Temporary:
            if (_successfulPost) {
                //TODO open main news feed page
                [self showAlertMessage:@"Image posted successfully!" withTitle:@"Success!"];
                [self dismissViewControllerAnimated:YES completion:^{
                    if (_postComplete != nil)
                        _postComplete();
                }];
                /*[self animateViewDisapperance:^ {
                    if (_postComplete != nil)
                        _postComplete();
                    [self.view removeFromSuperview];
                    [self removeFromParentViewController];
                }];*/
            }else {
                alertStatus([NSString stringWithFormat:@"Please try again! %@", responseData], @"Post Failed!", self);
                _isPosting = NO;
            }
        }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        self.navigationItem.rightBarButtonItem.enabled = YES;
        alertStatus(@"Post Failed.",@"Post Failed!",self);
        _isPosting = NO;
    }
}

- (void) asynchGetLandmarkRequest {
    @try {
        [_connectionManager startConnection];
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        CLLocationCoordinate2D zoomLocation = appDelegate.currentLocation.coordinate;
        
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@?mobile=1&latitude=%f&longitude=%f&%@", RCServiceURL, RCLandmarksResource, zoomLocation.latitude, zoomLocation.longitude, RCLevelsQueryString]];
        NSURLRequest *request = CreateHttpGetRequest(url);
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             [_connectionManager endConnection];
             NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
             
             NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
             int responseStatusCode = [httpResponse statusCode];
             if (responseStatusCode != RCHttpOkStatusCode) {
                 NSLog(@"New-Post: backend error %@", responseData);
             } else {
                 SBJsonParser *jsonParser = [SBJsonParser new];
                 NSArray *jsonData = (NSArray *) [jsonParser objectWithString:responseData error:nil];
                 [_topics removeAllObjects];
                 for (NSDictionary *landmarkJson in jsonData) {
                     RCLandmark *landmark = [[RCLandmark alloc] initWithNSDictionary:landmarkJson];
                     [_topics addObject:landmark];
                 }
                 [_collectionViewTopic reloadData];
             }
         }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        [_connectionManager endConnection];
        self.navigationItem.rightBarButtonItem.enabled = YES;
        alertStatus(@"Post Failed.",@"Post Failed!",self);
    }

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
    [_activityIndicator removeFromSuperview];
    [_activityIndicator stopAnimating];
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
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self removePhotoSourceControlAndAddPrivacyControl];
    /*[UIView animateWithDuration:0.6
						  delay:0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
                         _btnCameraSource.alpha = 0.0;
                         _btnPhotoLibrarySource.alpha = 0.0;
                         _btnVideoSource.alpha = 0.0;
					 }
                     completion:^(BOOL finished) {
                         [self removePhotoSourceControlAndAddPrivacyControl];
					 }];*/
    if (_activityIndicator == nil)
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:_scrollViewImage.frame];
    [self.view addSubview:_activityIndicator];
    [_activityIndicator startAnimating];
    dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
    dispatch_async(queue, ^{
        NSLog(@"inside data upload");
        NSLog(@"generating thumbnail");
        //after succesful thumbnail generation start uploading data
        NSLog(@"begin uploading data");
        NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
        //check if media is a video

        if (CFStringCompare ((__bridge CFStringRef) mediaType, kUTTypeMovie, 0)
            == kCFCompareEqualTo)
        {
            NSString *moviePath = [[info objectForKey:UIImagePickerControllerMediaURL] path];
            if ([picker sourceType] == UIImagePickerControllerSourceTypeCamera)
                UISaveVideoAtPathToSavedPhotosAlbum (moviePath, nil, nil, nil);
            _videoUrl=(NSURL*)[info objectForKey:UIImagePickerControllerMediaURL];
            AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:_videoUrl options:nil];
            CMTime duration = sourceAsset.duration;
            AVAssetImageGenerator* generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:sourceAsset];
            generator.appliesPreferredTrackTransform = YES;
            //Get the 1st frame 3 seconds in
            int frameTimeStart = (int)(CMTimeGetSeconds(duration) / 2.0);
            int frameLocation = 1;
            //Snatch a frame
            CGImageRef frameRef = [generator copyCGImageAtTime:CMTimeMake(frameTimeStart,frameLocation) actualTime:nil error:nil];
            _postImage = [UIImage imageWithCGImage:frameRef];
            _uploadData = [NSData dataWithContentsOfURL:_videoUrl];
            NSLog(@"obtained thumbnail and upload data");
        } else {
            //save photo if newly taken
            if ([picker sourceType] == UIImagePickerControllerSourceTypeCamera)
                UIImageWriteToSavedPhotosAlbum(_postImage, self, nil, nil);
            _postImage = [info objectForKey:UIImagePickerControllerOriginalImage];
            NSLog(@"image size %f %f",_postImage.size.width, _postImage.size.height);
            if (_postImage.size.width > 800 && _postImage.size.height > 800) {
                float division = MIN(_postImage.size.width/(800.0-1.0), _postImage.size.height/(800-1.0));
                UIImage *rescaledPostImage = imageWithImage(_postImage, CGSizeMake(_postImage.size.width/division,_postImage.size.height/division));
                _postImage = rescaledPostImage;
                _uploadData = UIImageJPEGRepresentation(rescaledPostImage, 1.0);
            } else {
                _uploadData = UIImageJPEGRepresentation(_postImage, 1.0);
            }
            NSLog(@"number of bytes %d",[_uploadData length]);
            
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setupImageScrollView];
            NSLog(@"remove activity indicator");
            [_activityIndicator removeFromSuperview];
            [_activityIndicator stopAnimating];
            
        });
        
        UIImage *thumbnail;

        if (CFStringCompare ((__bridge CFStringRef) mediaType, kUTTypeMovie, 0)
            == kCFCompareEqualTo)
        {
            _isMovie = YES;
            thumbnail = [info objectForKey:UIImagePickerControllerEditedImage];
            if (thumbnail == nil)
                thumbnail = [self generateSquareImageThumbnail:_postImage];
            UIImage *rescaledThumbnail = imageWithImage(thumbnail, CGSizeMake(RCUploadImageSizeWidth,RCUploadImageSizeHeight));
            _thumbnailData = UIImageJPEGRepresentation(rescaledThumbnail,0.7);
        } else {
            // Get the selected image
            _isMovie = NO;
            thumbnail = [self generateSquareImageThumbnail:_postImage];
            //generate thumbnail
            UIImage *uploadThumbnailImage =imageWithImage(thumbnail, CGSizeMake(RCUploadImageSizeWidth,RCUploadImageSizeHeight));;
            _thumbnailData = UIImageJPEGRepresentation(uploadThumbnailImage, 0.7);
        }
        
        
        
        NSLog(@"before uploading image");
        [self uploadImageToS3:_uploadData withThumbnail:_thumbnailData dataBeingMovie:_isMovie];
        [self processCompletionOfDataUpload];
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
    UIImage *closeImage = [UIImage imageNamed:@"buttonCancel.png"];
    CGFloat buttonWidth = closeImage.size.width/2.0;
    CGFloat buttonHeight = closeImage.size.height/2.0;
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(0,0,buttonWidth,buttonHeight)];
    [closeButton setBackgroundImage:closeImage forState:UIControlStateNormal];
    closeButton.frame = CGRectMake(_imgViewMainFrame.frame.origin.x + _imgViewMainFrame.frame.size.width - buttonWidth - 3,_imgViewMainFrame.frame.origin.y,buttonWidth,buttonHeight);
    [self.view addSubview:closeButton];
    [closeButton addTarget:self action:@selector(closeBtnTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    /*if ([[UIScreen mainScreen] bounds].size.height < RCIphone5Height && _viewFirstLoad) {
        _viewFirstLoad = NO;
        [_closeButton setHidden:YES];
        [_closeButton setEnabled:NO];
        CGRect closeFrame = _closeButton.frame;
        closeFrame.origin.y += 20;
        UIButton *newCloseButton = [[UIButton alloc] initWithFrame:closeFrame];
        [newCloseButton setImage:[UIImage imageNamed:@"closeButton.png"] forState:UIControlStateNormal];
        [newCloseButton addTarget:self action:@selector(closeBtnTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:newCloseButton];
        CGRect frame = self.view.frame;
        //move view up so that the whole post frame fits in iphone 4 screen
        //here we basically move the y coordinate back by exactly the amount
        //with which the post frame is away from screen top edge
        //leaving some gap in between
        frame.origin.y = -_imageViewPostFrame.frame.origin.y + 2;
        frame.size.height +=  _imageViewPostFrame.frame.origin.y - 2;
        self.view.frame = frame;
        
    }*/
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
    [super viewWillDisappear:animated];
    
}
#pragma mark - animate in the view
/*- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    
}*/



#pragma mark - UI actions

- (IBAction)btnActionChooseCameraSource:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
        
        [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
        [_txtViewPostContent resignFirstResponder];
        [self presentViewController:imagePicker animated:YES completion:nil];
    } else {
        alertStatus(@"Camera not available", @"Error!",nil);
    }
}

- (IBAction)btnActionChoosePhotoLibrarySource:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
        imagePicker.videoQuality = UIImagePickerControllerQualityTypeMedium;
        //imagePicker.allowsEditing = YES;
        imagePicker.videoMaximumDuration = RCMaxVideoLength;
        NSMutableArray *currentMediaTypesArray = [[NSMutableArray alloc] initWithArray:imagePicker.mediaTypes];
        [currentMediaTypesArray addObject:(NSString *) kUTTypeMovie];
        imagePicker.mediaTypes =[[NSArray alloc] initWithArray:currentMediaTypesArray];
        [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        [_txtViewPostContent resignFirstResponder];
        [self presentViewController:imagePicker animated:YES completion:nil];
    } else {
        alertStatus(@"Photo library not available", @"Error!",nil);
    }

}

- (IBAction)btnActionChooseVideSource:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
        imagePicker.videoQuality = UIImagePickerControllerQualityTypeMedium;
        imagePicker.mediaTypes =[[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
        //imagePicker.allowsEditing = YES;
        imagePicker.videoMaximumDuration = RCMaxVideoLength;
        [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
        [_txtViewPostContent resignFirstResponder];
        [self presentViewController:imagePicker animated:YES completion:nil];
    } else {
        alertStatus(@"Camera not available", @"Error!",nil);
    }
}

- (IBAction) openDatePickerView:(UIButton*) sender {
    
    if (!_isTimedRelease) {
    
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
            _datePickerView.frame = frame;
            _datePickerView.alpha = 0.0;
            
            
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
        alertStatus(@"You have deactivated capsule release mode for this post", @"Notice", nil);
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
                         [self setPostPrivacyOption:_publicPrivacyButton];
                     }];
    /*int buttonSize = 41;
    int distance = 13;
    if ([[UIScreen mainScreen] bounds].size.height < RCIphone5Height) {
        buttonSize = 35;
        distance += 41-35;
    }

    CGRect frame1 = CGRectMake(_imgViewControlFrame.frame.origin.x + 20,_btnVideoSource.frame.origin.y-3,buttonSize,buttonSize);
    CGRect frame2 = frame1, frame3 = frame1;
    frame2.origin.x = frame1.origin.x+buttonSize+distance;
    frame3.origin.x = frame2.origin.x+buttonSize+distance;
    _publicPrivacyButton = [[UIButton alloc] initWithFrame:frame1];
    [_publicPrivacyButton setImage:[UIImage imageNamed:@"postPublicPrivacyButton-2.png"] forState:UIControlStateNormal];
    _friendPrivacyButton = [[UIButton alloc] initWithFrame:frame2];
    [_friendPrivacyButton setImage:[UIImage imageNamed:@"postFriendPrivacyButton-2.png"] forState:UIControlStateNormal];
    _personalPrivacyButton = [[UIButton alloc] initWithFrame:frame3];
    [_personalPrivacyButton setImage:[UIImage imageNamed:@"postPersonalPrivacyButton-2.png"] forState:UIControlStateNormal];
    
    UIImage *separatorImage = [UIImage imageNamed:@"postVerticalSeparator.png"];
    UIImageView* separator = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,separatorImage.size.width/2.0,separatorImage.size.height/2.0)];
    [separator setImage:separatorImage];
    separator.frame = CGRectMake(frame3.origin.x + 54, frame3.origin.y,separatorImage.size.width/2.0,separatorImage.size.height/2.0);
    
    
    CGRect frame4 = _btnVideoSource.frame;
    frame4.size.width = buttonSize;
    frame4.size.height = buttonSize;
    frame4.origin.x = _imgViewControlFrame.frame.origin.x + _imgViewControlFrame.frame.size.width - 10 - buttonSize;
    _postButton = [[UIButton alloc] initWithFrame:frame4];
    [_postButton setImage:[UIImage imageNamed:@"postPostButton-2.png"] forState:UIControlStateNormal];
    CGRect frame5 = frame4;
    frame5.origin.x = separator.frame.origin.x + separator.frame.size.width;
    timeCapsule = [[UIButton alloc] initWithFrame:frame5];
        
    
    _postButton.alpha = 0.0;
    _publicPrivacyButton.alpha = 0.0;
    _personalPrivacyButton.alpha = 0.0;
    _friendPrivacyButton.alpha = 0.0;
    
    [self.imgViewControlFrame addSubview:_postButton];
    [self.imgViewControlFrame addSubview:timeCapsule];
    [self.imgViewControlFrame addSubview:separator];
    [self.imgViewControlFrame addSubview:_publicPrivacyButton];
    [self.imgViewControlFrame addSubview:_friendPrivacyButton];
    [self.imgViewControlFrame addSubview:_personalPrivacyButton];
    
    
    
    
    [UIView animateWithDuration:0.3
						  delay:0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
                         _postButton.alpha = 1.0;
                         _publicPrivacyButton.alpha = 1.0;
                         _personalPrivacyButton.alpha = 1.0;
                         _friendPrivacyButton.alpha = 1.0;
					 }
                     completion:^(BOOL finished) {
                         [self setPostPrivacyOption:_publicPrivacyButton];
					 }];*/
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
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    /*if ([textView isEqual:_txtViewPostContent]) {
        // register for keyboard notifications
        [[NSNotificationCenter defaultCenter] addObserver:_keyboardPushHandler
                                                 selector:@selector(keyboardWillShow:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:_keyboardPushHandler
                                                 selector:@selector(keyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
    }*/
    return YES;
}
- (void)textViewDidEndEditing:(UITextView *)textView {
    if ([textView isEqual:_txtViewPostContent]) {
       /* [[NSNotificationCenter defaultCenter] removeObserver:_keyboardPushHandler
                                                        name:UIKeyboardWillShowNotification
                                                      object:nil];
        
        [[NSNotificationCenter defaultCenter] removeObserver:_keyboardPushHandler
                                                        name:UIKeyboardWillHideNotification
                                                      object:nil];*/
    }
}

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

- (BOOL)textView:(UITextView *)textField shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)string
{
    NSString *resultString = [textField.text stringByReplacingCharactersInRange:range withString:string];
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
   
    [self dismissViewControllerAnimated:YES completion:^ {
        if (_postCancel != nil)
            _postCancel();
    }];
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
    [buttonFileNames addObject:@"postPublicPrivacyButton"];
    [buttonFileNames addObject:@"postFriendPrivacyButton"];
    [buttonFileNames addObject:@"postPersonalPrivacyButton"];
    int i = 0;
    for (UIButton *button in buttons) {
        if([button isEqual:sender])
            /*[button setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@-highlighted.png",[buttonFileNames objectAtIndex:i]]] forState:UIControlStateNormal];*/
            button.enabled = NO;
        else
            button.enabled = YES;//[button setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@.png",[buttonFileNames objectAtIndex:i]]] forState:UIControlStateNormal];
        i++;
    }
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
        [cell.imgViewCategory setImage:[UIImage imageNamed:@"buttonCancel.png"]];
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
    //[self.view addGestureRecognizer:_tapGestureRecognizer];
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

- (UIImage*) generateSquareImageThumbnail: (UIImage*) largeImage {
    CGFloat squareSize = MIN(largeImage.size.width, largeImage.size.height);
    CGFloat x,y;
    //largeImage.size.
    if (squareSize == largeImage.size.width) {
        x = 0;
        y = (largeImage.size.height - squareSize)/2.0;
    } else {
        y = 0;
        x = (largeImage.size.width  - squareSize)/2.0;
    }
    NSLog(@"crop coordinates x=%f y=%f size=%f",x,y,squareSize);
    CGRect cropRect = CGRectMake(0,0,squareSize,squareSize);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([largeImage CGImage], cropRect);
    // or use the UIImage wherever you like
    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef scale:largeImage.scale orientation:largeImage.imageOrientation];
    CGImageRelease(imageRef);
    return croppedImage;
}

#pragma mark - RCDatePickerDelegate
- (void) didPickDate:(NSDate *)pickedDateTime success:(BOOL)success {
    if (success) {
        _isTimedRelease = YES;
        [_timeCapsule setImage:[UIImage imageNamed:@"postButtonTimeCapsuleActive.png"] forState:UIControlStateNormal];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"HH:mm, dd/MM/yyyy"];
        
        alertStatus([NSString stringWithFormat:@"You have scheduled your post to be released at %@", [dateFormatter stringFromDate:pickedDateTime]], @"Notice", nil);
    }else {
        alertStatus(@"The release date has already passed", @"Notice", nil);
    }
}
@end


