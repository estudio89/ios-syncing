//
//  SharedModelContext.m
//  Syncing
//
//  Created by Rodrigo Suhr on 2/27/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "SharedModelContext.h"

@interface SharedModelContext()

@property (nonatomic, strong, readwrite) NSManagedObjectContext *managedObjectContext;

@end

@implementation SharedModelContext

static SharedModelContext *mySharedModelContext;

/**
 * sharedModelContext
 */
+ (SharedModelContext *)sharedModelContext
{
    if(!mySharedModelContext)
    {
        mySharedModelContext = [[self alloc] init];
    }
    
    return mySharedModelContext;
}

/**
 * setSharedModelContext
 */
- (void)setSharedModelContext:(NSManagedObjectContext *)context
{
    self.managedObjectContext = context;
}

/**
 * sharedModelContext
 */
- (NSManagedObjectContext *)getSharedModelContext
{
    return [self managedObjectContext];
}

@end
