//
//  RCNewPostViewController.m
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 3/6/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "Util.h"
#import "Constants.h"
#import "AppDelegate.h"
#import "RCAmazonS3Helper.h"
#import "RCNewPostViewController.h"
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
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
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
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
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
    por.delegate = self;
    
    S3PutObjectResponse *putObjectResponse = [s3 putObject:por];
    if (putObjectResponse.error == nil)
    {
        [self asynchPostNewResuest];
    } else {
        NSLog(@"Error: %@", putObjectResponse.error);
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
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
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    _postContent = [_txtViewPostContent text];
    
    //Asynchronous Request
    @try {    
        CLLocationDegrees latitude = appDelegate.currentLocation.coordinate.latitude;
        CLLocationDegrees longitude = appDelegate.currentLocation.coordinate.longitude;
        NSString* latSt = [[NSString alloc] initWithFormat:@"%f",latitude];
        NSString* longSt = [[NSString alloc] initWithFormat:@"%f",longitude];
        NSMutableString *dataSt = initQueryString(@"post[user_id]", [[NSString alloc] initWithFormat:@"%d",_user.userID]);
        addArgumentToQueryString(dataSt, @"post[content]", _postContent);
        addArgumentToQueryString(dataSt, @"post[rating]", @"5");
        addArgumentToQueryString(dataSt, @"post[latitude]", latSt);
        addArgumentToQueryString(dataSt, @"post[longitude]", longSt);
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
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            self.navigationItem.rightBarButtonItem.enabled = YES;
            
            NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"%@",responseData);
            
            //Temporary:
            if (_successfulPost) {
                //TODO open main news feed page
                [self showAlertMessage:@"Image posted successfully!" withTitle:@"Success!"];
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

#pragma mark - UI events

- (IBAction)btnPostImageTouchUpInside:(id)sender {
    if ([_txtViewPostContent isFirstResponder]) {
        [_txtViewPostContent endEditing:YES];
    }
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:nil];
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
@end
