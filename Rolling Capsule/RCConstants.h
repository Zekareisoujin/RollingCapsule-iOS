//
//  Header.h
//  Rolling Capsule
//
//  Created by Nguyen Phi Long Louis on 25/05/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#ifndef Rolling_Capsule_Constants_h
#define Rolling_Capsule_Constants_h

#define METERS_PER_MILE 1609.344

//prefix RC : rolling capsule
static NSString* const RCServiceURL = @"https://rocaps.herokuapp.com";
static NSString* const RCSessionsResource = @"/sessions";
static NSString* const RCUsersResource = @"/users";
static NSString* const RCPostsResource = @"/posts";
static NSString* const RCCommentsResource = @"/comments";
static NSString* const RCLandmarksResource = @"/landmarks";
static NSString* const RCFriendshipsResource = @"/friendships";
static NSString* const RCFriendStatusAccepted = @"accepted";
static NSString* const RCFriendStatusPending = @"pending";
static NSString* const RCFriendStatusRequested = @"requested";
static NSString* const RCFriendStatusNull = @"null";
static NSString* const RCAmazonS3AvatarPictureBucket = @"rcavatarimages";
static NSString* const RCAmazonS3UsersMediaBucket = @"rcusersmedia";
static int       const RCHttpOkStatusCode = 200;
static const char* RCCStringAppDomain = "com.foxtwo.rollingcapsules";

//query string for web request to indicate needed levels
static NSString* const RCLevelsQueryString = @"levels%5B%5D%5Bdist%5D=2000&levels%5B%5D%5Bpopularity%5D=-1&levels%5B%5D%5Bdist%5D=10000&levels%5B%5D%5Bpopularity%5D=100";

//info strings
static NSString* const RCInfoStringLastUpdatedOnFormat = @"Last updated on %@";
static NSString* const RCInfoStringDateFormat          = @"dd-MMM, hh:mm:ssa";
static NSString* const RCInfoStringPostSuccess          = @"The image was successfully uploaded.";

//alert strings
static NSString* const RCAlertMessageLoginFailed = @"Login Failed!";
static NSString* const RCAlertMessageLoginSuccess = @"Login Success!";
static NSString* const RCAlertMessageRegistrationFailed = @"Registration Failed!";
static NSString* const RCAlertMessageRegistrationSuccess = @"Registration Success!";
static NSString* const RCAlertMessageConnectionFailed = @"Connection Failed!";
static NSString* const RCAlertMessageUploadError = @"Upload Error!";
static NSString* const RCAlertMessageUploadSuccess = @"Upload Success!";

//error strings
static NSString* const RCErrorMessageUsernameAndPasswordMissing = @"Please enter both Username and Password";
static NSString* const RCErrorMessagePleaseTryAgain = @"Please try again!";
static NSString* const RCErrorMessageInformationMissing = @"Please enter all needed information";
static NSString* const RCErrorMessageFailedToGetFeed = @"Failed to obtain feed, please try again!";
static NSString* const RCErrorMessageFailedToGetFriends = @"Failed getting friends from web service, please try again!";
static NSString* const RCErrorMessageFailedToGetUsers = @"Failed to obtain user list, please try again!";
static NSString* const RCErrorMessageFailedToGetUsersRelation = @"Failed getting user's relation from web service";
static NSString* const RCErrorMessageFailedToEditFriendStatus = @"Failure editing friend status from web service, please try again!";

//NSUserDefault key
static NSString* const RCLogStatusDefault = @"logStatus";

//Displayed strings
static NSString* const RCImageSourcePhotoLibrary = @"Photo Library";
static NSString* const RCImageSourceCamera = @"Camera";
static NSString* const RCImageSourcePhotoAlbum = @"Photo Album";
static NSString* const RCFriendStatusActionUnfriend = @"Unfriend";
static NSString* const RCFriendStatusActionRequestFriend = @"Add friend";
static NSString* const RCFriendStatusActionRequestAccept = @"Accept request";
static NSString* const RCFriendStatusActionRequestSent = @"Request sent";

#endif

