//
//  ParentSyncEntity.h
//  Syncing
//
//  Created by Rodrigo Suhr on 7/15/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "SyncEntity.h"

@class NSManagedObject;

@interface ParentSyncEntity : SyncEntity

@property (nonatomic, retain) NSSet *testSync;
@end

@interface ParentSyncEntity (CoreDataGeneratedAccessors)

- (void)addTestSyncObject:(NSManagedObject *)value;
- (void)removeTestSyncObject:(NSManagedObject *)value;
- (void)addTestSync:(NSSet *)values;
- (void)removeTestSync:(NSSet *)values;

@end
