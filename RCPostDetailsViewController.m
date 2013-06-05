//
//  RCPostDetailsViewController.m
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 5/6/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "Constants.h"
#import "RCPostDetailsViewController.h"
#import "RCAmazonS3Helper.h"

@interface RCPostDetailsViewController ()

@end

@implementation RCPostDetailsViewController

@synthesize post = _post;
@synthesize postOwner = _postOwner;
@synthesize loggedInUser = _loggedInUser;

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
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self getPostImageFromInternet];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - web request
-(void) getPostImageFromInternet {
    dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
    dispatch_async(queue, ^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        UIImage *image = [RCAmazonS3Helper getUserMediaImage:_postOwner withLoggedinUserID:_loggedInUser.userID   withImageUrl:_post.fileUrl];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if (image != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_imgViewPostImage setImage:image];
            });
        }
    });
}

@end
