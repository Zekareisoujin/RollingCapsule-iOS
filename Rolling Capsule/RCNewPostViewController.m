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
#import "RCNewPostViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "SBJson.h"

@interface RCNewPostViewController ()

@property (nonatomic,strong) UIImage* postImage;
@property (nonatomic,strong) NSString* postContent;

@end

@implementation RCNewPostViewController

@synthesize postImage = _postImage;
@synthesize postContent = _postContent;
@synthesize user = _user;

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
                                                                   action:@selector(asynchPostNewResuest)];
    self.navigationItem.rightBarButtonItem = rightButton;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - post web request
- (void) asynchPostNewResuest {
    AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
    _postContent = [_txtViewPostContent text];
    //Asynchronous Request
    @try {
        
        if(_postImage == nil) {
            alertStatus(@"Please choose an image", @"No image chosen!",self);
        } else {
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
                NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                
                SBJsonParser *jsonParser = [SBJsonParser new];
                NSDictionary *jsonData = (NSDictionary *) [jsonParser objectWithString:responseData error:nil];
                NSLog(@"%@",jsonData);
                
                //Temporary:
                if (jsonData != NULL) {
                    NSDictionary *userData = (NSDictionary *) [jsonData objectForKey: @"user"];
                    NSString *name = (NSString *) [userData objectForKey:@"name"];
                    alertStatus([NSString stringWithFormat:@"Welcome, %@!",name], @"Registration Success!", self);
                }else {
                    alertStatus([NSString stringWithFormat:@"Please try again! %@", responseData], @"Registration Failed!", self);
                }
            }];
            
        }
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        alertStatus(@"Registration Failed.",@"Registration Failed!",self);
    }
}

#pragma mark - UI events

- (IBAction)btnPostImageTouchUpInside:(id)sender {
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
