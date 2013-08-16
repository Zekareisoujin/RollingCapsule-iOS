//
//  RCWebViewController.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 16/8/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCContentViewController.h"

@interface RCContentViewController ()

@end

@implementation RCContentViewController {
    UIView* _maskView;
}

@synthesize webview = _webview;
@synthesize activityIndicatorView = _activityIndicatorView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self setupBackButton];
    _webview = [[UIWebView alloc] initWithFrame:self.view.frame];
    _webview.delegate = self;
    [self.view addSubview:_webview];
	
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
}

- (void) loadURL:(NSURL*) url {
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [_webview loadRequest:requestObj];
}
- (void)webViewDidStartLoad:(UIWebView *)webView {
    _maskView = [[UIView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:_maskView];
    [self.view addSubview:_activityIndicatorView];
    _activityIndicatorView.frame = self.view.frame;
    [_maskView setBackgroundColor:[UIColor grayColor]];
    [_webview setBackgroundColor:[UIColor grayColor]];
    [_activityIndicatorView startAnimating];
}
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [_webview setBackgroundColor:[UIColor whiteColor]];
    [_activityIndicatorView stopAnimating];
    [_activityIndicatorView removeFromSuperview];
    [_maskView removeFromSuperview];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
