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
#import "SyncingInjection.h"
#import <Raven/RavenClient.h>

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
                withContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if (self)
    {
        [[SharedModelContext sharedModelContext] setSharedModelContext:context];
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
 * getDataFromServer
 */
- (BOOL)getDataFromServer
{
    return [self getDataFromServer:nil withParameters:[[NSMutableDictionary alloc] init] withSendTimestamp:YES];
}

/**
 * getDataFromServer
 */
- (BOOL)getDataFromServer:(NSString *)identifier
{
    return [self getDataFromServer:identifier withParameters:[[NSMutableDictionary alloc] init] withSendTimestamp:YES];
}

/**
 * getDataFromServer
 */
- (BOOL)getDataFromServer:(NSString *)identifier withParameters:(NSMutableDictionary *)parameters
{
    return [self getDataFromServer:identifier withParameters:parameters withSendTimestamp:NO];
}

/***
 * getDataFromServer
 */
- (BOOL)getDataFromServer:(NSString *)identifier withParameters:(NSMutableDictionary *)parameters withSendTimestamp:(BOOL)sendTimestamp
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
        if (![syncManager hasModifiedData])
        {
            continue;
        }
        
        modifiedData = [syncManager getModifiedData];
        
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
                    NSArray *partialFiles = [syncManager getModifiedFilesForObject:object];
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
                [files addObjectsFromArray:[syncManager getModifiedFiles]];
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
                NSArray *objects = [syncManager saveNewData:jsonArray withDeviceId:[self.syncConfig getDeviceId] withParameters:jsonObject];
                [syncManager postEvent:objects withBus:[self bus]];
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
    } withSyncConfig:[self syncConfig]];
    
    return [self.transactionManager wasSuccessful];
}

/***
 * processSendResponse
 */
- (BOOL)processSendResponse:(NSString *)threadId withJsonResponse:(NSDictionary *)jsonResponse
{
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
                [syncManager processSendResponse:syncResponse];
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
                    NSArray *objects = [syncManager saveNewData:newData withDeviceId:[self.syncConfig getDeviceId] withParameters:newDataResponse];
                    [syncManager postEvent:objects withBus:[self bus]];
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
        
    } withSyncConfig:[self syncConfig]];
    
    return [self.transactionManager wasSuccessful];
}

/**
 * internalRunSynchronousSync
 */
- (BOOL)internalRunSynchronousSync:(NSString *)identifier
{
    NSLog(@"STARTING NEW SYNC");
    BOOL completed = NO;
    
    if (identifier != nil)
    {
        [_partialSyncFlag setObject:[NSNumber numberWithBool:YES] forKey:identifier];
    }
    else
    {
        _isRunningSync = YES;
    }
    
    @try
    {
        NSLog(@"GETTING DATA FROM SERVER");
        completed = [self getDataFromServer:identifier];
        NSLog(@"GOT DATA FROM SERVER");
        if (completed && [self hasModifiedData])
        {
            completed = [self sendDataToServer:identifier];
        }
    }
    @catch (CustomException *e)
    {
        @throw e;
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
    @catch (Http408Exception *e | Http502Exception *e | Http503Exception *e)
    {
        // Server is overloaded - exponential backoff
        if (numberAttempts < 4)
        {
            double waitTimeSeconds = 0.5 * (pow(2, numberAttempts) - 1);
            waitTimeSeconds += drand48();
            [NSThread sleepForTimeInterval:waitTimeSeconds];
            return [self fullSynchronousSync];
        }
        else
        {
            numberAttempts = 0;
            @throw [[Http408Exception alloc] init];
        }
    }
    @catch (TimeoutException *e)
    {
        [self postBackgroundSyncError:e];
        [_syncConfig requestSync];
    }
    @catch (CustomException *e)
    {
        @throw e;
    }
    @catch (NSException *e)
    {
        [self sendCaughtException:e];
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
- (BOOL)partialSynchronousSync:(NSString *)identifier
{
    return [self runSynchronousSync:identifier];
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
    [self partialAsynchronousSync:identifier withParameters:nil];
}

/**
 * partialAsynchronousSync
 */
- (void)partialAsynchronousSync:(NSString *)identifier withParameters:(NSDictionary *)parameters
{
    NSNumber *flag = [self.partialSyncFlag objectForKey:identifier];
    if (flag == nil || ![flag boolValue] || (parameters == nil && _isRunningSync))
    {
        BOOL sendModified = parameters == nil;
        [self partialSyncTask:identifier withParameters:parameters withSendModified:sendModified];
    }
    else
    {
        NSLog(@"Sync already running");
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
- (void)partialSyncTask:(NSString *)identifier withParameters:(NSDictionary *)parameters withSendModified:(BOOL)sendModified
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @try
        {
            if (sendModified)
            {
                [self partialSynchronousSync:identifier];
            }
            else
            {
                [self.partialSyncFlag setObject:[NSNumber numberWithBool:YES] forKey:identifier];
                [self getDataFromServer:identifier withParameters:[parameters mutableCopy]];
            }
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

- (void)sendCaughtException:(NSException *)exception
{
    [[RavenClient sharedClient] captureException:exception method:__FUNCTION__ file:__FILE__ line:__LINE__ sendNow:YES];
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
