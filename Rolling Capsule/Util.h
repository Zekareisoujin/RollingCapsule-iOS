//
//  Util.h
//  Rolling Capsule
//
//  Created by Nguyen Phi Long Louis on 26/05/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

static NSMutableURLRequest* CreateHttpPostRequest (NSURL* url, NSData* postData) {
    NSString *plength = [NSString stringWithFormat:@"%d", [postData length]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:url
                                    cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                    timeoutInterval:15];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:plength forHTTPHeaderField:@"Content-Length"];
    //[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    return request;
}