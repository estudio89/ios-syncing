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
        
        for (NSManagedObject *object in objects)
        {
            [objectsIDs addObject:[object objectID]];
        }
        
        _objectsIDs = objectsIDs;
    }
    
    return self;
}

- (NSArray *)getObjectsWithContext:(NSManagedObjectContext *)context
{
    // Instantiate a NSManagedObject for every objectID in objectsIDs array.
    NSMutableArray *objects = [[NSMutableArray alloc] init];
    NSManagedObject *object = nil;
    
    for (NSManagedObjectID *objectID in _objectsIDs)
    {
        object = [context existingObjectWithID:objectID error:nil];
        [objects addObject:object];
    }
    
    return objects;
}

@end
