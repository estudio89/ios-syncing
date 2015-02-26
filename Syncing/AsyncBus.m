//
//  AsyncBus.m
//  Syncing
//
//  Created by Rodrigo Suhr on 2/26/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "AsyncBus.h"

@implementation AsyncBus

- (void)post:(NSString *)event withObject:(id)object
{
    [[NSNotificationCenter defaultCenter] postNotificationName:event object:object];
}

@end
