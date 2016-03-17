//
//  SyncEvent.m
//  Syncing
//
//  Created by Rodrigo Suhr on 6/21/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "SyncEvent.h"

@implementation SyncEvent

- (instancetype)initWithObjects:(NSArray *)objects
{
    self = [super init];
    
    if (self)
    {
        // Store the objectID of every NSManagedObject.
        NSMutableArray *objectsIDs = [[NSMutableArray alloc] init];
        NSManagedObjectContext *context = nil;
        
        if ([objects count] > 0) {
            context = [(NSManagedObject *)[objects objectAtIndex:0] managedObjectContext];
            NSError *error;
            [context obtainPermanentIDsForObjects:objects error:&error];
            if (error) {
                NSString *exception = [NSString stringWithFormat:@"SyncEvent exception: %@.", error.description];
                @throw [NSException exceptionWithName:@"" reason:exception userInfo:nil];
            }
        }
        
        for (NSManagedObject *object in objects)
        {
            [objectsIDs addObject:[object objectID]];
        }
        
        _objectsIDs = objectsIDs;
    }
    
    return self;
}

- (NSArray *)getDeletedObjectsWithContext:(NSManagedObjectContext *)context
{
    return [self getObjectsWithContext:context withRefresh:NO];
}

- (NSArray *)getUpdatedObjectsWithContext:(NSManagedObjectContext *)context
{
    return [self getObjectsWithContext:context withRefresh:YES];
}

- (NSArray *)getObjectsWithContext:(NSManagedObjectContext *)context withRefresh:(BOOL)refresh
{
    // Instantiate a NSManagedObject for every objectID in objectsIDs array.
    NSMutableArray *objects = [[NSMutableArray alloc] init];
    NSManagedObject *object = nil;
    
    for (NSManagedObjectID *objectID in _objectsIDs)
    {
        object = [context existingObjectWithID:objectID error:nil];
        if (object != nil)
        {
            if (refresh)
            {
                [context refreshObject:object mergeChanges:NO];
            }
            
            [objects addObject:object];
        }
    }
    
    return objects;
    
}

@end
