//
//  RCResourceCache.m
//  Rolling Capsule
//
//  Created by Nguyen Phi Long Louis on 9/06/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import "RCResourceCache.h"

@implementation RCResourceCache

@synthesize cache = _cache;

static RCResourceCache *instance;

- (id) init {
    self = [super init];
    if (self){
        _cache = [[NSMutableDictionary alloc] init];
    }
    return self;
}

+ (RCResourceCache*) centralCache {
    @synchronized(self){
        if (!instance)
            instance = [[RCResourceCache alloc] init];
        return instance;
    }
}

- (id) getResourceForKey:(id)key usingQuery:(id (^)(void))queryFunction {
    NSObject *ret = [_cache objectForKey:key];
    if (ret == nil) {
        ret = queryFunction();
        if (ret != nil)
            [_cache setObject:ret forKey:key];
        //NSLog(@"querrying new object from Internet for key: %@", key);
    }
    return ret;
}

@end


