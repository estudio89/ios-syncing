//
//  DatabaseProvider.m
//  Syncing
//
//  Created by Rodrigo Suhr on 2/27/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "DatabaseProvider.h"
#import "SharedModelContext.h"

@implementation DatabaseProvider

/**
 saveTransaction
 */
- (void)saveTransaction
{
    [[[SharedModelContext sharedModelContext] getSharedModelContext] save:nil];
}

/**
 rollbackTransaction
 */
- (void)rollbackTransaction
{
    [[[SharedModelContext sharedModelContext] getSharedModelContext] rollback];
}

@end
