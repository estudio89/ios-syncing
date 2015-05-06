//
//  SyncConfig.h
//  Syncing
//
//  Created by Rodrigo Suhr on 2/22/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SyncManager.h"
#import "DatabaseProvider.h"

@interface SyncConfig : NSObject

+ (SyncConfig *)getInstance;
- (void)showLoginIfNeeded:(UIViewController *)initialVC;
- (BOOL)userIsLoggedIn;
- (NSString *)getAuthenticateUrl;
- (NSString *)getAuthToken;
- (NSString *)getTimestamp;
- (NSString *)getGetDataUrl;
- (NSString *)getGetDataUrlForModel:(NSString *)identifier;
- (NSString *)getDeviceId;
- (NSArray *)getSyncManagers;
- (NSString *)getSendDataUrl;
- (id<SyncManager>)getSyncManager:(NSString *)identifier;
- (id<SyncManager>)getSyncManagerByResponseId:(NSString *)responseId;
- (DatabaseProvider *)getDatabase;
- (void)setTimestamp:(NSString *)timestamp;
- (void)setConfigFile:(NSString *)filename;
- (void)setAuthToken:(NSString *)authToken;
- (void)setUsername:(NSString *)username;
- (void)setDeviceId:(NSString *)newId;

@end
