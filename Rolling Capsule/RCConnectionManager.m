//
//  RCConnectionManager.m
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 9/6/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCConnectionManager.h"

@implementation RCConnectionManager
static int _staticOpenConnections = 0;
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

+ (void) startConnection {
    //NSLog(@"start %d",_staticOpenConnections);
    _staticOpenConnections++;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

+ (void) endConnection {
    //NSLog(@"end %d",_staticOpenConnections);
    _staticOpenConnections--;
    if (_staticOpenConnections == 0)
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (void) startConnection {
    //NSLog(@"start %d",_nOpenConnections);
    _nOpenConnections++;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void) endConnection {
    //NSLog(@"end %d",_nOpenConnections);
    _nOpenConnections--;
    if (_nOpenConnections == 0)
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

@end
