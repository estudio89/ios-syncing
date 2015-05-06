//
//  ServerAuthenticate.h
//  Syncing
//
//  Created by Rodrigo Suhr on 3/12/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServerComm.h"
#import "SyncConfig.h"
#import "AsyncBus.h"

@interface ServerAuthenticate : NSObject

+ (ServerAuthenticate *)getInstance;
- (instancetype)initWithServerComm:(ServerComm *)serverComm
                    withSyncCOnfig:(SyncConfig *)syncConfig
                      withAsyncBus:(AsyncBus *)bus;
- (NSString *)syncAuthentication:(NSString *)username withPasswd:(NSString *)password;
- (void)asyncAuthentication:(NSString *)username withPasswd:(NSString *)password;

@end

@interface WrongCredentialsEvent : NSObject
@end

@interface BlockedLoginEvent : NSObject
@end

@interface ConnectionErrorEvent : NSObject
@end

@interface SuccessfulLoginEvent : NSObject

- (instancetype)initWithUsername:(NSString *)username
                   withAuthToken:(NSString *)authToken;
- (NSString *)getUsername;
- (NSString *)getAuthToken;

@end