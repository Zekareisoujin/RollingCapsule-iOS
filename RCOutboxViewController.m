//
//  RCOutboxViewController.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 26/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCOutboxViewController.h"
#import "RCMenuTableCell.h"
#import "RCOperationsManager.h"
#import "RCNewPostOperation.h"
#import "RCMediaUploadOperation.h"
#import "RCUtilities.h"

@interface RCOutboxViewController ()

@end

@implementation RCOutboxViewController {
    NSMutableDictionary* thumbnailImages;
}

@synthesize uploadTasks = _uploadTasks;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        thumbnailImages = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _tblViewUploadTasks.tableFooterView = [[UIView alloc] init];
    [self refreshData];
    // Do any additional setup after loading the view from its nib.
}

- (void) refreshData {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray* uploadList = [RCOperationsManager uploadList];
        @synchronized(uploadList)
        {
            _uploadTasks = [uploadList copy];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [_tblViewUploadTasks reloadData];
        });
        
    });
}

#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_uploadTasks count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RCMenuTableCell *cell = [RCMenuTableCell createMenuTableCell:tableView];
    RCNewPostOperation* op = [_uploadTasks objectAtIndex:indexPath.row];
    if (op.mediaUploadOperation.thumbnailImage != nil)
        [cell.imgCellIcon setImage:op.mediaUploadOperation.thumbnailImage];
    else {
        UIImage *image = [thumbnailImages objectForKey:op.mediaUploadOperation.fileURL];
        if (image != nil)
            [cell.imgCellIcon setImage:image];
        else {
            [cell.imgCellIcon setImage:[UIImage imageNamed:@"loading.gif"]];
            /*dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                generateThumbnailImage(op.mediaUploadOperation.fileURL, op.mediaUploadOperation.mediaType, ^(UIImage *image) {
                    NSLog(@"set image for cell");
                    if (op.mediaUploadOperation.fileURL != nil)
                        [thumbnailImages setObject:image forKey:op.mediaUploadOperation.fileURL];
                    dispatch_async(dispatch_get_main_queue(), ^ {
                        [cell.imgCellIcon setImage:image];
                    });
                });
            });*/
        }
    }
    
    NSString *status = @"";
    if (op.successfulPost) status = @"Done";
    else if (op.isExecuting || op.mediaUploadOperation.isExecuting) status = @"Uploading";
    else status = @"Queued";
    cell.imgCellLabel.text = status;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {    
    return [RCMenuTableCell cellHeight];

}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [AppDelegate cleanupMemory];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnCleanupTouchUpInside:(id)sender {
    RCUploadManager* defaultUM = [RCOperationsManager defaultUploadManager];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [defaultUM cleanupFinishedOperation];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshData];
        });
    });
}
@end
