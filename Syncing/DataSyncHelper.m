//
//  DataSyncHelper.m
//  Syncing
//
//  Created by Rodrigo Suhr on 2/20/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "DataSyncHelper.h"
#import "SyncManager.h"
#import "SharedModelContext.h"
#import "CustomException.h"

@interface DataSyncHelper()

@property (nonatomic, readwrite) ServerComm *serverComm;
@property (nonatomic, readwrite) ThreadChecker * threadChecker;
@property (nonatomic, readwrite) SyncConfig *syncConfig;
@property (nonatomic, readwrite) CustomTransactionManager *transactionManager;
@property (nonatomic, readwrite) AsyncBus *bus;

@property BOOL isRunningSync;
@property (strong, readwrite) NSMutableDictionary *partialSyncFlag;

@end

@implementation DataSyncHelper

/**
 * Init with dependency injection.
 */
- (instancetype)initWithServer:(ServerComm *)serverComm
                withThreadChecker:(ThreadChecker *)threadChecker
                withSyncConfig:(SyncConfig *)syncConfig
                withTransactionManager:(CustomTransactionManager *)transactionManager
                withBus:(AsyncBus *)bus
{
    self = [super init];
    if (self)
    {
        self.serverComm = serverComm;
        self.threadChecker = threadChecker;
        self.syncConfig = syncConfig;
        self.transactionManager = transactionManager;
        self.bus = bus;
        self.isRunningSync = NO;
        self.partialSyncFlag = [[NSMutableDictionary alloc]init];
    }
    return self;
}

/**
 * Init
 */
- (instancetype)initWithContext:(NSManagedObjectContext *)context
{
    [[SharedModelContext sharedModelContext] setSharedModelContext:context];
    return [self initWithServer:[[ServerComm alloc] init]
                 withThreadChecker:[[ThreadChecker alloc] init]
                 withSyncConfig:[[SyncConfig alloc] init]
                 withTransactionManager:[[CustomTransactionManager alloc] init]
                 withBus:[[AsyncBus alloc] init]];
}

/**
 * getDataFromServer
 */
- (BOOL)getDataFromServer
{
    NSString *threadId = [self.threadChecker setNewThreadId];
    NSString *token = [self.syncConfig getAuthToken];
    
    if (token == nil || token.length == 0)
    {
        [self.threadChecker removeThreadId:threadId];
        return NO;
    }
    
    NSDictionary *data = @{@"token":token,
                           @"timestamp":[self.syncConfig getTimestamp]};
    
    NSDictionary *jsonResponse = [self.serverComm post:[self.syncConfig getGetDataUrl] withData:data];
    
    NSString *timestamp = [jsonResponse valueForKey:@"timestamp"];
    
    if ([self processGetDataResponse:threadId withJsonResponse:jsonResponse withTimestamp:timestamp])
    {
        [self.threadChecker removeThreadId:threadId];
        return YES;
    }
    else
    {
        [self.threadChecker removeThreadId:threadId];
        return NO;
    }
}

/***
 * getDataFromServer
 */
- (BOOL)getDataFromServer:(NSString *)identifier withParameters:(NSMutableDictionary *)parameters
{
    NSString *threadId = [self.threadChecker setNewThreadId];
    NSString *token = [self.syncConfig getAuthToken];
    
    if (token == nil || token.length == 0)
    {
        [self.threadChecker removeThreadId:threadId];
        return NO;
    }
    
    [parameters setObject:token forKey:@"token"];
    
    NSDictionary *jsonResponse = [self.serverComm post:[self.syncConfig getGetDataUrlForModel:identifier] withData:parameters];
    
    if ([self processGetDataResponse:threadId withJsonResponse:jsonResponse withTimestamp:nil])
    {
        [self.threadChecker removeThreadId:threadId];
        return YES;
    }
    else
    {
        [self.threadChecker removeThreadId:threadId];
        return NO;
    }
}

/***
 * sendDataToServer
 */
