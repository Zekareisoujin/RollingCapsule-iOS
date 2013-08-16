//
//  RCWebViewController.h
//  memcap
//
//  Created by Trinh Tuan Phuong on 16/8/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewController+RCCustomBackButtonViewController.h"

@interface RCContentViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, strong) UIWebView* webview;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
- (void) loadURL:(NSURL*) url;
@end
