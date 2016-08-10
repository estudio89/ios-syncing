//
//  SyncConfig.h
//  Syncing
//
//  Created by Rodrigo Suhr on 2/22/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "SyncManager.h"

@interface SyncConfig : NSObject

@property (nonatomic, strong) NSManagedObjectContext *context;

+ (SyncConfig *)getInstance;
- (instancetype)initWithBus:(AsyncBus *)bus withContext:(NSManagedObjectContext *)context;
- (void)showLoginIfNeeded:(UIViewController *)initialVC;
- (void)showLoginIfNeeded:(UIViewController *)initialVC withSegueID:(NSString *)segueID;
- (BOOL)userIsLoggedIn;
- (NSString *)getAuthenticateUrl;
- (NSString *)getAuthToken;
- (NSString *)getUsername;
- (NSDictionary *)getTimestamps;
- (NSDictionary *)getTimestamp:(NSString *)identifier;
- (NSString *)getGetDataUrl;
- (NSString *)getGetDataUrlForModel:(NSString *)identifier;
- (NSString *)getDeviceId;
- (NSArray *)getSyncManagers;
- (NSString *)getSendDataUrl;
- (id<SyncManager>)getSyncManager:(NSString *)identifier;
- (id<SyncManager>)getSyncManagerByResponseId:(NSString *)responseId;
- (void)setTimestamps:(NSDictionary *)timestamps;
- (void)setConfigFile:(NSString *)filename withBaseUrl:(NSString *)baseUrl;
- (void)setAuthToken:(NSString *)authToken;
- (void)setUsername:(NSString *)username;
- (void)setDeviceId:(NSString *)newId;
- (void)logout;
- (void)logout:(BOOL)postEvent;
- (BOOL)isEncryptionActive;
- (NSString *)getEncryptionPassword;
- (void)requestSync;
- (NSManagedObjectContext *)getContext;
- (BOOL)userNeverSynced;
- (void)setDataSyncHelper:(DataSyncHelper *)dataSyncHelper;

@end

@interface UserLoggedOutEvent : NSObject

@end
