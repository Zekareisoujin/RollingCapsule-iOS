//
//  RCMenuTableCell.m
//  memcap
//
//  Created by Nguyen Phi Long Louis on 17/07/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCMenuTableCell.h"

@implementation RCMenuTableCell

static NSString *cellStateHighlight = @"menuButtonPressed";
static NSString *cellStateSelected = @"menuButtonPressed";
static NSString *cellStateNormal = @"menuButtonNormal";

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
    if (selected) {
        [_imgCellBackground setImage:[UIImage imageNamed:cellStateSelected]];
    }else {
        [_imgCellBackground setImage:[UIImage imageNamed:cellStateNormal]];
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    //[super setHighlighted:highlighted animated:animated];
    if (highlighted) {
        [_imgCellBackground setImage:[UIImage imageNamed:cellStateHighlight]];
    }else {
        [_imgCellBackground setImage:[UIImage imageNamed:cellStateNormal]];
    }
}

+ (NSString*) cellIdentifier {
    return @"RCMenuTableCell";
}

+ (CGFloat) cellHeight {
    return 50;
}

+ (RCMenuTableCell*) createMenuTableCell: (UITableView*) tableView {
    RCMenuTableCell *cell;
    static NSString *cellIdentifier = @"RCMenuTableCell";
    
    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:cellIdentifier owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    return cell;
}

- (void) setCellStateNormal: (BOOL)pressed {
    if (pressed) {
        cellStateNormal = @"menuButtonPressed";
    }else {
        cellStateNormal = @"menuButtonNormal";
    }
}

- (void) setDropDownIconVisible: (BOOL)show openState:(BOOL)open {
    [self setHidden:!show];
    if (open)
        [_imgCellDropdownIcon setImage:[UIImage imageNamed:@"menuIconDropdownOpen"]];
    else
        [_imgCellDropdownIcon setImage:[UIImage imageNamed:@"menuIconDropdownClose"]];
}

@end
