//
//  RCDatePickerView.m
//  memcap
//
//  Created by Trinh Tuan Phuong on 18/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCDatePickerView.h"

@implementation RCDatePickerView
@synthesize day = _day;
@synthesize hour = _hour;
@synthesize month = _month;
@synthesize year = _year;
@synthesize months = _months;
@synthesize yearOffset = _yearOffset;
@synthesize delegate;

#define MULTIPLY 4
#define YEAR_RANGE 200

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code        
    }
    return self;
}
- (void) prepareView {
    _pickerViewYear.delegate = self;
    _pickerViewYear.dataSource = self;
    _pickerViewYear.tableFooterView = [[UIView alloc] init];
    [_pickerViewYear setSeparatorColor:[UIColor clearColor]];
    
    _pickerViewMonth.delegate = self;
    _pickerViewMonth.dataSource = self;
    _pickerViewMonth.tableFooterView = [[UIView alloc] init];
    [_pickerViewMonth setSeparatorColor:[UIColor clearColor]];
    
    _pickerViewDay.delegate = self;
    _pickerViewDay.dataSource = self;
    _pickerViewDay.tableFooterView = [[UIView alloc] init];
    [_pickerViewDay setSeparatorColor:[UIColor clearColor]];
    
    _pickerViewHour.delegate = self;
    _pickerViewHour.dataSource = self;
    _pickerViewHour.tableFooterView = [[UIView alloc] init];
    [_pickerViewHour setSeparatorColor:[UIColor clearColor]];
    
    _months = [[NSArray alloc] initWithObjects:@"JAN",@"FEB",@"MAR",@"APR",@"MAY",@"JUN",@"JUL",@"AUG",@"SEP",@"OCT",@"NOV",@"DEC", nil];
    NSDate *currentDate = [NSDate date];
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit fromDate:currentDate];
    _month = [components month];
    [_pickerViewMonth scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:(_month-1) + [self monthCount] * (MULTIPLY/2) inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    _year = [components year];
    _yearOffset = _year - (YEAR_RANGE/2);
    [_pickerViewYear scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:(YEAR_RANGE/2) + [self yearCount] * (MULTIPLY/2) inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    _hour =[components hour];
    [_pickerViewHour scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:_hour + [self hourCount]*(MULTIPLY/2) inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    _day = [components day];
    [_pickerViewDay scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:(_day-1) + [self dayCount] * (MULTIPLY/2) inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
}
- (NSString*) dateTimeString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    [dateFormatter setDateFormat:@"yyyy-MM-ddHH:mm:ss"];
    NSDate *date = [dateFormatter dateFromString:[NSString stringWithFormat:@"%04d-%02d-%02d%02d:00:00",_year,_month,_day,_hour]];
    if ([date compare:[NSDate date]] == NSOrderedDescending) {
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZZ"];
        return [dateFormatter stringFromDate:date];
    } else return nil;
};

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (int) dayCount {
    int rowCount;
    switch (_month) {
        case 1:
        case 3:
        case 5:
        case 7:
        case 8:
        case 10:
        case 12: rowCount = 31;
            break;
        case 2:
            if (_year % 4 == 0)
                if (_year % (YEAR_RANGE/2) == 0)
                    if (_year % 400 == 0)
                        rowCount = 29;
                    else
                        rowCount = 28;
                    else
                        rowCount = 29;
                    else
                        rowCount = 28;
            break;
        default:rowCount = 30;
            break;
    }
    return rowCount;
}
- (int) yearCount {
    return YEAR_RANGE;
}
- (int) monthCount {
    return 12;
}
- (int) hourCount {
    return 24;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int rowCount;
    if ([tableView isEqual:_pickerViewYear]) {
        rowCount = [self yearCount];
    } else if ([tableView isEqual:_pickerViewMonth]) {
        rowCount = [self monthCount];
    } else if ([tableView isEqual:_pickerViewDay]) {
        rowCount = [self dayCount];
    } else if ([tableView isEqual:_pickerViewHour]) {
        rowCount = [self hourCount];
    } else rowCount = 30;
    return rowCount*MULTIPLY;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"UITableViewCell";
    UITableViewCell *cell;
    
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] init];
    }
    int idx = indexPath.row;
    if ([tableView isEqual:_pickerViewYear]) {
        idx %= [self yearCount];
        int year = _yearOffset + idx;
        cell.textLabel.text = [NSString stringWithFormat:@"%d",year];
    } else if ([tableView isEqual:_pickerViewMonth]) {
        idx %= [self monthCount];
        cell.textLabel.text = [_months objectAtIndex:idx];
    } else if ([tableView isEqual:_pickerViewDay]) {
        idx %= [self dayCount];
        //NSLog(@"daycount %d index:%d",[self dayCount],indexPath.row);
        cell.textLabel.text = [NSString stringWithFormat:@"%d",idx+1];
    } else if ([tableView isEqual:_pickerViewHour]) {
        idx %= [self hourCount];
        cell.textLabel.text = [NSString stringWithFormat:@"%02d",idx];
    }
        
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 30;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}
#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    // if decelerating, let scrollViewDidEndDecelerating: handle it
    if (decelerate == NO) {
        [self centerTable:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self centerTable:scrollView];
}

- (void)centerTable:(UIScrollView*) scrollView {
   
    if ([scrollView isKindOfClass:[UITableView class]]) {
        UITableView *tableView = (UITableView*) scrollView;
         NSIndexPath *pathForCenterCell = [tableView indexPathForRowAtPoint:CGPointMake(CGRectGetMidX(tableView.bounds), CGRectGetMidY(tableView.bounds))];
        [tableView scrollToRowAtIndexPath:pathForCenterCell atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        int idx = pathForCenterCell.row;
        if ([tableView isEqual:_pickerViewYear]) {
            idx %= [self yearCount];
            _year = idx + _yearOffset;
            [_pickerViewDay reloadData];
        } else if ([tableView isEqual:_pickerViewMonth]) {
            idx %= [self monthCount];
            _month = idx+1;
            [_pickerViewDay reloadData];
        } else if ([tableView isEqual:_pickerViewDay]) {
            idx %= [self dayCount];
            _day = idx+1;
        } else if ([tableView isEqual:_pickerViewHour]) {
            idx %= [self hourCount];
            _hour = idx;
        }
    }
}

- (NSDate*) date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //[dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    [dateFormatter setDateFormat:@"yyyy-MM-ddHH:mm:ss"];
    return [dateFormatter dateFromString:[NSString stringWithFormat:@"%04d-%02d-%02d%02d:00:00",_year,_month,_day,_hour]];
}

- (IBAction)pickDate:(id)sender {

    /*[UIView animateWithDuration:0.5
						  delay:0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
                         self.alpha = 0.0;
					 }
                     completion:^(BOOL finished) {*/
                         NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                         [dateFormatter setDateFormat:@"yyyy-MM-ddHH:mm:ss"];
                         NSDate *date = [dateFormatter dateFromString:[NSString stringWithFormat:@"%04d-%02d-%02d%02d:00:00",_year,_month,_day,_hour]];
                         if ([date compare:[NSDate date]] == NSOrderedDescending) {
                             [delegate didPickDate:date success:YES];
                         }else
                             [delegate didPickDate:date success:NO];
                         //[self setHidden:YES];
                         NSLog(@"year %d month %d day %d hour %d",_year, _month, _day, _hour);
					 //}];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
