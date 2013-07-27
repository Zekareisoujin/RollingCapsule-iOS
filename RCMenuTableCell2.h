//
//  RCMenuTableCell2.h
//  memcap
//
//  Created by Nguyen Phi Long Louis on 27/07/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RCMenuTableCell2 : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imgCellIcon;
@property (weak, nonatomic) IBOutlet UIImageView *imgCellIcon2;
@property (weak, nonatomic) IBOutlet UILabel *lblCellTitle;

+ (NSString*) cellIdentifier;
+ (CGFloat) cellHeight;
+ (RCMenuTableCell2*) createMenuTableCell: (UITableView*) tableView;

@end
