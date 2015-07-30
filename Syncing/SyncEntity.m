//
//  SyncEntity.m
//  Syncing
//
//  Created by Rodrigo Suhr on 7/9/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "SyncEntity.h"

@implementation SyncEntity

@dynamic idServer;
@dynamic modified;
@dynamic isNew;

+ (SyncEntity *)getOldestFromEntity:(NSString *)entity withContext:(NSManagedObjectContext *)context
{
    return [SyncEntity getOldestFromEntity:entity withPredicate:nil withContext:context];
}

+ (SyncEntity *)getOldestFromEntity:(NSString *)entity withPredicate:(NSPredicate *)predicate withContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entity];
    if (predicate != nil) {
        [fetchRequest setPredicate:predicate];
    }
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"pubDate" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    [fetchRequest setFetchLimit:1];
    
    NSArray *oldestArray = [context executeFetchRequest:fetchRequest error:nil];
    
    if (oldestArray == nil || [oldestArray count] == 0)
    {
        return nil;
    }
    
    return [oldestArray objectAtIndex:0];
}

+ (NSUInteger)countFromEntity:(NSString *)entity withContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entity];
    NSUInteger rCount = [context countForFetchRequest:fetchRequest error:nil];
    
    return rCount;
}

+ (NSUInteger)countFromEntity:(NSString *)entity withPredicate:(NSPredicate *)predicate withContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entity];
    [fetchRequest setPredicate:predicate];
    NSUInteger rCount = [context countForFetchRequest:fetchRequest error:nil];
    
    return rCount;
}

+ (NSInteger)numberOfIsNewFromEntity:(NSString *)entity withContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"isNew==YES"]];
    
    return [context countForFetchRequest:fetchRequest error:nil];
}

+ (void)makeOldForEntity:(NSString *)entity withContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"isNew==YES"]];
    
    NSArray *objects = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    
    for (SyncEntity *object in objects)
    {
        object.isNew = [NSNumber numberWithBool:NO];
        [context save:nil];
    }
}

- (void)saveWithContext:(NSManagedObjectContext *)context
{
    NSError *error = nil;
    
    if (![context save:&error])
    {
        NSLog(@"Error! %@ %@", error, [error localizedDescription]);
    }
}

@end
