//
//  DataSyncHelper.h
//  Syncing
//
//  Created by Rodrigo Suhr on 2/20/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "ServerComm.h"
#import "ThreadChecker.h"
#import "SyncConfig.h"
#import "SyncManager.h"
#import <Foundation/Foundation.h>

@interface DataSyncHelper : NSObject

@property (nonatomic, readonly) ServerComm *serverComm;
@property (nonatomic, readonly) ThreadChecker *threadChecker;
@property (nonatomic, readonly) SyncConfig *syncConfig;
@property (nonatomic, readonly) id<SyncManager> syncManager;

- (instancetype)initWithServer:(ServerComm *)serverComm
                withThreadChecker:(ThreadChecker *)threadChecker
                withSyncConfig:(SyncConfig *)syncConfig;
- (BOOL)getDataFromServer;
- (BOOL)getDataFromServer:(NSString *)identifier withParameters:(NSMutableDictionary *)parameters;
- (BOOL)sendDataToServer;

@end
