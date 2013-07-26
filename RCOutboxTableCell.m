//
//  RCOutboxTableCell.m
//  memcap
//
//  Created by Nguyen Phi Long Louis on 27/07/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCOutboxTableCell.h"

@implementation RCOutboxTableCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

+ (CGFloat) cellHeight {
    return 60;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+ (RCOutboxTableCell*) createOutboxTableCell: (UITableView*) tableView {
    RCOutboxTableCell *cell;
    static NSString *cellIdentifier = @"RCOutboxTableCell";
    
    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:cellIdentifier owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    return cell;
}

@end
