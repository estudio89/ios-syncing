//
//  DataSyncHelper.h
//  Syncing
//
//  Created by Rodrigo Suhr on 2/20/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "ServerComm.h"
#import "ThreadChecker.h"
#import "SyncConfig.h"
#import "CustomTransactionManager.h"
#import "AsyncBus.h"
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface DataSyncHelper : NSObject

@property (nonatomic, readonly) ServerComm *serverComm;
@property (nonatomic, readonly) ThreadChecker *threadChecker;
@property (nonatomic, readonly) SyncConfig *syncConfig;
@property (nonatomic, readonly) CustomTransactionManager *transactionManager;
@property (nonatomic, readonly) AsyncBus *bus;

+ (DataSyncHelper *)getInstance;
- (instancetype)initWithServer:(ServerComm *)serverComm
                withThreadChecker:(ThreadChecker *)threadChecker
                withSyncConfig:(SyncConfig *)syncConfig
                withTransactionManager:(CustomTransactionManager *)transactionManager
                withBus:(AsyncBus *)bus
                withContext:(NSManagedObjectContext *)context;

- (BOOL)getDataFromServer;
- (BOOL)getDataFromServer:(NSString *)identifier withParameters:(NSMutableDictionary *)parameters;
- (BOOL)sendDataToServer;
- (BOOL)fullSynchronousSync;
- (void)fullAsynchronousSync;
- (void)partialAsynchronousSync:(NSString *)identifier withParameters:(NSDictionary *)parameters;
- (void)postSyncFinishedEvent;
- (void)postGetFinishedEvent;
- (void)postSendFinishedEvent;

- (void)setThreadChecker:(ThreadChecker *)threadChecker;
- (void)setServerComm:(ServerComm *)serverComm;
- (void)setSyncConfig:(SyncConfig *)syncConfig;
- (void)setTransactionManager:(CustomTransactionManager *)transactionManager;
- (void)setBus:(AsyncBus *)bus;

@end

@interface SendFinishedEvent : NSObject
@end

@interface GetFinishedEvent : NSObject
@end

@interface SyncFinishedEvent : NSObject
@end

@interface BackgroundSyncError : NSObject

- (id)initWithException:(NSException *)exception;
- (NSException *)getError;

@end