//
//  RCNewPostOperation.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 24/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCNewPostOperation.h"
#import "RCConstants.h"
#import "RCUtilities.h"

@implementation RCNewPostOperation

@synthesize  post = _post;
@synthesize successfulPost = _successfulPost;
@synthesize mediaUploadOperation = _mediaUploadOperation;

- (id) initWithPost:(RCPost*) post withMediaUploadOperation:(RCMediaUploadOperation*) mediaUploadOperation {
    self = [super init];
    if (self) {
        _post = post;
        _successfulPost = NO;
        _mediaUploadOperation = mediaUploadOperation;
    }
    [self addDependency:_mediaUploadOperation];
    return self;
}

- (RCNewPostOperation*) generateRetryOperation {
    RCNewPostOperation *retry;
    if (_mediaUploadOperation.successfulUpload)
        retry = [[RCNewPostOperation alloc] initWithPost:_post withMediaUploadOperation:_mediaUploadOperation ];
    else {
        RCMediaUploadOperation *mediaUploadRetry = [[RCMediaUploadOperation alloc] initWithKey:_mediaUploadOperation.key withUploadData:_mediaUploadOperation.uploadData withThumbnail:_mediaUploadOperation.thumbnailImage withMediaType:_mediaUploadOperation.mediaType];
        retry = [[RCNewPostOperation alloc] initWithPost:_post withMediaUploadOperation:mediaUploadRetry ];
    }
    return retry;
}

- (void) main {
    @autoreleasepool {
        if (!_mediaUploadOperation.successfulUpload)
            return;
        NSMutableString *dataSt = initQueryString(@"post[content]", _post.content);
        NSString* latSt = [NSString stringWithFormat:@"%f",_post.latitude];
        NSString* longSt = [NSString stringWithFormat:@"%f",_post.longitude];
        addArgumentToQueryString(dataSt, @"post[rating]", @"5");
        addArgumentToQueryString(dataSt, @"post[latitude]", latSt);
        addArgumentToQueryString(dataSt, @"post[longitude]", longSt);
        addArgumentToQueryString(dataSt, @"post[file_url]", _post.fileUrl);
        addArgumentToQueryString(dataSt, @"post[privacy_option]", _post.privacyOption);
        addArgumentToQueryString(dataSt, @"post[thumbnail_url]", _post.thumbnailUrl);
        addArgumentToQueryString(dataSt, @"post[subject]", _post.subject);
        if (_post.topic != nil)
            addArgumentToQueryString(dataSt, @"post[topic]", _post.topic);
        if (_post.releaseDate != nil) {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZZ"];
            addArgumentToQueryString(dataSt, @"post[release]", [dateFormatter stringFromDate:_post.releaseDate ]);
        }
        NSData *postData = [dataSt dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
        
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@", RCServiceURL, RCPostsResource]];
        
        NSURLRequest *request = CreateHttpPostRequest(url, postData);
        NSURLResponse *response;
        NSError *error = nil;
        [RCConnectionManager startConnection];
        NSLog(@"before sending post data");
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        NSLog(@"received post data");
        [RCConnectionManager endConnection];
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
        int responseStatusCode = [httpResponse statusCode];
        if (responseStatusCode != RCHttpOkStatusCode) {
            _successfulPost = NO;
        } else _successfulPost = YES;
        
        NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"%@",responseData);
        
        //Temporary:
        
        //TODO open main news feed page
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_successfulPost) {
                alertStatus(@"Media posted successfully!" , @"Success!", nil);
            }
        });
        
        /*[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             
         }];*/
    }
}

@end
