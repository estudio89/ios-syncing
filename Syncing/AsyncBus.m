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
- (void)post:(id)object withNotificationname:(NSString *)notification;
{
    [[NSNotificationCenter defaultCenter] postNotificationName:notification object:object];
}

/**
 * subscribe
 */
- (void)subscribe:(id)observer withSelector:(SEL)selector withNotificationname:(NSString *)notification withObject:(id)object
{
    [[NSNotificationCenter defaultCenter] addObserver:observer selector:selector name:notification object:object];
}

@end
