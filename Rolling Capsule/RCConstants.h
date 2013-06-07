//
//  Header.h
//  Rolling Capsule
//
//  Created by Nguyen Phi Long Louis on 25/05/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#ifndef Rolling_Capsule_Constants_h
#define Rolling_Capsule_Constants_h

//prefix RC : rolling capsule
static NSString* const RCServiceURL = @"https://shielded-fortress-7112.herokuapp.com";
static NSString* const RCSessionsResource = @"/sessions";
static NSString* const RCUsersResource = @"/users";
static NSString* const RCPostsResource = @"/posts";
static NSString* const RCCommentsResource = @"/comments";
static NSString* const RCFriendshipsResource = @"/friendships";
static NSString* const RCFriendStatusAccepted = @"accepted";
static NSString* const RCFriendStatusPending = @"pending";
static NSString* const RCFriendStatusRequested = @"requested";
static NSString* const RCFriendStatusNull = @"null";
static NSString* const RCAmazonS3AvatarPictureBucket = @"rcavatarimages";
static NSString* const RCAmazonS3UsersMediaBucket = @"rcusersmedia";
static NSString* const RCImageSourcePhotoLibrary = @"Photo Library";
static NSString* const RCImageSourceCamera = @"Camera";
static NSString* const RCImageSourcePhotoAlbum = @"Photo Album";
static int       const RCHttpOkStatusCode = 200;
static const char* RCCStringAppDomain = "com.foxtwo.rollingcapsules";
#endif
