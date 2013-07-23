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

- (id) initWithPost:(RCPost*) post {
    self = [super init];
    if (self) {
        _post = post;
        _successfulPost = NO;
    }
    return self;
}

- (void) main {
    @autoreleasepool {
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
        [RCConnectionManager endConnection];
        NSLog(@"received post data");
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
        int responseStatusCode = [httpResponse statusCode];
        if (responseStatusCode != RCHttpOkStatusCode) {
            _successfulPost = NO;
        } else _successfulPost = YES;
        
        [RCConnectionManager endConnection];
        NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"%@",responseData);
        
        //Temporary:
        
        //TODO open main news feed page
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_successfulPost) {
                alertStatus(@"Image posted successfully!" , @"Success!", nil);
            }else {
                alertStatus([NSString stringWithFormat:@"Failed posting %@, trying again later", responseData], @"Post Failed!", self);
            }
        });
        
        /*[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             
         }];*/
    }
}

@end
