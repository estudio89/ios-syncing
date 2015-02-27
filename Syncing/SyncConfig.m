//
//  SyncConfig.m
//  Syncing
//
//  Created by Rodrigo Suhr on 2/22/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "SyncConfig.h"

@implementation SyncConfig

- (NSString *)getAuthToken
{
    return @"";
}

- (NSString *)getTimestamp
{
    return @"";
}

- (NSString *)getGetDataUrl
{
    return @"";
}

- (NSString *)getGetDataUrlForModel:(NSString *)identifier
{
    return @"";
}

- (NSString *)getDeviceId
{
    return @"";
}

- (NSArray *)getSyncManagers
{
    return [[NSArray alloc] init];
}

- (NSString *)getSendDataUrl
{
    return @"";
}

- (void)setTimestamp:(NSString *)timestamp
{
    
}
- (id<SyncManager>)getSyncManagerByResponseId:(NSString *)responseId
{
    return nil;
}

- (id<SyncManager>)getSyncMaanger:(NSString *)identifier
{
    return nil;
}

- (DatabaseProvider *)getDatabase
{
    return [[DatabaseProvider alloc] init];
}

@end
