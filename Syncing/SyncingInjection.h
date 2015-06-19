//
//  SyncingInjection.h
//  Syncing
//
//  Created by Rodrigo Suhr on 5/4/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface SyncingInjection : NSObject

+ (void)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator
         withConfigFile:(NSString *)fileName;
+ (void)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator
         withConfigFile:(NSString *)fileName
        withInitialSync:(BOOL)initialSync;
+ (void)executeInjectionWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator;
+ (id)get:(Class)class;

@end
