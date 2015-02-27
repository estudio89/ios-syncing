//
//  CustomTransactionManager.m
//  Syncing
//
//  Created by Rodrigo Suhr on 2/25/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "CustomTransactionManager.h"
#import "DatabaseProvider.h"
#import "CustomException.h"

@interface CustomTransactionManager()

@property BOOL isSuccessful;

@end

@implementation CustomTransactionManager

/**
 init
 */
- (id)init
{
    if (self = [super init])
    {
        self.isSuccessful = NO;
    }
    
    return self;
}

/**
 doInTransaction
 */
- (void)doInTransaction:(void(^)(void))manipulateInTransaction withSyncConfig:(SyncConfig *)syncConfig
{
    DatabaseProvider *dbProvider = [syncConfig getDatabase];
    
    @try
    {
        manipulateInTransaction();
        [dbProvider saveTransaction];
        self.isSuccessful = YES;
    }
    @catch (InvalidThreadIdException *exception)
    {
        [dbProvider rollbackTransaction];
    }
    @catch (NSException *exception)
    {
        [dbProvider rollbackTransaction];
        @throw exception;
    }
}

/**
 wasSuccessful
 */
- (BOOL)wasSuccessful
{
    return self.isSuccessful;
}

@end
