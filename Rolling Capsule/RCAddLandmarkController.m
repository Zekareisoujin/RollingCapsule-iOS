//
//  RCAddLandmarkController.m
//  memcap
//
//  Created by Nguyen Phi Long Louis on 15/07/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCAddLandmarkController.h"
#import "RCLandmarkCell.h"
#import "RCConstants.h"
#import "RCUtilities.h"

@interface RCAddLandmarkController ()

@end

@implementation RCAddLandmarkController

@synthesize tblViewLandmark = _tblViewLandmark;
@synthesize viewLandmark = _viewLandmark;

NSArray *landmarkCategory;
BOOL    didPickedCategory;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // back button
    if ([self.navigationController.viewControllers count] > 2){
        [self setupBackButton];
    }
    
    // post button
    UIImage *buttonImage = [UIImage imageNamed:@"profileBtnFriendAction"];
    UIButton *postButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [postButton setFrame:CGRectMake(0,0,buttonImage.size.width, buttonImage.size.height)];
    [postButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [postButton addTarget:self action:@selector(asynchCreateLandmark) forControlEvents:UIControlEventTouchUpInside];
    [postButton setTitle:@"Create" forState:UIControlStateNormal];
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithCustomView:postButton] ;
    self.navigationItem.rightBarButtonItem = rightButton;
    
    //list of categories
    landmarkCategory = [[NSArray alloc] initWithObjects:@"Cafe", @"Cinema", @"Interest", @"Mall", @"Restaurant", @"School", @"Shop", @"Others", nil];
    
    //prepare landmark view
    _viewLandmark = [[UIView alloc] initWithFrame:CGRectMake(10, 90, 300, 160)];
    UIImageView *landmarkBackground = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 300, 160)];
    [landmarkBackground setImage:[UIImage imageNamed:@"postLandmarkBackground.png"]];
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    _tblViewLandmark = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, 280, 160) collectionViewLayout:flowLayout];
    [_viewLandmark addSubview:landmarkBackground];
    landmarkBackground.frame = CGRectMake(0,0,_viewLandmark.frame.size.width, _viewLandmark.frame.size.height);
    [_viewLandmark addSubview:_tblViewLandmark];
    _tblViewLandmark.frame = CGRectMake(10,0,280,160);
    [_tblViewLandmark setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0]];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    _tblViewLandmark.allowsSelection = YES;
    _tblViewLandmark.delegate = self;
    _tblViewLandmark.dataSource = self;
    NSString* cellIdentifier = [RCLandmarkCell cellIdentifier];
    [_tblViewLandmark registerClass:[RCLandmarkCell class] forCellWithReuseIdentifier:cellIdentifier];
    UINib *nib = [UINib nibWithNibName:cellIdentifier bundle: nil];
    [_tblViewLandmark registerNib:nib forCellWithReuseIdentifier:cellIdentifier];
    [_tblViewLandmark setPagingEnabled:YES];
    
    didPickedCategory = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)txtFieldCategoryAction:(id)sender {
    //NSLog(@"Touchign you");
    [self.view addSubview:_viewLandmark];
    //_landmarkTableVisible = YES;
}

- (IBAction)actionBackgroundTap:(id)sender {
    [_txtFieldName resignFirstResponder];
    [_txtFieldDescription resignFirstResponder];
}


#pragma mark - UICollectionView Datasource
// 1
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    return [landmarkCategory count];//section == 0 ? [[_postsByLandmark objectForKey:[[NSNumber alloc] initWithInteger:_currentLandmarkID]] count] : 0;
}
// 2
- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}
// 3
- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString* cellIdentifier = [RCLandmarkCell cellIdentifier];
    RCLandmarkCell *cell = [cv dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    NSString *categoryName = [landmarkCategory objectAtIndex:indexPath.row];
    NSString *imageName = [NSString stringWithFormat:@"landmarkCategory%@.png", categoryName];
    [cell.imgViewCategory setImage:[UIImage imageNamed:imageName]];
    cell.lblLandmarkTitle.text = categoryName;
    
    return cell;
}
// 4
/*- (UICollectionReusableView *)collectionView:
 (UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
 {
 return [[UICollectionReusableView alloc] init];
 }*/

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *categoryName = [landmarkCategory objectAtIndex:indexPath.row];
    [_btnCategory setTitle:categoryName forState:UIControlStateNormal];
    [_viewLandmark removeFromSuperview];
    didPickedCategory = YES;
}

#pragma mark – UICollectionViewDelegateFlowLayout

// 1
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    float height = (collectionView.frame.size.height-42);
    //float width = collectionView.frame.size.width - 22;
    float width = height;
    CGSize retval = CGSizeMake(width,height);
    return retval;
}

// 3
- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(30,10,10,10);
}

- (void) asynchCreateLandmark {
    //Asynchronous Request
    @try {
        if([[_txtFieldName text] isEqualToString:@""] || [[_txtFieldDescription text] isEqualToString:@""] || !didPickedCategory ) {
            alertStatus(@"Please filled in all required field!",@"Posting failed",nil);
        } else {
            AppDelegate *appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];
            CLLocationDegrees latitude = appDelegate.currentLocation.coordinate.latitude;
            CLLocationDegrees longitude = appDelegate.currentLocation.coordinate.longitude;
            NSString* latSt = [[NSString alloc] initWithFormat:@"%f",latitude];
            NSString* longSt = [[NSString alloc] initWithFormat:@"%f",longitude];
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            NSMutableString *dataStr = initQueryString(@"landmark[name]", [_txtFieldName text]);
            addArgumentToQueryString(dataStr, @"landmark[description]", [_txtFieldDescription text]);
            addArgumentToQueryString(dataStr, @"landmark[latitude]", latSt);
            addArgumentToQueryString(dataStr, @"landmark[longitude]", longSt);
            addArgumentToQueryString(dataStr, @"landmark[category]", _btnCategory.titleLabel);
            //NSString *post =[[NSString alloc] initWithFormat:@"landmmark[name]=%@&description=%@&latitude=%@&longitude=%@&category=%@&mobile=1",[_txtFieldName text],[_txtFieldDescription text], latSt, longSt, _btnCategory.titleLabel];
            
            NSData *postData = [dataStr dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
            NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@", RCServiceURL, RCLandmarksResource]];
            NSURLRequest *request = CreateHttpPostRequest(url, postData);
            
            [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                                   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
             {
                 [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                 BOOL isSuccess;
                 
                 NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
                 int responseStatusCode = [httpResponse statusCode];
                 if (responseStatusCode != RCHttpOkStatusCode) {
                     isSuccess = NO;
                 } else isSuccess = YES;
                 
                 NSString *responseData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                 NSLog(@"%@",responseData);
                 
                 //Temporary:
                 if (isSuccess) {
                     //TODO open main news feed page
                     alertStatus(@"Landmark created successfully!", @"Success!", nil);
                    [self.navigationController popViewControllerAnimated:YES];
                 }else {
                     alertStatus([NSString stringWithFormat:@"Please try again! %@", responseData], @"Post Failed!", self);
                 }
             }];
        }
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        alertStatus(@"Failed to connect to network",@"Connection Error", self);
    }
}

@end
