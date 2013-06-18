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
#import "RCLandmark.h"

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
@synthesize landmarks = _landmarks;
@synthesize tblViewLandmark = _tblViewLandmark;

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

- (IBAction)callLandmarkTable:(id)sender {
    [self asynchGetLandmarkRequest];
    [self.view addSubview:_tblViewLandmark];
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
    
    _tblViewLandmark = [[UITableView alloc] initWithFrame:CGRectMake(0, 30, 320, 200) style:UITableViewStylePlain];
    _tblViewLandmark.delegate = self;
    _tblViewLandmark.dataSource = self;
    
    _landmarks = [[NSMutableArray alloc] init];
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
    UIImage *rescaledImage = imageWithImage(_postImage, CGSizeMake(300,300));
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
    
    //RCUserProfileViewController *detailViewController = [[RCUserProfileViewController alloc] initWithUser:user viewingUser:_user];
    //[self.navigationController pushViewController:detailViewController animated:YES];
}

@end
