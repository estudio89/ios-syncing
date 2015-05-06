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

- (NSMutableArray *)getModifiedData
{
    return [[NSMutableArray alloc] init];
}

- (BOOL)hasModifiedData
{
    return NO;
}

- (NSMutableArray *)getModifiedFiles
{
    return [[NSMutableArray alloc] init];
}

- (NSMutableArray *)getModifiedFilesForObject:(NSDictionary *)object
{
    return [[NSMutableArray alloc] init];
}

- (void)postEvent:(NSArray *)objects withBus:(AsyncBus *)bus
{
}

- (void)processSendResponse:(NSArray *)jsonResponse
{
}

- (NSDictionary *)serializeObject:(NSObject *)object
{
    return nil;
}

@end
