//
//  RCTutorialViewController.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 16/8/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCTutorialViewController.h"
#import "RCMainFeedCell.h"
#import "RCConstants.h"
#import "RCMainMenuViewController.h"

@interface RCTutorialViewController ()

@end

@implementation RCTutorialViewController

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
    //prepare collection view cell
    NSString* cellIdentifier = [RCMainFeedCell cellIdentifier];
    [self.collectionView registerClass:[RCMainFeedCell class] forCellWithReuseIdentifier:cellIdentifier];
    UINib *nib = [UINib nibWithNibName:cellIdentifier bundle: nil];
    [self.collectionView registerNib:nib forCellWithReuseIdentifier:cellIdentifier];
    UICollectionViewFlowLayout *flow =  (UICollectionViewFlowLayout *)_collectionView.collectionViewLayout;
    flow.minimumInteritemSpacing = 0.0;
    flow.sectionInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate disableSideMenu];
}

#pragma mark - UICollectionView Datasource
// 1
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    return NUMBER_OF_TUTORIAL_PAGE + 1;
}
// 2
- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}
// 3
- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString* cellIdentifier = [RCMainFeedCell cellIdentifier];
    RCMainFeedCell *cell = [cv dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    if (indexPath.row < NUMBER_OF_TUTORIAL_PAGE) {
        BOOL iphone5 = [[UIScreen mainScreen] bounds].size.height >= RCIphone5Height;
        int phoneType = iphone5 ? 5 : 4;
        NSString* imageName = [NSString stringWithFormat:@"tutorialI%dMainpage%d.jpg",phoneType,indexPath.row+1];
        [cell.imageView setImage:[UIImage imageNamed:imageName]];
        return cell;
    } else {
        BOOL iphone5 = [[UIScreen mainScreen] bounds].size.height >= RCIphone5Height;
        int phoneType = iphone5 ? 5 : 4;
        NSString* imageName = [NSString stringWithFormat:@"tutorialI%dBackground.jpg",phoneType];
        UIImage *img = [UIImage imageNamed:imageName];
        [cell.imageView setImage:img];
        [_imgViewBackground setImage:img];
        return cell;
    }
    
}
// 4
/*- (UICollectionReusableView *)collectionView:
 (UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
 {
 return [[UICollectionReusableView alloc] init];
 }*/

#pragma mark – UICollectionViewDelegateFlowLayout

// 1
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.view.frame.size;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    // if decelerating, let scrollViewDidEndDecelerating: handle it
    if (decelerate == NO) {
        [self centerTable:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self centerTable:scrollView];
}

- (void)centerTable:(UIScrollView*) scrollView {
    
    if ([scrollView isKindOfClass:[UICollectionView class]]) {
        UICollectionView *tableView = (UICollectionView*) scrollView;
        NSIndexPath *pathForCenterCell = [tableView indexPathForItemAtPoint:CGPointMake(CGRectGetMidX(tableView.bounds), CGRectGetMidY(tableView.bounds))];
        [tableView scrollToItemAtIndexPath:pathForCenterCell atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
        if (pathForCenterCell.row == NUMBER_OF_TUTORIAL_PAGE) {
            [tableView setHidden:YES];
            /*AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
            [self.navigationController setNavigationBarHidden:NO];
            [appDelegate.menuViewController btnActionMainFeedNav:nil];*/
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnStartMemcapTouchUpInside:(id)sender {
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate enableSideMenu];
    [appDelegate.menuViewController btnActionMainFeedNav:nil];
    
}
@end
