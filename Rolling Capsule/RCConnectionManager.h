//
//  RCConnectionManager.h
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 9/6/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCConnectionManager : NSObject
- (void) startConnection;
- (void) endConnection;
- (void) reset;
@end
