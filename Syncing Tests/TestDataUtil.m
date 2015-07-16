//
//  TestDataUtil.m
//  Syncing
//
//  Created by Rodrigo Suhr on 7/15/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "TestDataUtil.h"

@implementation TestDataUtil

+ (Annotations *)annotations
{
    return [[Annotations alloc] initWithAnnotation:[self annotationsDict]];
}

+ (NSDictionary *)annotationsDict
{
    NSDictionary *pubDate = [[NSDictionary alloc] init];
    NSDictionary *name = [[NSDictionary alloc] init];
    NSDictionary *parent = @{@"name":@"parent_id"};
    NSDictionary *children = @{@"name":@"children_objs"};
    NSDictionary *otherChildren = @{@"name":@"other_children_objs"};
    NSDictionary *fields = @{@"pubDate":pubDate,
                             @"name":name,
                             @"parent":parent,
                             @"children":children,
                             @"otherChildren":otherChildren};
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
    
    return annotationDict;
}

@end
