//
//  TestSyncManager.m
//  Syncing
//
//  Created by Rodrigo Suhr on 3/4/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "TestSyncManager.h"

@implementation TestSyncManager

/**
 getIdentifier
 */
- (NSString *)getIdentifier
{
    return @"test";
}

/**
 getResponseIdentifier
 */
- (NSString *)getResponseIdentifier
{
    return @"test_id";
}

/**
 shouldSendSingleObject
 */
- (BOOL)shouldSendSingleObject
{
    return NO;
}

/**
 getModifiedData
 */
- (NSMutableArray *)getModifiedData
{
    return [[NSMutableArray alloc] init];
}

/**
 hasModifiedData
 */
- (BOOL)hasModifiedData
{
    return NO;
}

/**
 getModifiedFiles
 */
- (NSMutableArray *)getModifiedFiles
{
    return [[NSMutableArray alloc] init];
}

/**
 getModifiedFilesForObject
 */
- (NSMutableArray *)getModifiedFilesForObject:(NSDictionary *)object
{
    return [[NSMutableArray alloc] init];
}

/**
 saveNewData
 */
- (NSMutableArray *)saveNewData:(NSArray *)jsonObjects withDeviceId:(NSString *)deviceId
{
    return [[NSMutableArray alloc] init];
}

/**
 processSendResponse
 */
- (void)processSendResponse:(NSArray *)jsonResponse
{
}

/**
 serializeObject
 */
-(NSDictionary *)serializeObject:(NSObject *)object
{
    return [[NSDictionary alloc] init];
}

/**
 saveObject
 */
- (id)saveObject:(NSDictionary *)object withDeviceId:(NSString *)deviceId
{
    return [[NSObject alloc] init];
}

/**
 postEvent
 */
- (void)postEvent:(NSArray *)objects withBus:(AsyncBus *)bus
{
}

@end
