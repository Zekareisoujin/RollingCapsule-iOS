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

@end

@implementation RCNewPostViewController

@synthesize postImage = _postImage;
@synthesize postContent = _postContent;
@synthesize imageFileName = _imageFileName;
@synthesize user = _user;

BOOL _successfulPost = NO;
RCKeyboardPushUpHandler *_keyboardPushHandler;
RCConnectionManager *_connectionManager;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    [_connectionManager reset];
    [_keyboardPushHandler reset];
    _keyboardPushHandler.view = self.view;
    
    [[_txtViewPostContent layer] setBorderColor:[[UIColor grayColor] CGColor]];
    [[_txtViewPostContent layer] setBorderWidth:2.3];
    [[_txtViewPostContent layer] setCornerRadius:15];
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Post"
                                                                    style:UIBarButtonItemStyleDone
                                                                   target:self
                                                                   action:@selector(postNew)];
    self.navigationItem.rightBarButtonItem = rightButton;
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
    [_connectionManager startConnection];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    NSData *imageData = UIImageJPEGRepresentation(_postImage, 1.0);
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
    //por.delegate = self;
    
    S3PutObjectResponse *putObjectResponse = [s3 putObject:por];
    if (putObjectResponse.error == nil)
    {
        [self performSelectorOnMainThread:@selector(asynchPostNewResuest) withObject:nil waitUntilDone:YES];
    } else {
        NSLog(@"Error: %@", putObjectResponse.error);
        [_connectionManager endConnection];
        self.navigationItem.rightBarButtonItem.enabled = YES;
        [self showAlertMessage:putObjectResponse.error.description withTitle:@"Upload Error"];
        
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
        AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
        CLLocationDegrees latitude = appDelegate.currentLocation.coordinate.latitude;
        CLLocationDegrees longitude = appDelegate.currentLocation.coordinate.longitude;
        NSString* latSt = [[NSString alloc] initWithFormat:@"%f",latitude];
        NSString* longSt = [[NSString alloc] initWithFormat:@"%f",longitude];
        NSMutableString *dataSt = initQueryString(@"post[user_id]", [[NSString alloc] initWithFormat:@"%d",_user.userID]);
        addArgumentToQueryString(dataSt, @"post[content]", _postContent);
        addArgumentToQueryString(dataSt, @"post[rating]", @"5");
        addArgumentToQueryString(dataSt, @"post[latitude]", latSt);
        addArgumentToQueryString(dataSt, @"post[longitude]", longSt);
        addArgumentToQueryString(dataSt, @"post[file_url]", _imageFileName);
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
            self.navigationItem.rightBarButtonItem.enabled = YES;
            
            NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"%@",responseData);
            
            //Temporary:
            if (_successfulPost) {
                //TODO open main news feed page
                [self showAlertMessage:@"Image posted successfully!" withTitle:@"Success!"];
                [self.navigationController popViewControllerAnimated:YES];
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
    else if ([buttonLabel isEqualToString:RCImageSourcePhotoAlbum])
        [imagePicker setSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
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
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum])
        [actionSheet addButtonWithTitle:RCImageSourcePhotoAlbum];
    
    actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:@"Cancel"];
    [actionSheet showInView:self.view];
    
}

- (IBAction)backgroundTouchUpInside:(id)sender {
    [_txtViewPostContent resignFirstResponder];
}

#pragma mark - UIImageControllerDelegate methods
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    // Get the selected image.
    _postImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    [_btnPostImage setImage:_postImage forState:UIControlStateNormal];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

-(void) imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
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
@end
