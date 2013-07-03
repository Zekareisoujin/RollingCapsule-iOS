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
#import <QuartzCore/QuartzCore.h>
#import "SBJson.h"

@interface RCNewPostViewController ()

@property (nonatomic,strong) UIImage* postImage;
@property (nonatomic,strong) NSString* postContent;
@property (nonatomic,strong) NSString* imageFileName;
@property (nonatomic, strong) UIButton* postButton;
@property (nonatomic, strong) UIButton* publicPrivacyButton;
@property (nonatomic, strong) UIButton* friendPrivacyButton;
@property (nonatomic, strong) UIButton* personalPrivacyButton;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, strong) NSString* privacyOption;
@end

@implementation RCNewPostViewController

@synthesize postImage = _postImage;
@synthesize postContent = _postContent;
@synthesize imageFileName = _imageFileName;
@synthesize user = _user;
@synthesize keyboardPushHandler = _keyboardPushHandler;
@synthesize landmarks = _landmarks;
@synthesize tblViewLandmark = _tblViewLandmark;
@synthesize currentLandmark = _currentLandmark;
@synthesize postButton = _postButton;
@synthesize publicPrivacyButton = _publicPrivacyButton;
@synthesize friendPrivacyButton = _friendPrivacyButton;
@synthesize personalPrivacyButton = _personalPrivacyButton;
@synthesize privacyOption = _privacyOption;
BOOL _isTapToCloseKeyboard = NO;
BOOL _landmarkTableVisible = NO;
BOOL _successfulPost = NO;
BOOL _firstTimeEditPost = YES;
RCConnectionManager *_connectionManager;

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
        [_tblViewLandmark removeFromSuperview];
    } else {
        [self asynchGetLandmarkRequest];
        [self.view addSubview:_tblViewLandmark];
        _landmarkTableVisible = YES;
    }
}

- (id) initWithUser:(RCUser *)user {
    self = [super init];
    if (self) {
        _user = user;
        _keyboardPushHandler = [[RCKeyboardPushUpHandler alloc] init];
        _connectionManager = [[RCConnectionManager alloc] init];
        self.backgroundImage = nil;
        //NSLog(@"RCNewPostViewController: %@", _keyboardPushHandler);
    }
    return self;
}

