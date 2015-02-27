//
//  SyncConfig.m
//  Syncing
//
//  Created by Rodrigo Suhr on 2/22/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "SyncConfig.h"

@interface SyncConfig()

@property (nonatomic, strong, readwrite) NSString *configFile;
@property (nonatomic, strong, readwrite) NSMutableDictionary *syncManagersByIdentifier;
@property (nonatomic, strong, readwrite) NSMutableDictionary *syncManagersByResponseIdentifier;
@property (nonatomic, strong, readwrite) NSString *mGetDataUrl;
@property (nonatomic, strong, readwrite) NSString *mSendDataUrl;
@property (nonatomic, strong, readwrite) NSString *mAuthenticateUrl;
@property (nonatomic, strong, readwrite) NSMutableDictionary *mModelGetDataUrls;

@end

@implementation SyncConfig

/**
 init
 */
- (id)init
{
    if (self = [super init])
    {
        self.syncManagersByIdentifier = [[NSMutableDictionary alloc] init];
        self.syncManagersByResponseIdentifier = [[NSMutableDictionary alloc] init];
        self.mModelGetDataUrls = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

/**
 setConfigFile
 */
- (void)setConfigFile:(NSString *)filename
{
    self.configFile = filename;
    [self loadSettings];
    [self setupSyncing];
}

/**
 loadSettings
 */
- (void)loadSettings
{
    
}

- (void)setupSyncing
{
    
}

- (NSString *)getAuthToken
{
    return @"";
}

- (NSString *)getTimestamp
{
    return @"";
}

/**
 getGetDataUrl
 */
- (NSString *)getGetDataUrl
{
    return self.mGetDataUrl;
}

/**
 getGetDataUrlForModel
 */
- (NSString *)getGetDataUrlForModel:(NSString *)identifier
{
    NSString *url = [self.mModelGetDataUrls valueForKey:identifier];
    
    if (url == nil)
    {
        @throw([NSException exceptionWithName:@"URL not found" reason:@"URL not found for the identifier." userInfo:nil]);
    }
    
    return url;
}

- (NSString *)getDeviceId
{
    return @"";
}

/**
 getSyncManagers
 */
- (NSArray *)getSyncManagers
{
    return [self.syncManagersByIdentifier allValues];
}

/**
 getSendDataUrl
 */
- (NSString *)getSendDataUrl
{
    return self.mSendDataUrl;
}

- (void)setTimestamp:(NSString *)timestamp
{
    
}

/**
 getSyncManagerByResponseId
 */
- (id<SyncManager>)getSyncManagerByResponseId:(NSString *)responseId
{
    return [self.syncManagersByResponseIdentifier objectForKey:responseId];
}

/**
 getSyncManager
 */
- (id<SyncManager>)getSyncManager:(NSString *)identifier
{
    return [self.syncManagersByIdentifier objectForKey:identifier];
}

/**
 getDatabase
 */
- (DatabaseProvider *)getDatabase
{
    return [[DatabaseProvider alloc] init];
}

@end
