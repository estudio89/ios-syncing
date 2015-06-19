//
//  ReadOnlyAbstractSyncManager.m
//  Syncing
//
//  Created by Rodrigo Suhr on 5/6/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "ReadOnlyAbstractSyncManager.h"

@implementation ReadOnlyAbstractSyncManager

- (NSString *)getResponseIdentifier
{
    return [NSString stringWithFormat:@"%@", @([self hash])];
}

- (BOOL)shouldSendSingleObject
{
    return NO;
}

- (NSMutableArray *)getModifiedDataWithContext:(NSManagedObjectContext *)context
{
    return [[NSMutableArray alloc] init];
}

- (BOOL)hasModifiedDataWithContext:(NSManagedObjectContext *)context
{
    return NO;
}

- (NSMutableArray *)getModifiedFilesWithContext:(NSManagedObjectContext *)context
{
    return [[NSMutableArray alloc] init];
}

- (NSMutableArray *)getModifiedFilesForObject:(NSDictionary *)object withContext:(NSManagedObjectContext *)context
{
    return [[NSMutableArray alloc] init];
}

- (NSMutableArray *)saveNewData:(NSArray *)jsonObjects withDeviceId:(NSString *)deviceId withParameters:(NSDictionary *)responseParameters withContext:(NSManagedObjectContext *)context
{
    NSMutableArray * newObjects = [[NSMutableArray alloc] init];
    for (NSDictionary *objectJSON in jsonObjects)
    {
        [newObjects addObject:[self saveObject:objectJSON withDeviceId:deviceId withContext:context]];
    }
    
    return newObjects;
}

- (void)postEvent:(NSArray *)objects withBus:(AsyncBus *)bus
{
}

- (void)processSendResponse:(NSArray *)jsonResponse withContext:(NSManagedObjectContext *)context
{
}

- (NSDictionary *)serializeObject:(NSObject *)object
{
    return nil;
}

@end
