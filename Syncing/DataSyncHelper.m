//
//  DataSyncHelper.m
//  Syncing
//
//  Created by Rodrigo Suhr on 2/20/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "DataSyncHelper.h"
#import "SyncManager.h"
#import "CustomException.h"
#import "SyncingInjection.h"
#import <Raven/RavenClient.h>
#include <stdlib.h>

#define ARC4RANDOM_MAX 0x100000000

@interface DataSyncHelper()

@property (nonatomic, readwrite) ServerComm *serverComm;
@property (nonatomic, readwrite) ThreadChecker * threadChecker;
@property (nonatomic, readwrite) SyncConfig *syncConfig;
@property (nonatomic, readwrite) CustomTransactionManager *transactionManager;
@property (nonatomic, readwrite) AsyncBus *bus;

@property BOOL isRunningSync;
@property (strong, readwrite) NSMutableDictionary *partialSyncFlag;
@property (nonatomic, strong) NSMutableDictionary *eventQueue;

@end

@implementation DataSyncHelper

static int numberAttempts;

/**
 * getInstance
 */
+ (DataSyncHelper *)getInstance
{
    return [SyncingInjection get:[DataSyncHelper class]];
}

/**
 * initialize
 */
+ (void)initialize
{
    numberAttempts = 0;
    // initializing drand48 with a seed
    srand(arc4random());
}

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
        self.partialSyncFlag = [[NSMutableDictionary alloc] init];
        _eventQueue = [[NSMutableDictionary alloc] init];
    }
    return self;
}

/**
 * getDataFromServer
 */
- (BOOL)getDataFromServer
{
    return [self getDataFromServer:nil
                    withParameters:[[NSMutableDictionary alloc] init]
                 withSendTimestamp:YES];
}

/**
 * getDataFromServer
 */
- (BOOL)getDataFromServer:(NSString *)identifier
{
    return [self getDataFromServer:identifier
                    withParameters:[[NSMutableDictionary alloc] init]
                 withSendTimestamp:YES];
}

/**
 * getDataFromServer
 */
- (BOOL)getDataFromServer:(NSString *)identifier withParameters:(NSMutableDictionary *)parameters
{
    return [self getDataFromServer:identifier
                    withParameters:parameters
                 withSendTimestamp:NO];
}

/***
 * getDataFromServer
 */
- (BOOL)getDataFromServer:(NSString *)identifier
           withParameters:(NSMutableDictionary *)parameters
        withSendTimestamp:(BOOL)sendTimestamp
{
    NSString *threadId = [self.threadChecker setNewThreadId];
    NSString *token = [self.syncConfig getAuthToken];
    
    if (token == nil || token.length == 0)
    {
        [self.threadChecker removeThreadId:threadId];
        return NO;
    }
    
    @try
    {
        [parameters setObject:token forKey:@"token"];
        if (sendTimestamp)
        {
            if (identifier != nil)
            {
                [parameters setObject:[_syncConfig getTimestamp:identifier] forKey:@"timestamps"];
            }
            else
            {
                [parameters setObject:[_syncConfig getTimestamps] forKey:@"timestamps"];
            }
        }
    }
    @catch (CustomException *exception)
    {
        @throw exception;
    }
    
    NSString *url = nil;
    
    @try
    {
        url = identifier != nil ? [_syncConfig getGetDataUrlForModel:identifier] : [_syncConfig getGetDataUrl];
    }
    @catch (CustomException *exception)
    {
        @throw exception;
    }
    
    NSDictionary *jsonResponse = [self.serverComm post:url withData:parameters];
    NSDictionary *timestamps = nil;
    
    @try
    {
        timestamps = sendTimestamp ? [jsonResponse objectForKey:@"timestamps"] : nil;
    }
    @catch (CustomException *exception)
    {
        @throw exception;
    }
    
    if ([self processGetDataResponse:threadId withJsonResponse:jsonResponse withTimestamp:timestamps])
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
    return [self sendDataToServer:nil];
}

/***
 * sendDataToServer
 */
