//
//  RCPost.m
//  Rolling Capsule
//
//  Created by Nguyen Phi Long Louis on 31/05/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCPost.h"
#import "RCConstants.h"
#import "RCUtilities.h"
#import "RCAmazonS3Helper.h"
#import "RCResourceCache.h"
#import "RCOperationsManager.h"
#import "SBJson.h"

@interface RCPost ()
@property (nonatomic,strong) NSObject* objUIUpdate;
@property (nonatomic,assign) SEL       selUIUPdate;
@end

@implementation RCPost

@synthesize content = _content;
@synthesize createdTime = _createdTime;
@synthesize updatedTime = _updatedTime;
@synthesize fileUrl = _fileUrl;
@synthesize privacyOption = _privacyOption;
@synthesize likeCount = _likeCount;
@synthesize viewCount = _viewCount;
@synthesize longitude = _longitude;
@synthesize latitude = _latitude;
@synthesize postID = _postID;
@synthesize userID = _userID;
@synthesize authorName = _authorName;
@synthesize authorEmail = _authorEmail;
@synthesize landmarkID = _landmarkID;
@synthesize subject = _subject;
@synthesize thumbnailUrl = _thumbnailUrl;
@synthesize releaseDate = _releaseDate;
@synthesize isTimeCapsule = _isTimeCapsule;
@synthesize thumbnailImage = _thumbnailImage;
@synthesize topic = _topic;
@synthesize objUIUpdate = _objUIUpdate;
@synthesize selUIUPdate = _selUIUPdate;
@synthesize postedTime = _postedTime;

static NSMutableDictionary* RCPostPostCollection = nil;

+ (void) initPostDataModel {
    RCPostPostCollection = [[NSMutableDictionary alloc] init];
}

+ (id) getPostWithID:(int)postID {
    RCPost* cachedPost = [RCPostPostCollection objectForKey:[NSNumber numberWithInt:postID]];
    if (cachedPost != nil)
        return cachedPost;
    else {
        RCPost* post = [[RCPost alloc] init];
        post.postID = postID;
        return post;
    }
}

+ (void) addPostToCollection:(RCPost*) post {
    [RCPostPostCollection setObject:post forKey:[NSNumber numberWithInt:post.postID]];
}

+ (id) getPostWithNSDictionary:(NSDictionary *)postData {
    int newID = [[postData objectForKey:@"id"] intValue];
    RCPost* cachedPost = [RCPostPostCollection objectForKey:[NSNumber numberWithInt:newID]];
    if (cachedPost != nil) {
        NSLog(@"cached post class:%@",[cachedPost class]);
        if (cachedPost.isTimeCapsule && [cachedPost.releaseDate compare:[NSDate date]] != NSOrderedDescending) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
            [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
            NSDate* newUpdatedTime = [formatter dateFromString:(NSString*)[postData objectForKey:@"updated_at"]];
            
            if ([newUpdatedTime compare:cachedPost.updatedTime] != NSOrderedDescending)
                return cachedPost;
        }
    }
    
    RCPost *newPost = [[RCPost alloc] initWithNSDictionary:postData];
    [RCPost addPostToCollection:newPost];
    return newPost;
}

