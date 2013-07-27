//
//  RCMenuTableCell2.m
//  memcap
//
//  Created by Nguyen Phi Long Louis on 27/07/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCMenuTableCell2.h"

@implementation RCMenuTableCell2

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+ (NSString*) cellIdentifier {
    return @"RCMenuTableCell2";
}

+ (CGFloat) cellHeight {
    return 40;
}

+ (RCMenuTableCell2*) createMenuTableCell: (UITableView*) tableView {
    RCMenuTableCell2 *cell;
    static NSString *cellIdentifier = @"RCMenuTableCell2";
    
    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:cellIdentifier owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    return cell;
}

@end
