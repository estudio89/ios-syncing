//
//  SyncManager.h
//  Syncing
//
//  Created by Rodrigo Suhr on 2/12/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "SyncEntity.h"
#import "AsyncBus.h"

@class DataSyncHelper;

@protocol SyncManager <NSObject>

- (NSString *)getIdentifier;
- (NSString *)getResponseIdentifier;
- (BOOL)shouldSendSingleObject;
- (NSMutableArray *)getModifiedDataWithContext:(NSManagedObjectContext *)context;
- (BOOL)hasModifiedDataWithContext:(NSManagedObjectContext *)context;
- (NSMutableArray *)getModifiedFilesWithContext:(NSManagedObjectContext *)context;
- (NSMutableArray *)getModifiedFilesForObject:(NSDictionary *)object withContext:(NSManagedObjectContext *)context;
- (NSMutableArray *)saveNewData:(NSArray *)jsonObjects withDeviceId:(NSString *)deviceId withParameters:(NSDictionary *)responseParameters withContext:(NSManagedObjectContext *)context;
- (void)processSendResponse:(NSArray *)jsonResponse withContext:(NSManagedObjectContext *)context;
- (SyncEntity *)processResponseForObject:(NSDictionary *)object withContext:(NSManagedObjectContext *)context;
- (NSDictionary *)serializeObject:(NSObject *)object withContext:(NSManagedObjectContext *)context;
- (id)saveObject:(NSDictionary *)object withDeviceId:(NSString *)deviceId withContext:(NSManagedObjectContext *)context;
- (void)postEvent:(NSArray *)objects withBus:(AsyncBus *)bus;
- (NSString *)getNotificationName;
- (NSUInteger)getDelay;
- (void)setDataSyncHelper:(DataSyncHelper *)dataSyncHelper;

@end
