//
//  SyncConfig.h
//  Syncing
//
//  Created by Rodrigo Suhr on 2/22/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SyncManager.h"
#import "DatabaseProvider.h"

@interface SyncConfig : NSObject

- (NSString *)getAuthenticateUrl;
- (NSString *)getAccountType;
- (NSString *)getAuthToken;
- (NSString *)getTimestamp;
- (NSString *)getGetDataUrl;
- (NSString *)getGetDataUrlForModel:(NSString *)identifier;
- (NSString *)getDeviceId;
- (NSArray *)getSyncManagers;
- (NSString *)getSendDataUrl;
- (void)setTimestamp:(NSString *)timestamp;
- (id<SyncManager>)getSyncManager:(NSString *)identifier;
- (id<SyncManager>)getSyncManagerByResponseId:(NSString *)responseId;
- (DatabaseProvider *)getDatabase;
- (void)setConfigFile:(NSString *)filename;

@end
