//
//  AbstractSyncManager.h
//  Syncing
//
//  Created by Rodrigo Suhr on 7/7/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SyncEntity.h"
#import "SyncManager.h"
#import "Annotations.h"

@class Annotations;

@interface AbstractSyncManager : NSObject<SyncManager>

@property (strong, nonatomic, readonly) Annotations *annotations;
@property (strong, nonatomic, readonly) NSString *dateAttribute;
@property (strong, nonatomic, readonly) NSMutableDictionary *parentAttributes;
@property (strong, nonatomic, readonly) NSMutableDictionary *childrenAttributes;
@property (strong, nonatomic, readwrite) NSManagedObject *oldestInCache;
@property (strong, nonatomic) DataSyncHelper *dataSyncHelper;

- (Annotations *)getAnnotations;
- (NSDate *)getDateForObject:(NSManagedObject *)object;
- (SyncEntity *)findItem:(NSNumber *)idServer
            withIdClient:(NSString *)idClient
            withDeviceId:(NSString *)deviceId
        withItemDeviceId:(NSString *)itemDeviceId
              withObject:(NSDictionary *)object
             withContext:(NSManagedObjectContext *)context;
- (SyncEntity *)findItem:(NSNumber *)idServer
            withIdClient:(NSString *)idClient
            withDeviceId:(NSString *)deviceId
        withItemDeviceId:(NSString *)itemDeviceId
      withIgnoreDeviceId:(BOOL)ignoreDeviceId
             withContext:(NSManagedObjectContext *)context;
- (SyncEntity *)findItem:(NSNumber *)idServer
            withIdClient:(NSString *)idClient
            withDeviceId:(NSString *)deviceId
        withItemDeviceId:(NSString *)itemDeviceId
      withIgnoreDeviceId:(BOOL)ignoreDeviceId
              withObject:(NSDictionary *)object
             withContext:(NSManagedObjectContext *)context;
- (SyncEntity *)findParent:(NSString *)parentEntity withParentId:(NSObject *)parentId withContext:(NSManagedObjectContext *)context;
- (void)performSaveWithContext:(NSManagedObjectContext *)context;
- (void)deleteMissingChildrenFromEntity:(NSString *)entity
                    withParentAttribute:(NSString *)parentAttribute
                             withParent:(NSManagedObject *)parent
                            withContext:(NSManagedObjectContext *)context
                         withNewObjects:(NSArray *)newObjects;
- (id<SyncManager>)syncManagerForNestedManager:(NestedManager *)nestedManager;
- (void)saveBooleanPref:(NSString *)key withValue:(BOOL)value;
- (NSManagedObject *)getOldestFromContext:(NSManagedObjectContext *)context;
- (id<SyncManager>)getSyncManagerDeleted;
- (NSMutableArray *)saveNewData:(NSArray *)jsonObjects withDeviceId:(NSString *)deviceId withParameters:(NSDictionary *)responseParameters withContext:(NSManagedObjectContext *)context;
- (NSArray *)deleteAllWithContext:(NSManagedObjectContext *)context;
- (BOOL)moreOnServer;
- (BOOL)moreOnServerWithPaginationIdentifier:(NSString *)paginationIdentifier;
- (NSDictionary *)serializeObject:(NSObject *)object withContext:(NSManagedObjectContext *)context;
- (BOOL)booleanPref:(NSString *)key withDefaultValue:(BOOL)defaultValue;

@end