- (BOOL)sendDataToServer:(NSString *)identifier
{
    NSManagedObjectContext *context = [self.syncConfig getContext];
    NSString *threadId = [self.threadChecker setNewThreadId];
    NSString *token = [self.syncConfig getAuthToken];
    
    if (token == nil || token.length == 0)
    {
        [self.threadChecker removeThreadId:threadId];
        return NO;
    }
    
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    @try
    {
        [data setObject:token forKey:@"token"];
        [data setObject:identifier == nil ? [_syncConfig getTimestamps] : [_syncConfig getTimestamp:identifier] forKey:@"timestamps"];
        [data setObject:[self.syncConfig getDeviceId] forKey:@"device_id"];
    }
    @catch (CustomException *exception)
    {
        @throw exception;
    }
    
    NSUInteger nmbrMetadata = [data count];
    
    NSMutableArray *files = [[NSMutableArray alloc] init];
    NSArray *syncManagers = nil;
    
    if (identifier == nil)
    {
        syncManagers = [_syncConfig getSyncManagers];
    }
    else
    {
        syncManagers = [NSArray arrayWithObject:[_syncConfig getSyncManager:identifier]];
    }
    
    NSArray *modifiedData = [[NSArray alloc] init];
    
    for (id<SyncManager> syncManager in syncManagers)
    {
        if (![syncManager hasModifiedDataWithContext:context])
        {
            continue;
        }
        
        modifiedData = [syncManager getModifiedDataWithContext:context];
        
        if ([syncManager shouldSendSingleObject])
        {
            @try
            {
                NSMutableDictionary *timestamps = [data objectForKey:@"timestamps"];
                [timestamps removeObjectForKey:[syncManager getIdentifier]];
                [data setObject:timestamps forKey:@"timestamps"];
            }
            @catch (CustomException *exception)
            {
                @throw exception;
            }
            
            @try
            {
                for (NSDictionary *object in modifiedData)
                {
                    NSMutableDictionary *partialData = [[data copy] mutableCopy];
                    NSArray *singleItemArray = [NSArray arrayWithObject:object];
                    [partialData setObject:singleItemArray forKey:[syncManager getIdentifier]];
                    [partialData setObject:[_syncConfig getTimestamp:[syncManager getIdentifier]] forKey:@"timestamps"];
                    NSArray *partialFiles = [syncManager getModifiedFilesForObject:object withContext:context];
                    NSLog(@"Syncing - Enviando item %@", object);
                    NSDictionary *jsonResponse = [self.serverComm post:[self.syncConfig getSendDataUrl] withData:partialData withFiles:partialFiles];
                    
                    if (![self processSendResponse:threadId withJsonResponse:jsonResponse])
                    {
                        return NO;
                    }
                }
            }
            @catch (CustomException *exception)
            {
                @throw exception;
            }
        }
        else
        {
            @try
            {
                [data setObject:modifiedData forKey:[syncManager getIdentifier]];
                [files addObjectsFromArray:[syncManager getModifiedFilesWithContext:context]];
            }
            @catch (CustomException *exception)
            {
                @throw exception;
            }
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
- (BOOL)processGetDataResponse:(NSString *)threadId withJsonResponse:(NSDictionary *)jsonResponse withTimestamp:(NSDictionary *)timestamps
{
    NSManagedObjectContext *context = [self.syncConfig getContext];
    
    [self.transactionManager doInTransaction:^{
        for (id<SyncManager> syncManager in [self.syncConfig getSyncManagers])
        {
            NSString *identifier = [syncManager getIdentifier];
            NSMutableDictionary *jsonObject = [[jsonResponse objectForKey:identifier] mutableCopy];
            
            if (jsonObject != nil)
            {
                NSArray *jsonArray = [jsonObject objectForKey:@"data"];
                
                if (jsonArray == nil)
                {
                    jsonArray = [[NSArray alloc] init];
                }
                
                [jsonObject removeObjectForKey:@"data"];
                NSArray *objects = [syncManager saveNewData:jsonArray withDeviceId:[self.syncConfig getDeviceId] withParameters:jsonObject withContext:context];
                [self addToEventQueue:[syncManager getIdentifier] withObjects:objects];
            }
        }
        
        if ([self.threadChecker isValidThreadId:threadId])
        {
            if (timestamps != nil)
            {
                [self.syncConfig setTimestamps:timestamps];
            }
            [self postGetFinishedEvent];
        }
        else
        {
            @throw([InvalidThreadIdException exceptionWithName:@"InvalidThreadId" reason:@"The thread id is invalid." userInfo:nil]);
        }
    } withContext:context];
    
    if ([self.transactionManager wasSuccessful])
    {
        [self postEventQueue];
    }
    
    return [self.transactionManager wasSuccessful];
}

/***
 * processSendResponse
 */
- (BOOL)processSendResponse:(NSString *)threadId withJsonResponse:(NSDictionary *)jsonResponse
{
    NSManagedObjectContext *context = [self.syncConfig getContext];
    NSDictionary *timestamps = [jsonResponse objectForKey:@"timestamps"];
    
    [self.transactionManager doInTransaction:^{
        NSArray *syncResponse;
        NSMutableDictionary *newDataResponse;
        NSArray *newData;
        NSArray *iterator = [jsonResponse allKeys];
        
        for (NSString *responseId in iterator)
        {
            id<SyncManager> syncManager = [self.syncConfig getSyncManagerByResponseId:responseId];
            if (syncManager != nil)
            {
                syncResponse = [jsonResponse objectForKey:responseId];
                [syncManager processSendResponse:syncResponse withContext:context];
            }
            else
            {
                syncManager = [self.syncConfig getSyncManager:responseId];
                if (syncManager != nil)
                {
                    newDataResponse = [[jsonResponse objectForKey:responseId] mutableCopy];
                    newData = [newDataResponse objectForKey:@"data"];
                    if (newData == nil)
                    {
                        newData = [[NSArray alloc] init];
                    }
                    [newDataResponse removeObjectForKey:@"data"];
                    NSArray *objects = [syncManager saveNewData:newData withDeviceId:[self.syncConfig getDeviceId] withParameters:newDataResponse withContext:context];
                    [self addToEventQueue:[syncManager getIdentifier] withObjects:objects];
                }
            }
        }
        
        if ([self.threadChecker isValidThreadId:threadId])
        {
            [self.syncConfig setTimestamps:timestamps];
        }
        else
        {
            @throw([InvalidThreadIdException exceptionWithName:@"InvalidThreadId" reason:@"The thread id is invalid." userInfo:nil]);
        }
        
    } withContext:context];
    
    if ([self.transactionManager wasSuccessful])
    {
        [self postEventQueue];
    }
    
    return [self.transactionManager wasSuccessful];
}

/**
 * internalRunSynchronousSync
 */
- (BOOL)internalRunSynchronousSync:(NSString *)identifier
{
    NSLog(@"STARTING NEW SYNC");
    BOOL completed = NO;
    [self postWillStartSyncEvent];
    
    if (identifier != nil)
    {
        // Impedindo que uma thread parcial rode enquanto uma thread full esteja rodando
        if (_isRunningSync) {
            return NO;
        }
        [_partialSyncFlag setObject:[NSNumber numberWithBool:YES] forKey:identifier];
    }
    else
    {
        _isRunningSync = YES;
    }
    
    @try
    {
        NSLog(@"GETTING DATA FROM SERVER. Identifier: %@", identifier);
        completed = [self getDataFromServer:identifier];
        NSLog(@"GOT DATA FROM SERVER. Identifier: %@, Completed: %hhdd", identifier, completed);
        if (completed && [self hasModifiedData])
        {
            completed = [self sendDataToServer:identifier];
        }
    }
    @finally
    {
        if (identifier != nil)
        {
            [_partialSyncFlag setObject:[NSNumber numberWithBool:NO] forKey:identifier];
        }
        else
        {
            _isRunningSync = NO;
        }
    }
    
    if (completed)
    {
        if (identifier != nil)
        {
            [self postPartialSyncFinishedEvent];
        }
        else
        {
            [self postSyncFinishedEvent];
        }
        return YES;
    }
    else
    {
        return NO;
    }
}

/**
 * runSynchronousSync
 */
- (BOOL)runSynchronousSync:(NSString *)identifier
{
    @try
    {
        numberAttempts += 1;
        BOOL response = [self internalRunSynchronousSync:identifier];
        numberAttempts = 0;
        return response;
    }
    @catch (NSException *e)
    {
        NSArray *retryExceptions = @[[Http408Exception class],
                                     [Http502Exception class],
                                     [Http503Exception class],
                                     [Http504Exception class]];
        
        NSArray *errorExceptions = @[[TimeoutException class],
                                     [Http403Exception class],
                                     [ConnectionErrorException class]];
        
        if ([retryExceptions containsObject:[e class]]) {
            // Server is overloaded - exponential backoff
            if (numberAttempts < 4)
            {
                double waitTimeSeconds = 0.5 * (pow(2, numberAttempts) - 1);
                waitTimeSeconds += drand48();
                [NSThread sleepForTimeInterval:waitTimeSeconds];
                return [self runSynchronousSync:identifier];
            }
            else
            {
                numberAttempts = 0;
                @throw([Http408Exception exceptionWithName:@"Http request timeout" reason:@"The http request timed out." userInfo:nil]);
            }
        } else if ([errorExceptions containsObject:[e class]]) {
            [self postBackgroundSyncError:e];
            [_syncConfig requestSync];
        } else {
            [self sendCaughtException:e];
        }
    }
    
    return NO;
}

/**
 * fullSynchronousSync
 */
- (BOOL)fullSynchronousSync
{
    return [self runSynchronousSync:nil];
}

/**
 * partialSynchronousSync
 */
- (BOOL)partialSynchronousSync:(NSString *)identifier withDelay:(BOOL)allowDelay
{
    id<SyncManager> sm = [_syncConfig getSyncManager:identifier];
    
    if ([sm getDelay] > 0 && allowDelay) {
        double delay = ((double)arc4random() / ARC4RANDOM_MAX) * [sm getDelay];
        [self performSelector:@selector(runSynchronousSync:) withObject:identifier afterDelay:delay];
        return true;
    } else {
        return [self runSynchronousSync:identifier];
    }
}

/**
 * fullAsynchronousSync
 */
- (void)fullAsynchronousSync
{
    if ([self canRunSyncWithIdentifier:nil withParameters:nil])
    {
        NSLog(@"Running new FullSyncAsyncTask");
        // Impedindo que uma thread parcial rode enquanto uma thread full esteja rodando
        [self stopSyncThreads];
        [self fullSyncAsyncTask];
    }
    else
    {
        NSLog(@"Sync already running");
    }
}

/**
 * partialAsynchronousSync
 */
- (void)partialAsynchronousSync:(NSString *)identifier
{
    [self partialAsynchronousSync:identifier withParameters:nil withSuccessCallback:nil withFailCallback:nil];
}

/**
 * partialAsynchronousSync
 */
- (void)partialAsynchronousSync:(NSString *)identifier
                 withParameters:(NSDictionary *)parameters
{
    [self partialAsynchronousSync:identifier withParameters:parameters withSuccessCallback:nil withFailCallback:nil];
}

/**
 * partialAsynchronousSync
 */
- (void)partialAsynchronousSync:(NSString *)identifier
                 withParameters:(NSDictionary *)parameters
            withSuccessCallback:(void(^)(void))successCallback
               withFailCallback:(void(^)(void))failCallback
{
    if ([self canRunSyncWithIdentifier:identifier withParameters:parameters])
    {
        BOOL sendModified = parameters == nil;
        [self partialSyncTask:identifier
               withParameters:parameters
             withSendModified:sendModified
          withSuccessCallback:successCallback
             withFailCallback:failCallback];
    }
    else
    {
        NSLog(@"Sync already running");
    }
}

- (BOOL)canRunSyncWithIdentifier:(NSString *)identifier withParameters:(NSDictionary *)params
{
    if (identifier == nil && params == nil) {
        return !_isRunningSync;
    }
    
    NSNumber *flag = [self.partialSyncFlag objectForKey:identifier];
    
    return ((flag == nil || ![flag boolValue]) && !_isRunningSync) || params != nil;
}

/**
 * hasModifiedData
 */
- (BOOL)hasModifiedData
{
    NSManagedObjectContext *context = [self.syncConfig getContext];
    
    for (id<SyncManager> syncManager in [self.syncConfig getSyncManagers])
    {
        if ([syncManager hasModifiedDataWithContext:context])
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
    [self.bus post:[[SendFinishedEvent alloc] init] withNotificationName:@"SendFinishedEvent"];
}

/**
 * postGetFinishedEvent
 */
- (void)postGetFinishedEvent
{
    [self.bus post:[[GetFinishedEvent alloc] init] withNotificationName:@"GetFinishedEvent"];
}

/**
 * postSyncFinishedEvent
 */
- (void)postSyncFinishedEvent
{
    [self.bus post:[[SyncFinishedEvent alloc] init] withNotificationName:@"SyncFinishedEvent"];
    NSLog(@"SyncFinishedEvent");
}

/**
 * postWillStartSyncEvent
 */
- (void)postWillStartSyncEvent
{
    [self.bus post:[[WillStartSyncEvent alloc] init] withNotificationName:@"WillStartSyncEvent"];
    NSLog(@"WillStartSyncEvent");
}

/**
 * postPartialSyncFinishedEvent
 */
- (void)postPartialSyncFinishedEvent
{
    [self.bus post:[[PartialSyncFinishedEvent alloc] init] withNotificationName:@"PartialSyncFinishedEvent"];
    NSLog(@"PartialSyncFinishedEvent");
}

/**
 * postBackgroundSyncError
 */
- (void)postBackgroundSyncError:(NSException *)error
{
    [self.bus post:[[BackgroundSyncError alloc] initWithException:error] withNotificationName:@"BackgroundSyncError"];
}

- (void)addToEventQueue:(NSString *)identifier withObjects:(NSArray *)objects
{
    NSMutableArray *mutableObjects = [objects mutableCopy];
    
    if ([_eventQueue objectForKey:identifier])
    {
        NSMutableArray *queuedObjects = [_eventQueue objectForKey:identifier];
        [queuedObjects addObjectsFromArray:mutableObjects];
        [_eventQueue setObject:queuedObjects forKey:identifier];
    }
    else
    {
        [_eventQueue setObject:mutableObjects forKey:identifier];
    }
}

- (void)postEventQueue
{
    NSArray *eventQueueCopy = [[NSArray alloc] initWithArray:[_eventQueue allKeys] copyItems:YES];
    
    for (NSString *identifier in eventQueueCopy)
    {
        id<SyncManager>syncManager = [_syncConfig getSyncManager:identifier];
        [syncManager postEvent:[_eventQueue objectForKey:identifier] withBus:[self bus]];
        [_eventQueue removeObjectForKey:identifier];
    }
    
    if (_eventQueue.count > 0) {
        [self postEventQueue];
    }
}

/**
 * fullSyncAsyncTask
 */
- (void)fullSyncAsyncTask
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @try
        {
            [self fullSynchronousSync];
        }
        @catch (HttpException *exception)
        {
            [self postBackgroundSyncError:exception];
            NSLog(@"Background sync error");
        }
    });
}

/**
 * partialSyncTask
 */
- (void)partialSyncTask:(NSString *)identifier
         withParameters:(NSDictionary *)parameters
       withSendModified:(BOOL)sendModified
    withSuccessCallback:(void(^)(void))successCallback
       withFailCallback:(void(^)(void))failCallback
{
    __block BOOL success = NO;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @try
        {
            if (sendModified)
            {
                success = [self partialSynchronousSync:identifier withDelay:NO];
            }
            else
            {
                [self.partialSyncFlag setObject:[NSNumber numberWithBool:YES] forKey:identifier];
                success = [self getDataFromServer:identifier withParameters:[parameters mutableCopy]];
            }
        }
        @catch (NSException *e)
        {
            NSArray *exceptions = @[[TimeoutException class],
                                    [ConnectionErrorException class],
                                    [HttpException class]];
            
            if ([exceptions containsObject:[e class]]) {
                [self postBackgroundSyncError:e];
            } else {
                [self sendCaughtException:e];
            }
        }
        
        dispatch_async( dispatch_get_main_queue(), ^{
            [self.partialSyncFlag setObject:[NSNumber numberWithBool:NO] forKey:identifier];
            
            if (successCallback != nil && success) {
                successCallback();
            }
            
            if (failCallback != nil && !success) {
                failCallback();
            }
        });
    });
}

- (void)sendCaughtException:(NSException *)exception
{
    [[RavenClient sharedClient] captureException:exception method:__FUNCTION__ file:__FILE__ line:__LINE__ sendNow:YES];
    [self postBackgroundSyncError:exception];
}

@end

@implementation SendFinishedEvent
@end

@implementation GetFinishedEvent
@end

@implementation SyncFinishedEvent
@end

@implementation PartialSyncFinishedEvent
@end

@implementation WillStartSyncEvent
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
