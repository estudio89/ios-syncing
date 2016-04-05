//
//  DatabaseProvider.m
//  Syncing
//
//  Created by Rodrigo Suhr on 2/27/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "DatabaseProvider.h"
#import "SyncConfig.h"

@implementation DatabaseProvider

/**
 * clearAllCoreDataEntities
 */
+ (void)clearAllCoreDataEntitiesWithContext:(E89ManagedObjectContext *)context
{
    NSManagedObjectModel *model = [[context persistentStoreCoordinator] managedObjectModel];
    NSFetchRequest *fetchRequest = nil;
    NSArray *objects = nil;
    NSArray *entities = [model.entities valueForKey:@"name"];
    
    for (NSString *entity in entities) {
        fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entity];
        [fetchRequest setIncludesPropertyValues:NO];
        objects = [context executeFetchRequest:fetchRequest error:nil];
        
        for (NSManagedObject *object in objects) {
            [context deleteObject:object];
        }
    }
    
    NSError *error = nil;
    [context safeSave:&error];
}

@end
