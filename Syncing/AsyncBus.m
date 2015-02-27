//
//  AsyncBus.m
//  Syncing
//
//  Created by Rodrigo Suhr on 2/26/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "AsyncBus.h"
#import "DataSyncHelper.h"

@implementation AsyncBus

- (void)post:(id)object
{
    BOOL postEvent = YES;
    NSString *event = @"";
    
    if ([object isKindOfClass:[SendFinishedEvent class]])
    {
        event = @"SendFinishedEvent";
    }
    else if ([object isKindOfClass:[GetFinishedEvent class]])
    {
        event = @"GetFinishedEvent";
    }
    else if ([object isKindOfClass:[SyncFinishedEvent class]])
    {
        event = @"SyncFinishedEvent";
    }
    else if ([object isKindOfClass:[BackgroundSyncError class]])
    {
        event = @"BackgroundSyncError";
    }
    else
    {
        postEvent = NO;
    }
    
    if (postEvent)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:event object:object];
    }
}

- (void)subscribe:(id)observer withSelector:(SEL)selector withEventname:(NSString *)event withObject:(id)object
{
    [[NSNotificationCenter defaultCenter] addObserver:observer selector:selector name:event object:object];
}

@end