- (BOOL)sendDataToServer
{
    NSString *threadId = [self.threadChecker setNewThreadId];
    NSString *token = [self.syncConfig getAuthToken];
    
    if (token == nil || token.length == 0)
    {
        [self.threadChecker removeThreadId:threadId];
        return NO;
    }
    
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    [data setObject:token forKey:@"token"];
    [data setObject:[self.syncConfig getTimestamp] forKey:@"timestamp"];
    [data setObject:[self.syncConfig getDeviceId] forKey:@"device_id"];
    NSUInteger nmbrMetadata = [data count];
    
    NSMutableArray *files = [[NSMutableArray alloc] init];
    NSArray *modifiedData = [[NSArray alloc] init];
    
    for (id<SyncManager> syncManager in [self.syncConfig getSyncManagers])
    {
        if (![syncManager hasModifiedData])
        {
            continue;
        }
        
        modifiedData = [syncManager getModifiedData];
        
        if ([syncManager shouldSendSingleObject])
        {
            for (NSDictionary *object in modifiedData)
            {
                NSMutableDictionary *partialData = [[data copy] mutableCopy];
                NSArray *singleItemArray = [NSArray arrayWithObject:object];
                [partialData setObject:singleItemArray forKey:[syncManager getIdentifier]];
                NSArray *partialFiles = [syncManager getModifiedFilesForObject:object];
                NSLog(@"Syncing - Enviando item %@", object);
                NSDictionary *jsonResponse = [self.serverComm post:[self.syncConfig getSendDataUrl] withData:partialData withFiles:partialFiles];
                
                if (![self processSendResponse:threadId withJsonResponse:jsonResponse])
                {
                    return NO;
                }
                
                [data setObject:[self.syncConfig getTimestamp] forKey:@"timestamp"];
            }
        }
        else
        {
            [data setObject:modifiedData forKey:[syncManager getIdentifier]];
            [files addObjectsFromArray:[syncManager getModifiedFiles]];
        }
    }
    
    if ([data count] > nmbrMetadata)
    {
        NSDictionary *jsonResponse = [self.serverComm post:[self.syncConfig getSendDataUrl] withData:data withFiles:files];
        
        if ([self processSendResponse:threadId withJsonResponse:jsonResponse])
        {
            [self.threadChecker removeThreadId:threadId];
            [self postSendFinishedEvent];
            return YES;
        }
        else
        {
            [self.threadChecker removeThreadId:threadId];
            return NO;
        }
    }
    else
    {
        [self.threadChecker removeThreadId:threadId];
        [self postSendFinishedEvent];
        return YES;
    }
}

/***
 * processGetDataResponse
 */
- (BOOL)processGetDataResponse:(NSString *)threadId withJsonResponse:(NSDictionary *)jsonResponse withTimestamp:(NSString *)timestamp
{
    [self.transactionManager doInTransaction:^{
        for (id<SyncManager> syncManager in [self.syncConfig getSyncManagers])
        {
  
            NSString *identifier = [syncManager getIdentifier];
            
            NSArray *jsonArray = [jsonResponse objectForKey:identifier];
            
            if (jsonArray != nil)
            {
                NSArray *objects = [syncManager saveNewData:jsonArray withDeviceId:[self.syncConfig getDeviceId]];
                [syncManager postEvent:objects withBus:[self bus]];
            }
        }
        if ([self.threadChecker isValidThreadId:threadId])
        {
            if (timestamp != nil)
            {
                [self.syncConfig setTimestamp:timestamp];
            }
            [self postGetFinishedEvent];
        }
        else
        {
            @throw([InvalidThreadIdException exceptionWithName:@"InvalidThreadId" reason:@"The thread id is invalid." userInfo:nil]);
        }
    } withSyncConfig:[self syncConfig]];
    
    return [self.transactionManager wasSuccessful];
}

/***
 * processSendResponse
 */
- (BOOL)processSendResponse:(NSString *)threadId withJsonResponse:(NSDictionary *)jsonResponse
{
    NSString *timestamp = [jsonResponse valueForKey:@"timestamp"];
    
    [self.transactionManager doInTransaction:^{
        NSArray *syncResponse;
        NSArray *newDataResponse;
        NSArray *iterator = [jsonResponse allKeys];
        
        for (NSString *responseId in iterator)
        {
            id<SyncManager> syncManager = [self.syncConfig getSyncManagerByResponseId:responseId];
            if (syncManager != nil)
            {
                syncResponse = [jsonResponse objectForKey:responseId];
                [syncManager processSendResponse:syncResponse];
            }
            else
            {
                syncManager = [self.syncConfig getSyncManager:responseId];
                if (syncManager != nil)
                {
                    newDataResponse = [jsonResponse objectForKey:responseId];
                    NSArray *objects = [syncManager saveNewData:newDataResponse withDeviceId:[self.syncConfig getDeviceId]];
                    [syncManager postEvent:objects withBus:[self bus]];
                }
            }
        }
        
        if ([self.threadChecker isValidThreadId:threadId])
        {
            [self.syncConfig setTimestamp:timestamp];
        }
        else
        {
            @throw([InvalidThreadIdException exceptionWithName:@"InvalidThreadId" reason:@"The thread id is invalid." userInfo:nil]);
        }
        
    } withSyncConfig:[self syncConfig]];
    
    return [self.transactionManager wasSuccessful];
}

