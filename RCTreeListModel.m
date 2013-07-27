//
//  TreeListModel.m
//  TreeList
//
//  Created by Stephan Eletzhofer on 09.05.11.
//  Modified for use by Nguyen Phi Long
//  Copyright 2011 Nexiles GmbH. All rights reserved.
//

#import "RCTreeListModel.h"
#import "SBJson.h"
#import "RCConstants.h"


@interface RCTreeListModel ()

@property (nonatomic, retain) NSMutableArray *lookup;
@property (nonatomic, retain) NSMutableArray *level;

- (void)recalculate;
- (int)recalculateWithItem:(id)item andLevel:(int)lvl;
- (int)countChildrenOfItem:(id)item;

@end

@implementation RCTreeListModel

@synthesize cellCount;
@synthesize root;
@synthesize level;
@synthesize lookup;

@synthesize keyKeyPath;
@synthesize childKeyPath;
@synthesize isOpenKeyPath;

#pragma mark -
#pragma mark accessors

-(NSInteger)cellCount
{
    return cell_count;
}


-(void)setRoot:(id)newRoot;
{
    @synchronized (self) {
        if (root != newRoot) {
            root = nil;
            if (newRoot) {
                root = newRoot;
                [self recalculate];
            }
        }
    }
}

#pragma mark -
#pragma mark model item data access

-(id)itemForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.lookup objectAtIndex:indexPath.row+1];
}

-(NSInteger)levelForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [[self.level objectAtIndex:indexPath.row+1] intValue] - 1;
}

-(BOOL)isCellOpenForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = [self itemForRowAtIndexPath:indexPath];
    return [[item valueForKeyPath:self.isOpenKeyPath] boolValue];
}

-(void)setOpenClose:(BOOL)state forRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = [self itemForRowAtIndexPath:indexPath];
    [item setValue:[NSNumber numberWithBool:state] forKey:self.isOpenKeyPath];
    [self recalculate];
}

-(int)numberOfChildrenForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = [self itemForRowAtIndexPath:indexPath];
    
    int count = 0;
    for (id child in [item valueForKeyPath:self.childKeyPath]) {
        count += [self countChildrenOfItem:child];
    }
    
    return count;
}

-(void)setObject:(id)obj forKeyPath:(NSString*)keyPath forTreeItem:(NSString*)treeKey
{
    [self setObject:obj forKeyPath:keyPath forTreeItem:treeKey atItem:self.root];
}

#pragma mark -
#pragma mark internal model housekeeping

-(void)recalculate
{
    self.lookup = [NSMutableArray array];
    self.level = [NSMutableArray array];
    cell_count = [self recalculateWithItem:self.root
                                  andLevel:0] - 1;
}

-(int)recalculateWithItem:(id)item andLevel:(int)lvl;
{

    int count = 1;

    [self.lookup addObject: item];
    [self.level addObject: [NSNumber numberWithInt:lvl]];

//    if ([item valueForKeyPath:self.isOpenKeyPath] == nil)
//        [item setObject:[NSNumber numberWithBool:NO] forKey:self.isOpenKeyPath];
    BOOL isOpen = [[item valueForKeyPath:self.isOpenKeyPath] boolValue];

    if (isOpen) {
        for (id child in [item valueForKeyPath:self.childKeyPath]) {
            count += [self recalculateWithItem:child andLevel:lvl + 1];
        }
    }

    return count;
}

- (int)countChildrenOfItem:(id)item
{
    int count = 1;
    
    BOOL isOpen = [[item valueForKeyPath:self.isOpenKeyPath] boolValue];
    if (isOpen) {
        for (id child in [item valueForKeyPath:self.childKeyPath]) {
            count += [self countChildrenOfItem:child];
        }
    }
    
    return count;
}

- (void)setObject:(id)obj forKeyPath:(NSString*)keyPath forTreeItem:(NSString*)treeKey atItem:(id)item
{
    if ([treeKey isEqualToString:(NSString*)[item objectForKey:self.keyKeyPath]])
        [item setValue:obj forKeyPath:keyPath];
    
    for (id child in [item valueForKeyPath:self.childKeyPath]) {
        [self setObject:obj forKeyPath:keyPath forTreeItem:treeKey atItem:child];
    }
}

#pragma mark -
#pragma mark init and dealloc

-(id)init
{
	self = [super init];
	if (self) {
        // initialize key paths for model access
        self.keyKeyPath = RCMenuKeyKeyPath;
        self.isOpenKeyPath = @"isOpen";
        self.childKeyPath = @"value";

        self.lookup = [NSMutableArray array];
        self.level = [NSMutableArray array];

        return self;
    }
    return nil;
}

-(id)initWithDictionary:(NSMutableDictionary *)dict
{
	self = [self init];
    if (self) {
        self.root = dict;
        return self;
    }
    return nil;
}

-(id)initWithJSONString:(NSString *)jsonString
{
    return [self initWithDictionary:[jsonString JSONValue]];
}

-(id)initWithJSONFilePath:(NSString *)filePath
{
    NSString *data = [NSString stringWithContentsOfFile:filePath
                                               encoding:NSUTF8StringEncoding
                                                  error:nil];
    return [self initWithJSONString:data];
}

-(void)dealloc
{
	self.root         = nil;
	self.lookup        = nil;
	self.level         = nil;
	self.isOpenKeyPath = nil;
	self.keyKeyPath    = nil;
	self.childKeyPath  = nil;
}


@end
