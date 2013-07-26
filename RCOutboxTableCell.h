//
//  RCOutboxTableCell.h
//  memcap
//
//  Created by Nguyen Phi Long Louis on 27/07/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RCOutboxTableCell : UITableViewCell

+ (CGFloat) cellHeight;
+ (RCOutboxTableCell*) createOutboxTableCell: (UITableView*) tableView;

@end
