//
//  SyncingInjection.m
//  Syncing
//
//  Created by Rodrigo Suhr on 5/4/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "SyncingInjection.h"
#import "Syncing.h"
#import <Raven/RavenClient.h>

@implementation SyncingInjection

static NSMutableDictionary *objects;

+ (void)initWithContext:(NSManagedObjectContext *)context
         withConfigFile:(NSString *)fileName
{
    [self initWithContext:context withConfigFile:fileName withInitialSync:YES];
}

+ (void)initWithContext:(NSManagedObjectContext *)context
         withConfigFile:(NSString *)fileName
        withInitialSync:(BOOL)initialSync
{
    [self configRavenClient];
    [self executeInjectionWithContext:context];
    
    SyncConfig *syncConfig = [self get:[SyncConfig class]];
    [syncConfig setConfigFile:fileName];
    
    if (initialSync)
    {
        [[DataSyncHelper getInstance] fullAsynchronousSync];
    }
    
    // send some information to sentry
    [RavenClient sharedClient].user = @{@"token":[syncConfig getAuthToken],
                                        @"user":[syncConfig getUsername],
                                        @"model":[NSString stringWithFormat:@"%@, %@", [UIDevice currentDevice].model, [UIDevice currentDevice].localizedModel]};
}

+ (void)executeInjectionWithContext:(NSManagedObjectContext *)context;
{
    AsyncBus *asyncBus = [[AsyncBus alloc] init];
    SyncConfig *syncConfig = [[SyncConfig alloc] initWithBus:asyncBus];
    CustomTransactionManager *customTransactionManager = [[CustomTransactionManager alloc] init];
    ThreadChecker *threadChecker = [[ThreadChecker alloc] init];
    SecurityUtil *securityUtil = [[SecurityUtil alloc] initWithSyncConfig:syncConfig];
    ServerComm *serverComm = [[ServerComm alloc] initWithSecurityUtil:securityUtil];
    
    DataSyncHelper *dataSyncHelper = [[DataSyncHelper alloc] initWithServer:serverComm
                                                          withThreadChecker:threadChecker
                                                             withSyncConfig:syncConfig
                                                     withTransactionManager:customTransactionManager
                                                                    withBus:asyncBus
                                                                withContext:context];
    
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

+ (void)configRavenClient
{
    //raven client configuration
    RavenClient *ravenClient = [RavenClient clientWithDSN:@"http://7c2c45b4fd0443098cec6739ad8785a8:c5c4826fbec942fda38e7eb94fa25307@sentry.estudio89.com.br/4"];
    [RavenClient setSharedClient:ravenClient];
    
    //global error handler
    [[RavenClient sharedClient] setupExceptionHandler];
}

@end
