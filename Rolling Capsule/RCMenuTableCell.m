//
//  RCMenuTableCell.m
//  memcap
//
//  Created by Nguyen Phi Long Louis on 17/07/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCMenuTableCell.h"

@implementation RCMenuTableCell

@synthesize imgCellIcon = _imgCellIcon;
@synthesize imgCellBackground = _imgCellBackground;
@synthesize imgCellLabel = _imgCellLabel;

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

- (void) setIcon: (UIImage*)icon label: (NSString*)label {
    [_imgCellIcon setImage:icon];
    [_imgCellLabel setText:label];
}

- (void) setStatePressed: (BOOL)pressed {
    if (pressed) {
        [_imgCellBackground setImage:[UIImage imageNamed:@"menuButtonPressed"]];
    }else {
        [_imgCellBackground setImage:[UIImage imageNamed:@"menuButtonNormal"]];
    }
}

@end
