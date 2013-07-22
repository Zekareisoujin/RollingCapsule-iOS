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

static RCResourceCache *instance = 0;

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

- (void) purge {
    [_cache removeAllObjects];
}

- (void) putResourceInCache:(id)object forKey:(id)key {
    [_cache setObject:object forKey:key];
}

- (id) getResourceForKey:(id)key {
    return [_cache objectForKey:key];
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

- (void) invalidateKey:(id) key {
    //[_cache setObject:nil forKey:key];
    [_cache removeObjectForKey:key];
}

@end


