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
                withBus:(AsyncBus *)bus;
- (void)fullAsynchronousSync;
- (BOOL)fullSynchronousSync;
- (void)partialAsynchronousSync:(NSString *)identifier;
- (void)partialAsynchronousSync:(NSString *)identifier
                 withParameters:(NSDictionary *)parameters;
- (void)partialAsynchronousSync:(NSString *)identifier
                 withParameters:(NSDictionary *)parameters
            withSuccessCallback:(void(^)(void))successCallback
               withFailCallback:(void(^)(void))failCallback;
- (BOOL)partialSynchronousSync:(NSString *)identifier withDelay:(BOOL)allowDelay;
- (void)stopSyncThreads;
- (BOOL)canRunSyncWithIdentifier:(NSString *)identifier withParameters:(NSDictionary *)params;

// Exposed for tests
- (BOOL)getDataFromServer;
- (BOOL)getDataFromServer:(NSString *)identifier withParameters:(NSMutableDictionary *)parameters;
- (BOOL)sendDataToServer:(NSString *)identifier;
- (void)postGetFinishedEvent;
- (void)postSendFinishedEvent;
- (void)postSyncFinishedEvent;
- (void)addToEventQueue:(NSString *)identifier withObjects:(NSArray *)objects;

@end

@interface SendFinishedEvent : NSObject
@end

@interface GetFinishedEvent : NSObject
@end

@interface SyncFinishedEvent : NSObject
@end

@interface PartialSyncFinishedEvent : NSObject
@end

@interface WillStartSyncEvent : NSObject
@end

@interface BackgroundSyncError : NSObject

- (id)initWithException:(NSException *)exception;
- (NSException *)getError;

@end