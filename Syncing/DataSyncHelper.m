//
//  DataSyncHelper.m
//  Syncing
//
//  Created by Rodrigo Suhr on 2/20/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "DataSyncHelper.h"
#import "SyncManager.h"

@interface DataSyncHelper()

@property (nonatomic, strong, readwrite) ServerComm *serverComm;
@property (nonatomic, strong, readwrite) ThreadChecker * threadChecker;
@property (nonatomic, strong, readwrite) SyncConfig *syncConfig;

@end

@implementation DataSyncHelper

/**
 Init with dependency injection.
 */
- (instancetype)initWithServer:(ServerComm *)serverComm
                withThreadChecker:(ThreadChecker *)threadChecker
                withSyncConfig:(SyncConfig *)syncConfig
{
    self = [super init];
    if (self)
    {
        self.serverComm = serverComm;
        self.threadChecker = threadChecker;
        self.syncConfig = syncConfig;
    }
    return self;
}

/**
 Init
 */
- (instancetype)init
{
    return [self initWithServer:[[ServerComm alloc] init]
                 withThreadChecker:[[ThreadChecker alloc] init]
                 withSyncConfig:[[SyncConfig alloc] init]];
}

/**
 getDataFromServer
 */
- (BOOL)getDataFromServer
{
    NSString *threadId = [self.threadChecker setNewThreadId];
    NSString *token = [self.syncConfig getAuthToken];
    
    if (token == (id)[NSNull null] || token.length == 0)
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
 getDataFromServer
 */
- (BOOL)getDataFromServer:(NSString *)identifier withParameters:(NSMutableDictionary *)parameters
{
    NSString *threadId = [self.threadChecker setNewThreadId];
    NSString *token = [self.syncConfig getAuthToken];
    
    if (token == (id)[NSNull null] || token.length == 0)
    {
        [self.threadChecker removeThreadId:threadId];
        return NO;
    }
    
    [parameters setValue:token forKey:@"token"];
    
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
 sendDataToServer
 */
- (BOOL)sendDataToServer
{
    NSString *threadId = [self.threadChecker setNewThreadId];
    NSString *token = [self.syncConfig getAuthToken];
    
    if (token == (id)[NSNull null] || token.length == 0)
    {
        [self.threadChecker removeThreadId:threadId];
        return NO;
    }
    
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    [data setObject:token forKey:@"token"];
    [data setObject:[self.syncConfig getTimestamp] forKey:@"timestamp"];
    [data setObject:[self.syncConfig getDeviceId] forKey:@"device_id"];
    NSUInteger nmbrMetadata = [data count];
    
    NSArray *files = [[NSArray alloc] init];
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
                NSMutableDictionary *partialData = data;
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
            files = [syncManager getModifiedFiles];
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
 processGetDataResponse
 */
- (BOOL)processGetDataResponse:(NSString *)threadId withJsonResponse:(NSDictionary *)jsonResponse withTimestamp:(NSString *)timestamp
{
    return YES;
}

/***
 processSendResponse
 */
- (BOOL)processSendResponse:(NSString *)threadId withJsonResponse:(NSDictionary *)jsonResponse
{
    return YES;
}

- (void)postSendFinishedEvent
{
    
}

@end
