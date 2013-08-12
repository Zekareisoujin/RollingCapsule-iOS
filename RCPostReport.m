//
//  RCPostReport.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 13/8/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCPostReport.h"
#import "RCConstants.h"
#import "RCUtilities.h"
#import "RCPost.h"

@implementation RCPostReport

+ (void) postReportCategory:(NSString*) category withReason:(NSString*) reason forPost:(RCPost*) post withSuccessHandler:(VoidBlock) successHandler withFailureHandler:(void(^)(NSString*)) failureHandler {
    @try {
    NSURL *url=[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", RCServiceURL, RCPostReportsResource]];
    NSMutableString *dataSt = initQueryString(@"post_report[reason]", reason);
    addArgumentToQueryString(dataSt, @"post_report[category]", category);
    addArgumentToQueryString(dataSt, @"post_id", [NSString stringWithFormat:@"%d",post.postID]);
    NSData *postData = [dataSt dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    NSURLRequest *request = CreateHttpPostRequest(url,postData);
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
         NSLog(@"post new report received response data:%@", responseData);
         if ([responseData isEqualToString:@"ok"]) {
             successHandler();
         } else  if (error == nil) {
             failureHandler(responseData);
         } else {
             NSLog(@"exception : %@", [error localizedDescription]);
             failureHandler(@"we could not connect to server");
         }
     }];
    }@catch (NSException* exception) {
        NSLog(@"exception : %@", exception.description);
        failureHandler(@"we could not connect to server");
    }
}

@end
