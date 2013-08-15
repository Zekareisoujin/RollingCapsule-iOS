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
#define eps 1e-9
//prefix RC : rolling capsule
static NSString* const RCServiceURL = @"http://localhost:5000";//@"https://rocaps.herokuapp.com";
static NSString* const RCTermsOfUseURL = @"https://rocaps.herokuapp.com/terms_of_use";
static NSString* const RCUnactivatedAccountString = @"Unactivated account";
static NSString* const RCUnactivatedWarningKey = @"unactivated_warning";
static NSString* const RCErrorMessageKey = @"error_message";
static NSString* const RCSessionsResource = @"/sessions";
static NSString* const RCUsersResource = @"/users";
static NSString* const RCPostsResource = @"/posts";
static NSString* const RCCommentsResource = @"/comments";
static NSString* const RCLandmarksResource = @"/landmarks";
static NSString* const RCFriendshipsResource = @"/friendships";
static NSString* const RCFollowsResource = @"/follows";
static NSString* const RCNotificationsResource = @"/notifications";
static NSString* const RCPostReportsResource = @"/post_reports";
static NSString* const RCMediaResource = @"/media";
static NSString* const RCFriendStatusAccepted = @"accepted";
static NSString* const RCFriendStatusPending = @"pending";
static NSString* const RCFriendStatusRequested = @"requested";
static NSString* const RCFriendStatusNull = @"null";
static NSString* const RCAmazonS3AvatarPictureBucket = @"memcap-avatar-images";
static NSString* const RCAmazonS3UsersMediaBucket = @"memcap-users-media";
static int       const RCHttpOkStatusCode = 200;
static int       const RCHttpUnauthorizedStatus = 401;
#define RCCStringAppDomain "com.foxtwo.rollingcapsules"

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
static NSString* const RCAlertMessageServerError = @"Server Error!";

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
static NSString* const RCLogStatusDefault = @"LogStatus";
static NSString* const RCLogUserDefault = @"LoggedUser";
static NSString* const RCMainFeedRowCountSetting = @"MainFeedRowCount";

//integer values
#define RCUploadImageSizeWidth  225
#define RCUploadImageSizeHeight 225
#define RCIphone5Height         568
#define RCPostPerPage           30
#define RCMaxVideoLength        30

//Displayed strings
static NSString* const RCImageSourcePhotoLibrary = @"Photo Library";
static NSString* const RCImageSourceCamera = @"Camera";
static NSString* const RCImageSourcePhotoAlbum = @"Photo Album";
static NSString* const RCFriendStatusActionUnfriend = @"Unfriend";
static NSString* const RCFriendStatusActionRequestFriend = @"Add friend";
static NSString* const RCFriendStatusActionRequestAccept = @"Accept request";
static NSString* const RCFriendStatusActionRequestSent = @"Request sent";
static NSString* const RCLoadingRelation = @"Loading relation";
static NSString* const RCDeclineRequest = @"Decline Request";
static NSString* const RCUploadError = @"UploadError";
static NSString* const RCEmailCapitalString = @"EMAIL";
static NSString* const RCPasswordCapitalString = @"PASSWORD";
static NSString* const RCMainFeedNoPostPublic = @"There is no post in this area yet. Share something!";
static NSString* const RCMainFeedNoPostFriends = @"There is no post from your friends yet. Add some new friends!";
static NSString* const RCMainFeedNoPostFollows = @"There is no post from people you follow yet. Follow some new user!";
static NSString* const RCMainFeedNoPostCommented = @"There is no new comment at the moment";

//Menu items
static NSString* const RCMenuItemMainFeed = @"Main Feeds";
static NSString* const RCMenuItemProfile = @"Profile";
static NSString* const RCMenuItemFriend = @"Friends";
static NSString* const RCMenuItemOutbox = @"Outbox";
static NSString* const RCMenuItemConcierge = @"Concierge";
static NSString* const RCMenuItemSettings = @"Settings";
static NSString* const RCMenuItemConciergeGame = @"Games";
static NSString* const RCMenuItemConciergeUtility = @"Utility";
static NSString* const RCMenuItemConciergeTravel = @"Travel";
static NSString* const RCMenuItemConciergeEmergency = @"Emergency";
static NSString* const RCMenuItemConciergeShopping = @"Shopping";
static NSString* const RCMenuItemSettingsLogOut = @"Log Out";
static NSString* const RCMenuItemSettingsFacebook = @"Facebook";

static NSString* const RCMenuKeyKeyPath = @"key";
static NSString* const RCMenuKeyIcon = @"icon";
static NSString* const RCMenuKeyIcon2 = @"icon2";
static NSString* const RCMenuKeyDisplayedName = @"displayedName";
static NSString* const RCMenuKeySelector = @"selector";
static NSString* const RCMenuKeySelectorLoad = @"selectorLoad";

//cell border color
static double const RCAppThemeColorRed = 52.0/255.0;
static double const RCAppThemeColorGreen = 178.0/255.0;
static double const RCAppThemeColorBlue = 167.0/255.0;

//cell states
#define RCCellStateNormal 0
#define RCCellStateDimmed -1
#define RCCellStateFloat 1

//topics
#define NUM_TOPICS 12
static char* __attribute__((unused)) RCTopics[] =
{"Airport","Aquarium","Movie","Mall","Shop","Restaurant","Hotel",
  "School", "Temple","Church","Tropic Of Cancer","Others"};
#endif

