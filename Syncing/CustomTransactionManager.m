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
    NSUndoManager *undoManager = [[NSUndoManager alloc] init];
    [context setUndoManager:undoManager];
    
    @try
    {
        [undoManager beginUndoGrouping];
        manipulateInTransaction();
        [self performSaveWithContext:context];
        [undoManager endUndoGrouping];
        self.isSuccessful = YES;
    }
    @catch (InvalidThreadIdException *exception)
    {
        [undoManager endUndoGrouping];
        [undoManager undo];
        [self performSaveWithContext:context];
    }
    @catch (NSException *exception)
    {
        [undoManager endUndoGrouping];
        [undoManager undo];
        [self performSaveWithContext:context];
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

- (void)performSaveWithContext:(NSManagedObjectContext *)context
{
    NSError *error = nil;
    [context save:&error];
    if (error) {
        NSString *errorString = [NSString stringWithFormat:@"Error on performSaveWithContext: %@", error];
        NSException *ex = [NSException exceptionWithName:@"CoreDataSaveError" reason:errorString userInfo:nil];
        @throw ex;
    }
}

@end
