//
//  Util.h
//  Rolling Capsule
//
//  Created by Nguyen Phi Long Louis on 26/05/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#ifndef Rolling_Capsule_Util_h
#define Rolling_Capsule_Util_h

static NSMutableURLRequest* CreateHttpPostRequest (NSURL* url, NSData* postData) {
    NSString *plength = [NSString stringWithFormat:@"%d", [postData length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:url
                                    cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                    timeoutInterval:15];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:plength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    return request;
}

static NSMutableURLRequest* CreateHttpPutRequest (NSURL* url, NSData* postData) {
    NSString *plength = [NSString stringWithFormat:@"%d", [postData length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:url
                                    cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                    timeoutInterval:15];
    
    [request setHTTPMethod:@"PUT"];
    [request setValue:plength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    return request;
}

static NSMutableURLRequest* CreateHttpGetRequest (NSURL* url) {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:url
                                    cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                    timeoutInterval:15];
    
    [request setHTTPMethod:@"GET"];
    return request;
}

static NSMutableURLRequest* CreateHttpDeleteRequest (NSURL* url) {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:url
                                    cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                    timeoutInterval:15];
    
    [request setHTTPMethod:@"DELETE"];
    return request;
}

static void alertStatus(NSString *msg, NSString *title, id delegateObject)
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:msg
                                                       delegate:delegateObject
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil, nil];
    
    [alertView show];
}

static NSMutableString* initQueryString(NSString* key, NSString* value) {
    NSMutableString *ret = [[NSMutableString alloc]
                            initWithString:[[NSString alloc] initWithFormat:@"mobile=1&%@=%@",key,value]];
    return ret;
}

static NSMutableString* initEmptyQueryString() {
    NSMutableString *ret = [[NSMutableString alloc]
                        initWithString:[[NSString alloc] initWithFormat:@"mobile=1"]];
    return ret;
}

static void addArgumentToQueryString(NSMutableString *currentQueryString, NSString* key, NSString* value) {
    [currentQueryString appendString:[[NSString alloc] initWithFormat:@"&%@=%@",key,value]];
}

static UITableViewController* setUpRefreshControlWithTableViewController(
                                                            UIViewController* superViewController,
                                                            UITableView *tableView) {
    UITableViewController* tableViewController = [[UITableViewController alloc] initWithStyle:tableView.style];
    tableViewController.tableView = tableView;
    [superViewController addChildViewController:tableViewController];
    tableViewController.refreshControl = [[UIRefreshControl alloc] init];
    return tableViewController;
}
#endif