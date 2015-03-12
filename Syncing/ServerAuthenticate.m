//
//  ServerAuthenticate.m
//  Syncing
//
//  Created by Rodrigo Suhr on 3/12/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "ServerAuthenticate.h"
#import "ServerComm.h"
#import "SyncConfig.h"
#import "AsyncBus.h"
#import "CustomException.h"

@interface ServerAuthenticate()

@property ServerComm *serverComm;
@property SyncConfig *syncConfig;
@property AsyncBus *bus;

@end

@implementation ServerAuthenticate

/**
 * initWithServerComm
 * Constructor for dependency injection.
 @param serverComm A ServerComm mock object.
 @param syncConfig A SyncConfig mock object.
 @param bus A AsyncBus mock object.
 @return self A ServerAuthenticate instance.
 */
- (instancetype)initWithServerComm:(ServerComm *)serverComm
                    withSyncCOnfig:(SyncConfig *)syncConfig
                      withAsyncBus:(AsyncBus *)bus
{
    self = [super init];
    if (self)
    {
        _serverComm = serverComm;
        _syncConfig = syncConfig;
        _bus = bus;
    }
    return self;
}

/**
 init
 The overridden init method
 @return self A ServerAuthenticate instance.
 */
- (instancetype)init
{
    return [self initWithServerComm:[[ServerComm alloc] init]
                     withSyncCOnfig:[[SyncConfig alloc] init]
                       withAsyncBus:[[AsyncBus alloc] init]];
}

/**
 * syncAuthentication
 * Authenticate on server.
 * @param username
 * @param password
 * @return JSON response with token if the authentication was successful.
 */
- (NSString *)syncAuthentication:(NSString *)username withPasswd:(NSString *)password
{
    NSDictionary *auth = @{@"username":username, @"password":password};
    NSDictionary *response = nil;
    
    @try
    {
        NSLog(@"Sending authentication post to server.");
        response = [_serverComm post:[_syncConfig getAuthenticateUrl] withData:auth];
    }
    @catch (Http403Exception *e)
    {
        NSLog(@"403 exception.");
        [_bus post:[[BlockedLoginEvent alloc] init] withNotificationname:@"BlockedLoginEvent"];
        return nil;
    }
    @catch (NSException *e)
    {
        NSLog(@"syncAuthentication error.");
        [_bus post:[[ConnectionErrorEvent alloc] init] withNotificationname:@"ConnectionErrorEvent"];
        return nil;
    }
    
    BOOL verified = [[response valueForKey:@""] boolValue];
    NSString *authToken = nil;
    
    if (verified)
    {
        authToken = [response valueForKey:@"token"];
        [_bus post:[[SuccessfulLoginEvent alloc] init] withNotificationname:@"SuccessfulLoginEvent"];
        NSLog(@"Login successful.");
    }
    else
    {
        [_bus post:[[WrongCredentialsEvent alloc] init] withNotificationname:@"WrongCredentialsEvent"];
        NSLog(@"Wrong credentials.");
    }
    
    return authToken;
    
}

@end

@interface SuccessfulLoginEvent()

@property NSString *username;
@property NSString *password;
@property NSString *accountType;
@property NSString *authToken;

@end

@implementation SuccessfulLoginEvent

- (instancetype)initWithUsername:(NSString *)username
                    withPassword:(NSString *)password
                 withAccountType:(NSString *)accountType
                   withAuthToken:(NSString *)authToken
{
    
}

@end
