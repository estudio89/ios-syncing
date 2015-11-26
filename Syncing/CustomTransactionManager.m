//
//  CustomTransactionManager.m
//  Syncing
//
//  Created by Rodrigo Suhr on 2/25/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "CustomTransactionManager.h"
#import "CustomException.h"
#import <CoreData/CoreData.h>

@interface CustomTransactionManager()

@property BOOL isSuccessful;

@end

@implementation CustomTransactionManager

/**
 * init
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
 * doInTransaction
 */
- (void)doInTransaction:(void(^)(void))manipulateInTransaction withContext:(NSManagedObjectContext *)context
{
    @try
    {
        manipulateInTransaction();
        [context save:nil];
        self.isSuccessful = YES;
    }
    @catch (InvalidThreadIdException *exception)
    {
        [context rollback];
    }
    @catch (NSException *exception)
    {
        [context rollback];
        @throw exception;
    }
}

/**
 * wasSuccessful
 */
- (BOOL)wasSuccessful
{
    return self.isSuccessful;
}

@end
