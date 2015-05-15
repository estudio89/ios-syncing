//
//  AsyncBus.m
//  Syncing
//
//  Created by Rodrigo Suhr on 2/26/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "AsyncBus.h"

@implementation AsyncBus

/**
 * post
 */
- (void)post:(id)object withNotificationName:(NSString *)notification;
{
    // The notification will be posted on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:notification object:object];
    });
}

/**
 * subscribe
 */
- (void)subscribe:(id)observer withSelector:(SEL)selector withNotificationName:(NSString *)notification withObject:(id)object
{
    [[NSNotificationCenter defaultCenter] addObserver:observer selector:selector name:notification object:object];
}

/**
 * unsubscribe
 */
- (void)unsubscribe:(id)observer withNotificationName:(NSString *)notification withObject:(id)object
{
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:notification object:object];
}

@end
