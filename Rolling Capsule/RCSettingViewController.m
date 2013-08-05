//
//  RCSettingViewController.m
//  memcap
//
//  Created by Nguyen Phi Long Louis on 18/07/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCSettingViewController.h"
#import "RCOperationsManager.h"
#import "RCNewPostViewController.h"
#import "RCPostDetailsViewController.h"
#import "RCUtilities.h"
#import "RCConstants.h"

@interface RCSettingViewController ()

@end

@implementation RCSettingViewController

@synthesize user = _user;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithUser:(RCUser *)user
{
    self = [super init];
    if (self){
        _user = user;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnActionLogOut:(id)sender {
    [self asynchLogOutRequest];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:RCLogStatusDefault];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:RCLogUserDefault];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.navigationController popToRootViewControllerAnimated:YES];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate disableSideMenu];
}

- (IBAction)switchSaveToDiskValueChanged:(id)sender {
    RCUploadManager* defaultUM = [RCOperationsManager defaultUploadManager];
    defaultUM.willWriteToCoreData = !defaultUM.willWriteToCoreData;
}

- (IBAction)siwtchClosePostViewValueChanged:(id)sender {
    //NSLog(@"%d", _switchClosePostView.on);
    [RCNewPostViewController toggleAutomaticClose];
}

- (IBAction)switchShowPostIDValueChanged:(id)sender {
    [RCPostDetailsViewController toggleShowPostID];
}

- (void)asynchLogOutRequest
{
    //Asynchronous Request
    @try {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@", RCServiceURL, RCSessionsResource]];
        NSURLRequest *request = CreateHttpDeleteRequest(url);
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
         }];
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        postNotification(@"Log Out Failed.");
    }
}

@end
