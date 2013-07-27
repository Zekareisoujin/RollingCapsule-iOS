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
#import "NSTimer+BlocksKit.h"

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

static void postNotification(NSString *msg)
{
    NSLog(@"creating alert message");
    UILabel *lblAlert = nil;
    if (lblAlert == nil)
        lblAlert = [[UILabel alloc] init];
    lblAlert.text = msg;
    lblAlert.textAlignment = NSTextAlignmentCenter;
    lblAlert.textColor = [UIColor whiteColor];
    lblAlert.backgroundColor = [UIColor colorWithRed:50.0/255.0 green:200.0/255.0 blue:50.0/255.0 alpha:0.9];
    lblAlert.adjustsFontSizeToFitWidth = YES;
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    UINavigationController *navigationController = appDelegate.navigationController;
    [navigationController.view addSubview:lblAlert];
    lblAlert.frame = CGRectMake(0,42,navigationController.view.frame.size.width,0);
    [UIView animateWithDuration:0.5 animations:^{
        CGRect frame2 = lblAlert.frame;
        frame2.size.height += 20;
        lblAlert.frame = frame2;
    }];
    [NSTimer scheduledTimerWithTimeInterval:2.0 block:^(NSTimeInterval time) {
            [UIView animateWithDuration:0.5 animations:^{
                lblAlert.alpha = 0.0;
            } completion:^(BOOL finished){
                NSLog(@"removing alert from superview");
                [lblAlert removeFromSuperview];
                NSLog(@"done removing alert from superview");
            }];
    } repeats:NO];
}

// Alert is different from notification for the fact that it requires user's acknowledgement
static void showAlertDialog(NSString *msg, NSString *title){
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:msg
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil, nil];
    [alertView show];
}

static void showConfirmationDialog(NSString *msg, NSString *title, id delegate){
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
static UIImage* generateSquareImageThumbnail(UIImage* largeImage) {
    CGFloat squareSize = MIN(largeImage.size.width, largeImage.size.height);
    CGFloat x,y;
    //largeImage.size.
    if (squareSize == largeImage.size.width) {
        x = 0;
        y = (largeImage.size.height - squareSize)/2.0;
    } else {
        y = 0;
        x = (largeImage.size.width  - squareSize)/2.0;
    }
    NSLog(@"crop coordinates x=%f y=%f size=%f",x,y,squareSize);
    CGRect cropRect = CGRectMake(0,0,squareSize,squareSize);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([largeImage CGImage], cropRect);
    // or use the UIImage wherever you like
    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef scale:largeImage.scale orientation:largeImage.imageOrientation];
    CGImageRelease(imageRef);
    return croppedImage;
}

static UIImage* resizeImageIfTooBig(UIImage *image) {
    if (image.size.width > 800 && image.size.height > 800) {
        float division = MIN(image.size.width/(800.0-1.0), image.size.height/(800-1.0));
        UIImage *rescaledPostImage = imageWithImage(image, CGSizeMake(image.size.width/division,image.size.height/division));
        return rescaledPostImage;
    }
    return image;
}
#import <AVFoundation/AVFoundation.h>

static UIImage* generateVideoThumbnail(NSURL *videoURL) {
    AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    CMTime duration = sourceAsset.duration;
    AVAssetImageGenerator* generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:sourceAsset];
    generator.appliesPreferredTrackTransform = YES;
    //Get the 1st frame 3 seconds in
    int frameTimeStart = (int)(CMTimeGetSeconds(duration) / 2.0);
    int frameLocation = 1;
    //Snatch a frame
    CGImageRef frameRef = [generator copyCGImageAtTime:CMTimeMake(frameTimeStart,frameLocation) actualTime:nil error:nil];
    return [UIImage imageWithCGImage:frameRef];
}

#import <AssetsLibrary/AssetsLibrary.h>

static void generateThumbnailImage (NSURL *fileURL, NSString *mediaType, void(^imageProcessBlock)(UIImage*) ) {
    /*if ([mediaType hasSuffix:@"mov"]) {
        UIImage *image;
        image = generateVideoThumbnail(fileURL);
        image = generateSquareImageThumbnail(image);
        image = imageWithImage(image, CGSizeMake(RCUploadImageSizeWidth,RCUploadImageSizeHeight));
        imageProcessBlock(image);
    } else {*/
        ALAssetsLibrary *assetLibrary=[[ALAssetsLibrary alloc] init];
        [assetLibrary assetForURL:fileURL resultBlock:^(ALAsset *asset){
            UIImage *image = [UIImage imageWithCGImage:[asset thumbnail]];
            /*// Retrieve the image orientation from the ALAsset
            UIImageOrientation orientation = UIImageOrientationUp;
            NSNumber* orientationValue = [asset valueForProperty:@"ALAssetPropertyOrientation"];
            if (orientationValue != nil) {
                orientation = [orientationValue intValue];
            }
            UIImage *image = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullResolutionImage] scale:1.0 orientation:orientation];
            image = generateSquareImageThumbnail(image);
            image = imageWithImage(image, CGSizeMake(RCUploadImageSizeWidth,RCUploadImageSizeHeight));*/
            imageProcessBlock(image);
        } failureBlock:^(NSError *err){
            imageProcessBlock(nil);
        }];
    //}
}
#endif