- (id) initWithNSDictionary:(NSDictionary *)postData {
    self = [super init];
    if (self) {
        _thumbnailImage = nil;
        _postID = [[postData objectForKey:@"id"] intValue];
        _topic = [postData objectForKey:@"topic"];
        if ([_topic isKindOfClass:[NSNull class]])
            _topic = nil;
        _fileUrl = (NSString*)[postData objectForKey:@"file_url"];
        _privacyOption = (NSString*)[postData objectForKey:@"privacy_option"];
        _likeCount = [[postData objectForKey:@"like_count"] intValue];
        _viewCount = [[postData objectForKey:@"view_count"] intValue];
        _longitude = [[postData objectForKey:@"longitude"] doubleValue];
        _latitude = [[postData objectForKey:@"latitude"] doubleValue];
        
        _userID = [[postData objectForKey:@"user_id"] intValue];
        id landmarkObj = [postData objectForKey:@"landmark_id"];
        if ([landmarkObj isKindOfClass:[NSNumber class]]) {
            _landmarkID = [[postData objectForKey:@"landmark_id"] intValue];
        } else
            _landmarkID = -1;
        _authorName = [postData objectForKey:@"author_name"];
        _authorEmail = [postData objectForKey:@"author_email"];
        _thumbnailUrl = [postData objectForKey:@"thumbnail_url"];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        _createdTime = [formatter dateFromString:(NSString*)[postData objectForKey:@"created_at"]];
        _updatedTime = [formatter dateFromString:(NSString*)[postData objectForKey:@"updated_at"]];
        NSObject* postedTimeObj = [postData objectForKey:@"updated_at"];
        if ([postedTimeObj isKindOfClass:[NSString class]] )
            _postedTime = [formatter dateFromString:(NSString*)postedTimeObj];
        else
            _postedTime = nil;
        NSString *releaseTime = [postData objectForKey:@"release"];
        if ((NSNull*)releaseTime == [NSNull null]){
            _isTimeCapsule = NO;
        }else {
            _isTimeCapsule = YES;
            _releaseDate = [formatter dateFromString:releaseTime];
        }
        
        _subject = (NSString*)[postData objectForKey:@"subject"];
        if ([_subject isKindOfClass:[NSNull class]])
            _subject = @"";
        _content = (NSString*)[postData objectForKey:@"content"];
        if ([_content isKindOfClass:[NSNull class]] || [_content isEqualToString:@""]) {
            if ([_subject isEqualToString:@""]) {
                [formatter setTimeZone:[NSTimeZone localTimeZone]];
                [formatter setDateFormat:@"yyyy-MM-dd' 'HH:mm:ss' '"];
                _content = [NSString stringWithFormat:@"Posted on %@", [formatter stringFromDate:_postedTime]];
            } else {
                _content = _subject;
            }
        }
    }
    
    _thumbnailImage = [[RCResourceCache centralCache] getResourceForKey:[NSString stringWithFormat:@"media/%@", _thumbnailUrl]];
    if (_thumbnailImage == nil) {
        RCPhotoDownloadOperation *op = [[RCPhotoDownloadOperation alloc] initWithPhotokey:self.thumbnailUrl];
        [op setCompletionHandler:^(UIImage* img){
            [self updateThumbnailImage:img];
        }];
        [RCOperationsManager addOperation:op];
    }
    
    return self;
}

//- (void) getThumbnailImageAsync:(int)viewingUserID completion:(void (^)(UIImage *))completionHandle {
//    RCResourceCache *cache = [RCResourceCache centralCache];
//    NSString *key = [NSString stringWithFormat:@"%@/%d-thumbnail", RCPostsResource, _postID];
//    dispatch_queue_t queue = dispatch_queue_create(RCCStringAppDomain, NULL);
//    dispatch_async(queue, ^{
//        RCUser *owner = [[RCUser alloc] init];
//        owner.userID = post.userID;
//        owner.email = post.authorEmail;
//        owner.name = post.authorName;
//        UIImage* cachedImg = (UIImage*)[cache getResourceForKey:key usingQuery:^{
//            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
//            UIImage *image = [RCAmazonS3Helper getUserMediaImage:owner withLoggedinUserID:user.userID withImageUrl:post.thumbnailUrl];
//            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
//            NSLog(@"downloading images");
//
//            return image;
//        }];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            if (cachedImg != nil)
//                [_imageView setImage:cachedImg];
//            callback();
//        });
//    });
//}

- (NSString *)title {
    return [self.subject length] > 0 ? self.subject : @"Here";
}

- (NSString *)subtitle {
    return self.content;
}

- (CLLocationCoordinate2D)coordinate {
    CLLocationCoordinate2D _theCoordinate;
    _theCoordinate.latitude = _latitude;
    _theCoordinate.longitude = _longitude;
    return _theCoordinate;
}

- (MKMapItem*)mapItem {
    NSDictionary *addressDict = @{@"address" : @"address"};
    
    MKPlacemark *placemark = [[MKPlacemark alloc]
                              initWithCoordinate:self.coordinate
                              addressDictionary:addressDict];
    
    MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
    mapItem.name = @"yo";
    
    return mapItem;
}
- (void)updateThumbnailImage:(UIImage *)img {
    _thumbnailImage = img;
    dispatch_async(dispatch_get_main_queue(), ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [_objUIUpdate performSelector:_selUIUPdate withObject:self];
#pragma clang diagnostic pop
    });
}
- (void) registerUIUpdateAction:(NSObject*)target action:(SEL)sel {
    _objUIUpdate = target;
    _selUIUPdate = sel;
}

- (void)updatePostTopic:(NSString*)topic completionHandler:(void(^)(NSString*))completionHandle {
    
    
    NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@/%d?mobile=1", RCServiceURL, RCPostsResource, _postID]];
    NSMutableString* dataSt = initQueryString(@"post[topic]", topic);
    NSData *postData = [dataSt dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSURLRequest *request = CreateHttpPutRequest(url, postData);
    [RCConnectionManager startConnection];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         [RCConnectionManager endConnection];
         if (error == nil) {
             NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
             
             if ([responseData isEqualToString:@"ok"])
                 completionHandle(nil);
             else
                 completionHandle(@"Server error, please try again later");
             
         } else
             completionHandle(RCAlertMessageConnectionFailed);
     }];
}
@end
