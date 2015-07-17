//
//  TestSyncManager.m
//  Syncing
//
//  Created by Rodrigo Suhr on 3/4/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "TestSyncManager.h"
#import "Annotations.h"

@implementation TestSyncManager

/**
 getAnnotations
 */
- (Annotations *)getAnnotationsWithAbstractAttributes:(NSDictionary *)abstractAttributes
{
    // fields
    NSDictionary *pubDate = [[NSDictionary alloc] init];
    NSDictionary *name = [[NSDictionary alloc] init];
    NSDictionary *parent = @{@"name":@"parent_id"};
    NSDictionary *children = @{@"name":@"children_objs"};
    NSDictionary *otherChildren = @{@"name":@"other_children_objs"};
    NSMutableDictionary *fields = [[NSMutableDictionary alloc] initWithDictionary:abstractAttributes];
    [fields setObject:pubDate forKey:@"pubDate"];
    [fields setObject:name forKey:@"name"];
    [fields setObject:parent forKey:@"parent"];
    [fields setObject:children forKey:@"children"];
    [fields setObject:otherChildren forKey:@"otherChildren"];
    
    // nested managers
    NSDictionary *childrenNestedManager = @{@"entityName":@"ChildSyncEntity",
                                            @"manager":@"ChildSyncManager",
                                            @"paginationParams":@"children_pagination"};
    NSDictionary *otherChildrenNestedManager = @{@"entityName":@"OtherChildSyncEntity",
                                                 @"manager":@"OtherChildSyncManager",
                                                 @"writable":@YES,
                                                 @"discardOnSave":@YES};
    NSDictionary *nestedManagers = @{@"children":childrenNestedManager,
                                     @"otherChildren":otherChildrenNestedManager};
    
    // paginate
    NSDictionary *paginate = @{@"byField":@"pubDate",
                               @"extraIdentifier":@"paginationIdentifier"};
    
    // annotation
    NSDictionary *annotationDict = @{@"fields":fields,
                                     @"entityName":@"TestSyncEntity",
                                     @"paginate":paginate,
                                     @"nestedManagers":nestedManagers};
    
    Annotations *annotations = [[Annotations alloc] initWithAnnotation:annotationDict];
    
    return annotations;
}

/**
 getIdentifier
 */
- (NSString *)getIdentifier
{
    return @"test";
}

/**
 getResponseIdentifier
 */
- (NSString *)getResponseIdentifier
{
    return @"test_id";
}

/**
 shouldSendSingleObject
 */
- (BOOL)shouldSendSingleObject
{
    return NO;
}

/**
 getModifiedFiles
 */
- (NSMutableArray *)getModifiedFiles
{
    return [[NSMutableArray alloc] init];
}

/**
 getModifiedFilesForObject
 */
- (NSMutableArray *)getModifiedFilesForObject:(NSDictionary *)object
{
    return [[NSMutableArray alloc] init];
}

/**
 postEvent
 */
- (void)postEvent:(NSArray *)objects withBus:(AsyncBus *)bus
{
}

@end
