//
//  Util.h
//  Rolling Capsule
//
//  Created by Nguyen Phi Long Louis on 26/05/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#ifndef Rolling_Capsule_Util_h
#define Rolling_Capsule_Util_h

// temporary
#define IS_IPHONE_5 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )
#import "RCConnectionManager.h"
#import "RCConstants.h"

typedef void (^VoidBlock)();

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
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil, nil];
    
    // delegateObject is unnecessary, but lazy to refractor all the code that use this
    [alertView show];
}

static void confirmationDialog(NSString *msg, NSString *title, id delegate){
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title
                                                       message:msg
                                                      delegate:delegate
                                             cancelButtonTitle:@"Ok"
                                             otherButtonTitles:@"Cancel", nil];
    [alertView show];
}

static NSString * urlEncodeValue(NSString * string)
{
    return (NSString*)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                (CFStringRef) string,
                                                                                NULL,
                                                                                (CFStringRef) @"!*'();:@&=+$,/?%#[]",
                                                                                kCFStringEncodingUTF8));
    
}

static NSMutableString* initQueryString(NSString* key, NSString* value) {
    NSMutableString *ret = [[NSMutableString alloc]
                            initWithString:[[NSString alloc] initWithFormat:@"mobile=1&%@=%@",key,urlEncodeValue(value)]];
    return ret;
}

static NSMutableString* initEmptyQueryString() {
    NSMutableString *ret = [[NSMutableString alloc]
                        initWithString:[[NSString alloc] initWithFormat:@"mobile=1"]];
    return ret;
}

static void addArgumentToQueryString(NSMutableString *currentQueryString, NSString* key, NSString* value) {
    
    [currentQueryString appendString:[[NSString alloc] initWithFormat:@"&%@=%@",key,urlEncodeValue(value)]];
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

static UICollectionViewController* setUpRefreshControlWithCollectionViewController(
                                                                         UIViewController* superViewController,
                                                                         UICollectionView *collectionView) {
    UICollectionViewController* collectionViewController = [[UICollectionViewController alloc] initWithCollectionViewLayout:collectionView.collectionViewLayout];
    collectionViewController.collectionView = collectionView;
    [superViewController addChildViewController:collectionViewController];
    //collectionViewController. = [[UIRefreshControl alloc] init];
    return collectionViewController;
}

static UIImage *imageWithImage(UIImage*image,CGSize newSize) {
    UIGraphicsBeginImageContext( newSize );
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

static void getResourceAsynch(NSString *resourceKey, NSObject *(^parser)(NSString*), void (^processFunction)(NSObject*)) {
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@", RCServiceURL, resourceKey]];
        NSURLRequest *request = CreateHttpGetRequest(url);
        [RCConnectionManager startConnection];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             if (error == nil) {
                 NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                 NSObject* obj = parser(responseData);
                 processFunction(obj);
             }
         }];

}

static void postResourceAsync(NSString *resourceKey, NSDictionary *params, NSObject* (^parser)(NSString*), void (^processFunction)(NSObject*)) {
    NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@", RCServiceURL, resourceKey]];
    NSMutableString* dataSt = initEmptyQueryString();
    for (NSString* key in params) {
        addArgumentToQueryString(dataSt, key, [params objectForKey:key]);
    }
    NSData *postData = [dataSt dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSURLRequest *request = CreateHttpPostRequest(url, postData);
    [RCConnectionManager startConnection];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         [RCConnectionManager endConnection];
         if (error == nil) {
             NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
             NSObject* obj = parser(responseData);
             processFunction(obj);
         }
     }];
}

static void putResourceAsync(NSString *resourceKey, NSDictionary *param, NSObject (*parser)(NSString*), void (^processFunction)(NSObject*)) {
    //TODO
}

static void deleteResourceAsync(NSString *resourceKey, void (^processFunction)(BOOL)) {
    //TODO
}

struct RCMapReferencePoint {
    double longitude, lattitude, x, y;
};

static NSValue* createMapReferencePoint(double longitude, double lattitude, double refX, double refY) {
    struct RCMapReferencePoint point;
    point.lattitude = lattitude;
    point.longitude = longitude;
    point.x = refX;
    point.y = refY;
    return [NSValue valueWithBytes:&point objCType:@encode(struct RCMapReferencePoint)];
}

#endif