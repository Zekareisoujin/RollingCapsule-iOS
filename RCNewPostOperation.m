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
#import "RCUser.h"
#import "RCUploadTask.h"

@implementation RCNewPostOperation

@synthesize  post = _post;
@synthesize successfulPost = _successfulPost;
@synthesize mediaUploadOperation = _mediaUploadOperation;
@synthesize paused = _paused;

- (id) initWithPost:(RCPost*) post withMediaUploadOperation:(RCMediaUploadOperation*) mediaUploadOperation {
    self = [super init];
    if (self) {
        self.post = post;
        _successfulPost = NO;
        _mediaUploadOperation = mediaUploadOperation;
        self.paused = NO;
    }
    [self addDependency:_mediaUploadOperation];
    [self setQueuePriority:NSOperationQueuePriorityHigh];
    return self;
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
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZZ"];
        if (_post.releaseDate != nil) {
            addArgumentToQueryString(dataSt, @"post[release]", [dateFormatter stringFromDate:_post.releaseDate ]);
        }
        if (_post.postedTime != nil) {
            addArgumentToQueryString(dataSt, @"post[posted_at]", [dateFormatter stringFromDate:_post.postedTime ]);
        }
        NSData *postData = [dataSt dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
        
        NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@", RCServiceURL, RCPostsResource]];
        
        NSURLRequest *request = CreateHttpPostRequest(url, postData);
        NSURLResponse *response = nil;
        NSError *error = nil;
        NSLog(@"before sending post data");
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        NSLog(@"successful data");
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
                postNotification(NSLocalizedString(@"Media posted successfully!", nil));
            }
        });
        
        /*[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             
         }];*/
    }
}

- (void) writeOperationToCoreDataAsUploadTask {
    NSLog(@"writing to core data");
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate] ;
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSManagedObject *uploadTask = [NSEntityDescription
                                   insertNewObjectForEntityForName:@"RCUploadTask"
                                   inManagedObjectContext:context];
    RCPost* post = self.post;
    [uploadTask setValue:[NSNumber numberWithInt:[RCUser currentUser].userID] forKey:@"userID"];
    [uploadTask setValue:post.fileUrl forKey:@"key"];
    [uploadTask setValue:[self.mediaUploadOperation.fileURL absoluteString] forKey:@"fileURL"];
    [uploadTask setValue:post.content forKey:@"content"];
    [uploadTask setValue:[NSNumber numberWithDouble:post.latitude] forKey:@"latitude"];
    [uploadTask setValue:[NSNumber numberWithDouble:post.longitude] forKey:@"longitude"];
    [uploadTask setValue:post.postedTime forKey:@"postedTime"];
    [uploadTask setValue:post.privacyOption forKey:@"privacyOption"];
    [uploadTask setValue:post.subject forKey:@"subject"];
    
    if (post.releaseDate != nil)
        [uploadTask setValue:post.releaseDate forKey:@"releaseDate"];
    if (post.topic != nil)
        [uploadTask setValue:post.topic forKey:@"topic"];
    NSLog(@"before saving to coredata");
    NSError *error;
    if (![context save:&error]) {
        NSLog(@"CoreData, couldn't save: %@", [error localizedDescription]);
    }
    NSLog(@"finished saving to coredata");

}

@end
