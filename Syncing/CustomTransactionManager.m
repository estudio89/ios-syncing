//
//  CustomTransactionManager.m
//  Syncing
//
//  Created by Rodrigo Suhr on 2/25/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "CustomTransactionManager.h"

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
    @try
    {
        manipulateInTransaction();
        //database.setTransactionSuccessful();
        //[objDP.context save:&error]
        self.isSuccessful = YES;
    }
    @finally
    {
        //database.endTransaction();
        //[objDP.context rollback];????
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
