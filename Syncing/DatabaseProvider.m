//
//  DatabaseProvider.m
//  Syncing
//
//  Created by Rodrigo Suhr on 2/27/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "DatabaseProvider.h"
#import "SharedModelContext.h"

@implementation DatabaseProvider

/**
 * saveTransaction
 */
- (void)saveTransaction
{
    [[[SharedModelContext sharedModelContext] getSharedModelContext] save:nil];
}

/**
 * rollbackTransaction
 */
- (void)rollbackTransaction
{
    [[[SharedModelContext sharedModelContext] getSharedModelContext] rollback];
}

/**
 * flushDatabase
 */
- (void)flushDatabase
{
    NSError *error = nil;
    NSFileManager *fileMgr = [[NSFileManager alloc] init];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSArray *directoryContents = [fileMgr contentsOfDirectoryAtPath:documentsPath error:&error];
    
    if (error == nil)
    {
        for (NSString *path in directoryContents)
        {
            NSString *fullPath = [documentsPath stringByAppendingPathComponent:path];
            BOOL removeSuccess = [fileMgr removeItemAtPath:fullPath error:&error];
            if (!removeSuccess)
            {
                NSLog(@"flushDatabase error - removeItemAtPath");
            }
        }
    }
    else
    {
        NSLog(@"flushDatabase error - contentsOfDirectoryAtPath");
    }
    
    NSManagedObjectContext *context = [[SharedModelContext sharedModelContext] getSharedModelContext];
    NSURL * storeURL = [[context persistentStoreCoordinator] URLForPersistentStore:[[[context persistentStoreCoordinator] persistentStores] lastObject]];
    
    [context reset];
    
    if ([[context persistentStoreCoordinator] removePersistentStore:[[[context persistentStoreCoordinator] persistentStores] lastObject] error:&error])
    {
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error];
        [[context persistentStoreCoordinator] addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error];
    }
}

@end
