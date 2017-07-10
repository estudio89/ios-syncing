//
//  SharedObjectContext.m
//  Syncing
//
//  Created by Rodrigo Suhr on 7/10/17.
//  Copyright © 2017 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "SharedObjectContext.h"

@interface SharedObjectContext ()
    
@property (readonly, strong, nonatomic) NSManagedObjectContext *masterManagedObjectContext;
@property (readonly, strong, nonatomic) E89MainManagedObjectContext *mainManagedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
    
@end

@implementation SharedObjectContext
    
@synthesize masterManagedObjectContext = _masterManagedObjectContext;
@synthesize mainManagedObjectContext = _mainManagedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
    
static SharedObjectContext *sharedObjectContextInstance;
static NSString *urlForResource;
    
+ (NSManagedObjectContext *)managedObjectContext {
        if (sharedObjectContextInstance == nil) {
            sharedObjectContextInstance = [[SharedObjectContext alloc] init];
        }
        
        return sharedObjectContextInstance.mainManagedObjectContext;
}

+ (NSManagedObjectContext *)managedObjectContextWithURLForResource:(NSString *)url {
    urlForResource = url;

    return [SharedObjectContext managedObjectContext];
}
    
- (instancetype)init {
    self = [super init];
    
    if (self) {
        NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        if (!coordinator) {
            return nil;
        }
        
        _masterManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_masterManagedObjectContext setPersistentStoreCoordinator:coordinator];
        [_masterManagedObjectContext setUndoManager:nil];
        [_masterManagedObjectContext performBlockAndWait:^{
            [_masterManagedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
        }];
        
        _mainManagedObjectContext = [[E89MainManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_mainManagedObjectContext setParentContext:_masterManagedObjectContext];
        [_mainManagedObjectContext setUndoManager:nil];
    }
    
    return self;
}
    
- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "Estudio89.SingleAppForTests" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}
    
- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:urlForResource withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}
    
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"SingleAppForTests.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    
    //Lightweight migration
    NSDictionary *migrateOptions = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:migrateOptions error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}
    
    @end

@implementation E89MainManagedObjectContext
    
- (BOOL)save:(NSError * _Nullable __autoreleasing *)error {
    if (![self hasChanges]) {
        return YES;
    }
    
    if ([super save:error]) {
        [self.parentContext performBlock:^{
            NSError *parentError = nil;
            if (![self.parentContext save:&parentError]) {
                NSString *errorString = [NSString stringWithFormat:@"E89MainManagedObjectContext: error on self.parentContext save: %@.", parentError];
                NSException *ex = [NSException exceptionWithName:@"E89MainManagedObjectContextSaveError" reason:errorString userInfo:parentError.userInfo];
                NSLog(@"%@", ex);
            }
        }];
        
        return YES;
    } else {
        return NO;
    }
}
    
@end