/**
 * fullSynchronousSync
 */
- (BOOL)fullSynchronousSync
{
    if ([self isRunningSync])
    {
        NSLog(@"Sync already running");
        return NO;
    }
    
    NSLog(@"STARTING NEW SYNC");
    BOOL completed = NO;
    self.isRunningSync = YES;
    
    @try
    {
        completed = [self getDataFromServer];
        if (completed && [self hasModifiedData])
        {
            completed = [self sendDataToServer];
        }
    }
    @finally
    {
        self.isRunningSync = NO;
    }
    
    if (completed)
    {
        [self postSyncFinishedEvent];
        return YES;
    }
    else
    {
        return NO;
    }
}

/**
 * fullAsynchronousSync
 */
- (void)fullAsynchronousSync
{
    if (![self isRunningSync])
    {
        NSLog(@"Running new FullSyncAsyncTask");
        [self fullSyncAsyncTask];
    }
}

/**
 * partialAsynchronousSync
 */
- (void)partialAsynchronousSync:(NSString *)identifier withParameters:(NSDictionary *)parameters
{
    NSNumber *flag = [self.partialSyncFlag objectForKey:identifier];
    if (flag != nil && [flag boolValue])
    {
        [self partialSyncTask:identifier withParameters:parameters];
    }
}

/**
 * hasModifiedData
 */
- (BOOL)hasModifiedData
{
    for (id<SyncManager> syncManager in [self.syncConfig getSyncManagers])
    {
        if ([syncManager hasModifiedData])
        {
            return YES;
        }
    }
    return NO;
}

/**
 * stopSyncThreads
 */
- (void)stopSyncThreads
{
    [self.threadChecker clear];
}

/**
 * postSendFinishedEvent
 */
- (void)postSendFinishedEvent
{
    [self.bus post:[[SendFinishedEvent alloc] init] withNotificationname:@"postSendFinishedEvent"];
}

/**
 * postGetFinishedEvent
 */
- (void)postGetFinishedEvent
{
    [self.bus post:[[GetFinishedEvent alloc] init] withNotificationname:@"postGetFinishedEvent"];
}

/**
 * postSyncFinishedEvent
 */
- (void)postSyncFinishedEvent
{
    [self.bus post:[[SyncFinishedEvent alloc] init] withNotificationname:@"postSyncFinishedEvent"];
    NSLog(@"SyncFinishedEvent");
}

/**
 * postBackgroundSyncError
 */
- (void)postBackgroundSyncError:(NSException *)error
{
    [self.bus post:[[BackgroundSyncError alloc] initWithException:error] withNotificationname:@"postBackgroundSyncError"];
}

/**
 * fullSyncAsyncTask
 */
-(void)fullSyncAsyncTask
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @try
        {
            [self fullSynchronousSync];
        }
        @catch (HttpException *exception)
        {
            [self postBackgroundSyncError:exception];
        }
    });
}

/**
 * partialSyncTask
 */
-(void)partialSyncTask:(NSString *)identifier withParameters:(NSDictionary *)parameters
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self.partialSyncFlag setObject:[NSNumber numberWithBool:YES] forKey:identifier];
        @try
        {
            [self getDataFromServer:identifier withParameters:[parameters mutableCopy]];
        }
        @catch (HttpException *exception)
        {
            [self postBackgroundSyncError:exception];
        }
        
        dispatch_async( dispatch_get_main_queue(), ^{
            [self.partialSyncFlag setObject:[NSNumber numberWithBool:NO] forKey:identifier];
        });
    });
}

@end

@implementation SendFinishedEvent
@end

@implementation GetFinishedEvent
@end

@implementation SyncFinishedEvent
@end

@interface BackgroundSyncError()

@property (strong, readwrite) NSException *exception;

@end

@implementation BackgroundSyncError

/**
 * initWithException
 */
- (id)initWithException:(NSException *)exception
{
    if(self = [super init])
    {
        self.exception = exception;
    }
    
    return self;
}

/**
 * getError
 */
- (NSException *)getError
{
    return self.exception;
}

@end
