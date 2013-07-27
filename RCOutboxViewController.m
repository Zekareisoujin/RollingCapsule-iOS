//
//  RCOutboxViewController.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 26/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCOutboxViewController.h"
#import "RCOutboxTableCell.h"
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
        _uploadTasks = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _tblViewUploadTasks.tableFooterView = [[UIView alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshData:) name:RCNotificationNameMediaUploaded object:nil];
    [self refreshData:nil];
    // Do any additional setup after loading the view from its nib.
}

- (void) refreshData:(NSNotification*) notification {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray* uploadList = [RCOperationsManager uploadList];
        [_uploadTasks removeAllObjects];
        @synchronized(uploadList)
        {
            for (RCUploadTask *task in uploadList)
                 [_uploadTasks addObject:task];
        }
        int j = [_uploadTasks count] - 1;
        int i = 0;
        while (i < j) {
            RCUploadTask* task1 = (RCUploadTask*)[_uploadTasks objectAtIndex:i];
            if (task1.postedSuccessfully) {
                //decrease j until find a none successful post
                RCUploadTask *task2 = (RCUploadTask*)[_uploadTasks objectAtIndex:j];
                while (j > i && task2.postedSuccessfully) {
                    j--;
                    task2 = (RCUploadTask*)[_uploadTasks objectAtIndex:j];
                }
                if (j > i) {
                    [_uploadTasks exchangeObjectAtIndex:i withObjectAtIndex:j];
                }
            }
            i++;
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
    RCOutboxTableCell *cell = [RCOutboxTableCell createOutboxTableCell:tableView];
    RCUploadTask *task = [_uploadTasks objectAtIndex:indexPath.row];
    NSURL* url;
    BOOL success = task.fileURL == nil;
    RCPost* post;
    if (success) {
        post = task.currentNewPostOperation.post;
        url = task.currentNewPostOperation.mediaUploadOperation.fileURL;
    } else {
        post = [task respectivePost];
        url = [NSURL URLWithString:task.fileURL];
    }
    /*if (op.mediaUploadOperation.thumbnailImage != nil)
        [cell.imgViewThumbnail setImage:op.mediaUploadOperation.thumbnailImage];
    else {*/
        UIImage *image = [thumbnailImages objectForKey:task.fileURL];
        if (image != nil)
            [cell.imgViewThumbnail setImage:image];
        else {
            [cell.imgViewThumbnail setImage:[UIImage imageNamed:@"loading.gif"]];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSString* mediaType = [task.key hasSuffix:@"mov"] ? @"movie/mov" : @"image/jpeg";
                generateThumbnailImage(url, mediaType, ^(UIImage *image) {
                    NSLog(@"set image for cell");
                    if (task.fileURL != nil)
                        [thumbnailImages setObject:image forKey:url];
                    dispatch_async(dispatch_get_main_queue(), ^ {
                        [cell.imgViewThumbnail setImage:image];
                    });
                });
            });
        }
    //}
    cell.lblSubject.text = post.subject;
    /*NSString *status = @"";*/
    cell.btnTaskAction.enabled = NO;
    NSLog(@"task.successful %d",success);
    NSLog(@"task.fileURL %@ %@",url, task.fileURL);
    [cell.btnDeleteTask addTarget:self action:@selector(refreshData:) forControlEvents:UIControlEventTouchUpInside];
    if (success) {
        cell.btnDeleteTask.enabled = NO;
        [cell.btnDeleteTask setImage:[UIImage imageNamed:@"outboxComplete.png"] forState:UIControlStateDisabled];
        [cell.btnTaskAction setHidden:YES];
        //[cell.viewActivityIndicator stopAnimating];
    }
    else if (task.currentNewPostOperation.isExecuting || task.currentNewPostOperation.mediaUploadOperation.isExecuting) {
        [cell.btnTaskAction setImage:[UIImage imageNamed:@"outboxUploading.png"] forState:UIControlStateNormal];
        //[cell.viewActivityIndicator startAnimating];
    } else {
        [cell.btnTaskAction setImage:[UIImage imageNamed:@"outboxPause.png"] forState:UIControlStateNormal];
        //[cell.viewActivityIndicator stopAnimating];
    }
    [cell setupButtonControl:task];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {    
    return [RCOutboxTableCell cellHeight];

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
            [self refreshData:nil];
        });
    });
}
@end
