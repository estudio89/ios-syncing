//
//  CustomTransactionManager.m
//  Syncing
//
//  Created by Rodrigo Suhr on 2/25/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "CustomTransactionManager.h"
#import "DatabaseProvider.h"

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
    @catch
    {
        //nao e erro, proposital
        //catch da minha classe de excessao (InvalidThreadId)
        //rollback
    }
    @catch (NSException *exception)
    {
        //erro!
        [dbProvider rollbackTransaction];
        //@trow da exception
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
