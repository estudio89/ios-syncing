//
//  TestSyncEntity.h
//  Syncing
//
//  Created by Rodrigo Suhr on 7/15/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "SyncEntity.h"

@class NSManagedObject, ParentSyncEntity;

@interface TestSyncEntity : SyncEntity

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSDate * pubDate;
@property (nonatomic, retain) ParentSyncEntity *parent;
@property (nonatomic, retain) NSSet *children;
@property (nonatomic, retain) NSSet *otherChildren;
@end

@interface TestSyncEntity (CoreDataGeneratedAccessors)

- (void)addChildrenObject:(NSManagedObject *)value;
- (void)removeChildrenObject:(NSManagedObject *)value;
- (void)addChildren:(NSSet *)values;
- (void)removeChildren:(NSSet *)values;

- (void)addOtherChildrenObject:(NSManagedObject *)value;
- (void)removeOtherChildrenObject:(NSManagedObject *)value;
- (void)addOtherChildren:(NSSet *)values;
- (void)removeOtherChildren:(NSSet *)values;

@end
