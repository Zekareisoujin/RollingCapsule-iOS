//
//  RCMenuTableCell.h
//  memcap
//
//  Created by Nguyen Phi Long Louis on 17/07/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RCMenuTableCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imgCellIcon;
@property (weak, nonatomic) IBOutlet UIImageView *imgCellBackground;
@property (weak, nonatomic) IBOutlet UILabel *imgCellLabel;

+ (NSString*) cellIdentifier;
+ (CGFloat) cellHeight;
+ (RCMenuTableCell*) createMenuTableCell: (UITableView*) tableView;
- (void) setIcon: (UIImage*)icon label: (NSString*)label;
- (void) setCellStateNormal: (BOOL)pressed;

@end