- (id) initWithUser:(RCUser *)user withBackgroundImage:(UIImage*) image{
    self = [super init];
    if (self) {
        _user = user;
        _keyboardPushHandler = [[RCKeyboardPushUpHandler alloc] init];
        _connectionManager = [[RCConnectionManager alloc] init];
        self.backgroundImage = image;
        //NSLog(@"RCNewPostViewController: %@", _keyboardPushHandler);
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
    [self.view addGestureRecognizer:_tapGestureRecognizer];
    _isTapToCloseKeyboard = NO;
    
    //prepare text view placeholder
    _firstTimeEditPost = YES;
    
    _tblViewLandmark = [[UITableView alloc] initWithFrame:CGRectMake(0, 30, 320, 200) style:UITableViewStylePlain];
    _tblViewLandmark.delegate = self;
    _tblViewLandmark.dataSource = self;
    
    _landmarks = [[NSMutableArray alloc] init];
    _landmarkTableVisible = NO;
    _currentLandmark = nil;
    
    [self animateViewAppearance];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) postNew {
    if (_postImage == nil) {
        [self showAlertMessage:@"Please choose an image!" withTitle:@"Incomplete post!"];
        return;
    }
    if (_privacyOption == nil) {
        [self showAlertMessage:@"Please choose a privacy option!" withTitle:@"Incomplete post!"];
        return;
    }
    [_connectionManager startConnection];
    _postButton.enabled = NO;
    UIImage *rescaledImage = imageWithImage(_postImage, CGSizeMake(RCUploadImageSizeWidth,RCUploadImageSizeHeight));
    NSData *imageData = UIImageJPEGRepresentation(rescaledImage, 1.0);
    [self performSelectorInBackground:@selector(uploadImageToS3:) withObject:imageData];
}

#pragma mark - upload method

- (void)uploadImageToS3:(NSData *)imageData
{
    AmazonS3Client *s3 = [RCAmazonS3Helper s3:_user.userID forResource:[NSString stringWithFormat:@"%@/*", RCAmazonS3UsersMediaBucket]];
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    _imageFileName = [(__bridge NSString*)string stringByReplacingOccurrencesOfString:@"-"withString:@""];
    // Upload image data.  Remember to set the content type.
    S3PutObjectRequest *por = [[S3PutObjectRequest alloc] initWithKey:_imageFileName
                                                             inBucket:RCAmazonS3UsersMediaBucket];
    por.contentType = @"image/jpeg";
    por.data = imageData;
    
    @try {        
        S3PutObjectResponse *putObjectResponse = [s3 putObject:por];
        if (putObjectResponse.error == nil)
        {
            [self performSelectorOnMainThread:@selector(asynchPostNewResuest) withObject:nil waitUntilDone:YES];
        } else {
            NSLog(@"Error: %@", putObjectResponse.error);
            [_connectionManager endConnection];
            _postButton.enabled = YES;
            [self showAlertMessage:putObjectResponse.error.description withTitle:@"Upload Error"];
            
        }
    }@catch (AmazonClientException *exception) {
        NSLog(@"New-Post: Error: %@", exception);
        NSLog(@"New-Post: Debug Description: %@",exception.debugDescription);
        [_connectionManager endConnection];
        _postButton.enabled = YES;
        [self showAlertMessage:exception.description withTitle:RCUploadError];
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
        _postContent = [_txtViewPostContent text];
        NSString *postSubject = [_txtFieldPostSubject text];
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        CLLocationDegrees latitude = appDelegate.currentLocation.coordinate.latitude;
        CLLocationDegrees longitude = appDelegate.currentLocation.coordinate.longitude;
        NSString* latSt = [[NSString alloc] initWithFormat:@"%f",latitude];
        NSString* longSt = [[NSString alloc] initWithFormat:@"%f",longitude];
        NSMutableString *dataSt = initQueryString(@"post[content]", _postContent);
        addArgumentToQueryString(dataSt, @"post[rating]", @"5");
        addArgumentToQueryString(dataSt, @"post[latitude]", latSt);
        addArgumentToQueryString(dataSt, @"post[longitude]", longSt);
        addArgumentToQueryString(dataSt, @"post[file_url]", _imageFileName);
        addArgumentToQueryString(dataSt, @"post[privacy_option]", _privacyOption);
        addArgumentToQueryString(dataSt, @"subject", postSubject);
        if (_currentLandmark != nil) {
            addArgumentToQueryString(dataSt, @"landmark_id", [NSString stringWithFormat:@"%d",_currentLandmark.landmarkID]);
        }
        NSData *postData = [dataSt dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        
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
                [self animateViewDisapperance:^ {
                    [self.navigationController popViewControllerAnimated:NO];
                }];
            }else {
                alertStatus([NSString stringWithFormat:@"Please try again! %@", responseData], @"Post Failed!", self);
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
                 [_landmarks removeAllObjects];
                 for (NSDictionary *landmarkJson in jsonData) {
                     RCLandmark *landmark = [[RCLandmark alloc] initWithNSDictionary:landmarkJson];
                     [_landmarks addObject:landmark];
                 }
                 [_tblViewLandmark reloadData];
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

#pragma mark - UIActionSheetDelegate

- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([actionSheet cancelButtonIndex] == buttonIndex)
        return;
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    NSString* buttonLabel = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([buttonLabel isEqualToString:RCImageSourcePhotoLibrary])
        [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    //else if ([buttonLabel isEqualToString:RCImageSourcePhotoAlbum])
    //    [imagePicker setSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
    else if ([buttonLabel isEqualToString:RCImageSourceCamera])
        [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
    [self presentViewController:imagePicker animated:YES completion:nil];
}

#pragma mark - UI events

- (IBAction)btnPostImageTouchUpInside:(id)sender {
    if ([_txtViewPostContent isFirstResponder]) {
        [_txtViewPostContent endEditing:YES];
    }
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Select where image is from"
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
        [actionSheet addButtonWithTitle:RCImageSourcePhotoLibrary];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
        [actionSheet addButtonWithTitle:RCImageSourceCamera];
    
    // This is probably not necessary
    //if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum])
    //    [actionSheet addButtonWithTitle:RCImageSourcePhotoAlbum];
    
    actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:@"Cancel"];
    [actionSheet showInView:self.view];
    
}

- (IBAction)backgroundTouchUpInside:(id)sender {
    if ([_txtFieldPostSubject isEditing])
        [_txtFieldPostSubject resignFirstResponder];
    else
        [_txtViewPostContent resignFirstResponder];
}

#pragma mark - UIImagePickerControllerDelegate methods
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    // Get the selected image.
    _postImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    [_imageViewPostPicture setImage:_postImage];
    if ([picker sourceType] == UIImagePickerControllerSourceTypeCamera)
        UIImageWriteToSavedPhotosAlbum(_postImage, self, nil, nil);
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    [UIView animateWithDuration:0.6
						  delay:0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
                         _btnCameraSource.alpha = 0.0;
                         _btnPhotoLibrarySource.alpha = 0.0;
                         _btnVideoSource.alpha = 0.0;
					 }
                     completion:^(BOOL finished) {
                         [self removePhotoSourceControlAndAddPrivacyControl];
					 }];

}

-(void) imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - code to move views up/down appropriately when keyboard is going to cover text field

- (void)viewWillAppear:(BOOL)animated
{
    _keyboardPushHandler.view = self.view;
    [_keyboardPushHandler reset];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}
#pragma mark - animate in the view
/*- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    
}*/



#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_landmarks count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *simpleTableIdentifier = @"SimpleTableItem";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    RCLandmark *landmark = [_landmarks objectAtIndex:indexPath.row];
    cell.textLabel.text = landmark.description;
    return cell;
}

/*- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [RCUserTableCell cellHeight];
}*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    RCLandmark *landmark = [_landmarks objectAtIndex:indexPath.row];
    _currentLandmark = landmark;
    [_btnLandmark setTitle:landmark.description forState:UIControlStateNormal];
    [_tblViewLandmark removeFromSuperview];
    _landmarkTableVisible = NO;
}

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
        
        [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        [_txtViewPostContent resignFirstResponder];
        [self presentViewController:imagePicker animated:YES completion:nil];
    } else {
        alertStatus(@"Photo library not available", @"Error!",nil);
    }

}

- (IBAction)btnActionChooseVideSource:(id)sender {
}

- (void) removePhotoSourceControlAndAddPrivacyControl {
    
    CGRect frame1 = CGRectMake(_imageViewPostFrame.frame.origin.x + 10,_btnVideoSource.frame.origin.y,54,59);
    CGRect frame2 = frame1, frame3 = frame1;
    frame2.origin.x = frame1.origin.x+54;
    frame3.origin.x = frame2.origin.x+54;
    _publicPrivacyButton = [[UIButton alloc] initWithFrame:frame1];
    [_publicPrivacyButton setImage:[UIImage imageNamed:@"postPublicPrivacyButton.png"] forState:UIControlStateNormal];
    _friendPrivacyButton = [[UIButton alloc] initWithFrame:frame2];
    [_friendPrivacyButton setImage:[UIImage imageNamed:@"postFriendPrivacyButton.png"] forState:UIControlStateNormal];
    _personalPrivacyButton = [[UIButton alloc] initWithFrame:frame3];
    [_personalPrivacyButton setImage:[UIImage imageNamed:@"postPersonalPrivacyButton.png"] forState:UIControlStateNormal];
    _postButton = [[UIButton alloc] initWithFrame:_btnVideoSource.frame];
    [_postButton setImage:[UIImage imageNamed:@"postPostButton-normal.png"] forState:UIControlStateNormal];
    [_btnCameraSource removeFromSuperview];
    [_btnPhotoLibrarySource removeFromSuperview];
    [_btnVideoSource removeFromSuperview];
    
    
    [_postButton addTarget:self action:@selector(postNew) forControlEvents:UIControlEventTouchUpInside];
    [_publicPrivacyButton addTarget:self action:@selector(setPostPrivacyOption:) forControlEvents:UIControlEventTouchUpInside];
    [_personalPrivacyButton addTarget:self action:@selector(setPostPrivacyOption:) forControlEvents:UIControlEventTouchUpInside];
    [_friendPrivacyButton addTarget:self action:@selector(setPostPrivacyOption:) forControlEvents:UIControlEventTouchUpInside];
    _postButton.alpha = 0.0;
    _publicPrivacyButton.alpha = 0.0;
    _personalPrivacyButton.alpha = 0.0;
    _friendPrivacyButton.alpha = 0.0;
    [self.view addSubview:_postButton];
    [self.view addSubview:_publicPrivacyButton];
    [self.view addSubview:_friendPrivacyButton];
    [self.view addSubview:_personalPrivacyButton];
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
                         //[self removePhotoSourceControlAndAddPrivacyControl];
					 }];
}

#pragma mark - tap gesture handler
-(void) handleTap:(UITapGestureRecognizer *)tapGestureRecognizer {
    if (_isTapToCloseKeyboard){
        [self backgroundTouchUpInside:tapGestureRecognizer];
        _isTapToCloseKeyboard = NO;
    }
    else {
        CGPoint point = [tapGestureRecognizer locationInView:_imageViewPostFrame];
        //CGRect frame = _imageViewPostFrame.frame;
        if (![_imageViewPostFrame pointInside:point withEvent:nil])
            [self animateViewDisapperance:^ {
                [self.navigationController popViewControllerAnimated:NO];
            }];
    }
}

#pragma mark - UITextView delegate
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    if ([textView isEqual:_txtViewPostContent]) {
        // register for keyboard notifications
        [[NSNotificationCenter defaultCenter] addObserver:_keyboardPushHandler
                                                 selector:@selector(keyboardWillShow:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:_keyboardPushHandler
                                                 selector:@selector(keyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
    }
    return YES;
}
- (void)textViewDidEndEditing:(UITextView *)textView {
    if ([textView isEqual:_txtViewPostContent]) {
        [[NSNotificationCenter defaultCenter] removeObserver:_keyboardPushHandler
                                                        name:UIKeyboardWillShowNotification
                                                      object:nil];
        
        [[NSNotificationCenter defaultCenter] removeObserver:_keyboardPushHandler
                                                        name:UIKeyboardWillHideNotification
                                                      object:nil];
    }
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    _isTapToCloseKeyboard = YES;
    if ([textView isEqual:_txtViewPostContent]) {
        // register for keyboard notifications

        if (_firstTimeEditPost )   {
            [textView setText:@""];
            _firstTimeEditPost = NO;
        }
    }
}

#pragma mark - UITextField delegate

- (void)textFieldDidBeginEditing:(UITextView *)textView {
    _isTapToCloseKeyboard = YES;
}
- (IBAction)closeBtnTouchUpInside:(id)sender {
    [self animateViewDisapperance:^ {
        [self.navigationController popViewControllerAnimated:NO];
    }];
}

#pragma mark - post privacy options
- (void) setPostPrivacyOption:(UIButton*) sender {
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
        if([button isEqual:sender]) {
            [button setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@-highlighted.png",[buttonFileNames objectAtIndex:i]]] forState:UIControlStateNormal];
        } else 
            [button setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@.png",[buttonFileNames objectAtIndex:i]]] forState:UIControlStateNormal];
        i++;
    }
}
@end
