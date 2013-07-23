//
//  RCDatePickerView.h
//  memcap
//
//  Created by Trinh Tuan Phuong on 18/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RCDatePickerDelegate
@optional
- (void) didPickDate: (NSDate*) pickedDateTime success:(BOOL)success;

@end

@interface RCDatePickerView : UIView <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *pickerViewYear;
@property (weak, nonatomic) IBOutlet UITableView *pickerViewMonth;
@property (weak, nonatomic) IBOutlet UITableView *pickerViewDay;
@property (weak, nonatomic) IBOutlet UITableView *pickerViewHour;
@property (nonatomic, strong) NSArray* months;

@property (nonatomic, assign) int hour;
@property (nonatomic, assign) int day;
@property (nonatomic, assign) int month;
@property (nonatomic, assign) int year;
@property (nonatomic, assign) int yearOffset;
@property (nonatomic, assign) id<RCDatePickerDelegate> delegate;

- (void) prepareView;
- (IBAction)pickDate:(id)sender;
- (NSString*) dateTimeString;
- (NSDate*) date;
@end
