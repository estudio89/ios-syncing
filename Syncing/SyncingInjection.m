//
//  SyncingInjection.m
//  Syncing
//
//  Created by Rodrigo Suhr on 5/4/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "SyncingInjection.h"
#import "Syncing.h"

@implementation SyncingInjection

static NSMutableDictionary *objects;

+ (void)initWithContext:(NSManagedObjectContext *)context
                            withConfigFile:(NSString *)fileName
{
    [self initWithContext:context
           withConfigFile:fileName
          withInitialSync:YES];
}

+ (void)initWithContext:(NSManagedObjectContext *)context
                            withConfigFile:(NSString *)fileName
                           withInitialSync:(BOOL)initialSync
{
    [self executeInjectionWithContext:context];
    
    SyncConfig *syncConfig = [self get:[SyncConfig class]];
    [syncConfig setConfigFile:fileName];
    
    if (initialSync)
    {
        [[DataSyncHelper getInstance] fullAsynchronousSync];
    }
}

+ (void)executeInjectionWithContext:(NSManagedObjectContext *)context
{
    AsyncBus *asyncBus = [[AsyncBus alloc] init];
    SyncConfig *syncConfig = [[SyncConfig alloc] initWithBus:asyncBus withContext:context];
    CustomTransactionManager *customTransactionManager = [[CustomTransactionManager alloc] init];
    ThreadChecker *threadChecker = [[ThreadChecker alloc] init];
    SecurityUtil *securityUtil = [[SecurityUtil alloc] initWithSyncConfig:syncConfig];
    ServerComm *serverComm = [[ServerComm alloc] initWithSecurityUtil:securityUtil];
    
    DataSyncHelper *dataSyncHelper = [[DataSyncHelper alloc] initWithServer:serverComm
                                                          withThreadChecker:threadChecker
                                                             withSyncConfig:syncConfig
                                                     withTransactionManager:customTransactionManager
                                                                    withBus:asyncBus];
    
    ServerAuthenticate *serverAuthenticate = [[ServerAuthenticate alloc] initWithServerComm:serverComm
                                                                             withSyncCOnfig:syncConfig
                                                                               withAsyncBus:asyncBus];
    
    objects = [[NSMutableDictionary alloc] init];
    [objects setObject:context forKey:NSStringFromClass([context class])];
    [objects setObject:asyncBus forKey:NSStringFromClass([asyncBus class])];
    [objects setObject:syncConfig forKey:NSStringFromClass([syncConfig class])];
    [objects setObject:customTransactionManager forKey:NSStringFromClass([customTransactionManager class])];
    [objects setObject:threadChecker forKey:NSStringFromClass([threadChecker class])];
    [objects setObject:securityUtil forKey:NSStringFromClass([securityUtil class])];
    [objects setObject:serverComm forKey:NSStringFromClass([serverComm class])];
    [objects setObject:dataSyncHelper forKey:NSStringFromClass([dataSyncHelper class])];
    [objects setObject:serverAuthenticate forKey:NSStringFromClass([serverAuthenticate class])];
}

+ (id)get:(Class)class
{
    return [objects objectForKey:NSStringFromClass(class)];
}

@end
