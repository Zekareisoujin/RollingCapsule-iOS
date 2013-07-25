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

@interface RCOutboxViewController ()

@end

@implementation RCOutboxViewController

@synthesize uploadTasks = _uploadTasks;

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
    _tblViewUploadTasks.tableFooterView = [[UIView alloc] init];
    [self refreshData];
    // Do any additional setup after loading the view from its nib.
}

- (void) refreshData {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSMutableArray* uploadList = [RCOperationsManager uploadTasks];
        @synchronized(uploadList)
        {
            _uploadTasks = [uploadList copy];
        }
        [_tblViewUploadTasks reloadData];
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
    [cell.imageView setImage:op.mediaUploadOperation.thumbnailImage];
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
    // Dispose of any resources that can be recreated.
}

@end
