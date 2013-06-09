//
//  RCConnectionManager.m
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 9/6/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCConnectionManager.h"

@implementation RCConnectionManager

int _nOpenConnections;

-(id) init {
    self = [super init];
    if (self) {
        _nOpenConnections = 0;
    }
    return self;
}

- (void) reset {
    _nOpenConnections = 0;
}

- (void) startConnection {
    _nOpenConnections++;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void) endConnection {
    _nOpenConnections--;
    if (_nOpenConnections == 0)
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

@end
