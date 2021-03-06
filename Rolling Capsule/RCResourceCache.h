//
//  RCResourceCache.h
//  Rolling Capsule
//
//  Created by Nguyen Phi Long Louis on 9/06/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCResourceCache : NSObject

@property (nonatomic, strong) NSCache *cache;

+ (RCResourceCache*) centralCache;

- (void) purge;
- (void) putResourceInCache:(id)object forKey:(id)key;
- (id) getResourceForKey:(id)key;
- (id) getResourceForKey:(id)key usingQuery:(id (^)(void))queryFunction;
- (void) invalidateKey:(id) key;
@end
