//
//  ServerAuthenticate.m
//  Syncing
//
//  Created by Rodrigo Suhr on 3/12/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "ServerAuthenticate.h"
#import "CustomException.h"
#import "SyncingInjection.h"

@implementation WrongCredentialsEvent
@end

@implementation BlockedLoginEvent
@end

@implementation ConnectionErrorEvent
@end

//===================================|SuccessfulLoginEvent|===================================

@interface SuccessfulLoginEvent()

@property NSString *username;
@property NSString *password;
@property NSString *authToken;

@end

@implementation SuccessfulLoginEvent

/**
 * initWithUsername
 */
- (instancetype)initWithUsername:(NSString *)username
                   withAuthToken:(NSString *)authToken
{
    self = [super init];
    if (self)
    {
        _username = username;
        _authToken = authToken;
    }
    return self;
}

/**
 * getUsername
 */
- (NSString *)getUsername
{
    return _username;
}

/**
 * getAuthToken
 */
- (NSString *)getAuthToken
{
    return _authToken;
}

@end

//===================================|ServerAuthenticate|===================================

@interface ServerAuthenticate()

@property ServerComm *serverComm;
@property SyncConfig *syncConfig;
@property AsyncBus *bus;
@property BOOL isAuthenticating;

@end

@implementation ServerAuthenticate

/**
 getInstance
 @return self A ServerAuthenticate instance.
 */
+ (ServerAuthenticate *)getInstance
{
    return [SyncingInjection get:[ServerAuthenticate class]];
}

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
        _isAuthenticating = NO;
    }
    return self;
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
        [_bus post:[[BlockedLoginEvent alloc] init] withNotificationName:@"BlockedLoginEvent"];
        return nil;
    }
    @catch (NSException *e)
    {
        NSLog(@"syncAuthentication error.");
        [_bus post:[[ConnectionErrorEvent alloc] init] withNotificationName:@"ConnectionErrorEvent"];
        return nil;
    }
    
    BOOL verified = [[response valueForKey:@"verified"] boolValue];
    NSString *authToken = nil;
    
    if (verified)
    {
        authToken = [response valueForKey:@"token"];
        SuccessfulLoginEvent *sLoginEvent = [[SuccessfulLoginEvent alloc] initWithUsername:username
                                                                             withAuthToken:authToken];
        [_bus post:sLoginEvent withNotificationName:@"SuccessfulLoginEvent"];
        NSLog(@"Login successful.");
    }
    else
    {
        [_bus post:[[WrongCredentialsEvent alloc] init] withNotificationName:@"WrongCredentialsEvent"];
        NSLog(@"Wrong credentials.");
    }
    
    return authToken;
}

/**
 * asyncAuthentication
 * Authenticate on server.
 * @param username
 * @param password
 */
- (void)asyncAuthentication:(NSString *)username withPasswd:(NSString *)password
{
    if (!_isAuthenticating)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            @try
            {
                _isAuthenticating = YES;
                NSLog(@"Starting asynchronous authentication.");
                [self syncAuthentication:username withPasswd:password];
            }
            @finally
            {
                _isAuthenticating = NO;
            }
        });
    }
}

@end
