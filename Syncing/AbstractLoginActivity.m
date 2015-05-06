//
//  AbstractLoginActivity.m
//  Syncing
//
//  Created by Rodrigo Suhr on 3/12/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "AbstractLoginActivity.h"
#import "SyncConfig.h"

@implementation AbstractLoginActivity

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        AsyncBus *bus = [[AsyncBus alloc] init];
        [bus subscribe:self withSelector:@selector(onSuccessfulLogin:) withNotificationname:@"SuccessfulLoginEvent" withObject:nil];
        [bus subscribe:self withSelector:@selector(onWrongCredentials:) withNotificationname:@"WrongCredentialsEvent" withObject:nil];
        [bus subscribe:self withSelector:@selector(onBlockedLogin:) withNotificationname:@"BlockedLoginEvent" withObject:nil];
        [bus subscribe:self withSelector:@selector(onConnectionError:) withNotificationname:@"ConnectionErrorEvent" withObject:nil];
    }
    
    return self;
}

/**
 * submitLogin
 *
 * @param
 */
- (void)submitLogin:(NSString *)username withPasswd:(NSString *)password
{
    if (![self verifyCredentials:username withPasswd:password])
    {
        [self onIncompleteCredentials];
        return;
    }

    [[ServerAuthenticate getInstance] asyncAuthentication:username withPasswd:password];
}

/**
 * verifyCredentials
 *
 * @param
 * @return
 */
- (BOOL)verifyCredentials:(NSString *)username withPasswd:(NSString *)password
{
    return !([username length] <= 0 || [password length] <= 0);
}

/**
 * onSuccessfulLogin
 *
 * @param
 */
- (void)onIncompleteCredentials
{
}

#pragma mark - Events

/**
 * onSuccessfulLogin
 *
 * @param event
 */
- (void)onSuccessfulLogin:(SuccessfulLoginEvent *)event
{
    [[SyncConfig getInstance] setAuthToken:[event getAuthToken]];
    [[SyncConfig getInstance] setUsername:[event getUsername]];
}

/**
 * onWrongCredentials
 *
 * @param event
 */
- (void)onWrongCredentials:(WrongCredentialsEvent *)event
{
    
}

/**
 * onBlockedLogin
 *
 * @param event
 */
- (void)onBlockedLogin:(BlockedLoginEvent *)event
{
    
}

/**
 * onConnectionError
 *
 * @param event
 */
- (void)onConnectionError:(ConnectionErrorEvent *)event
{
    
}

@end
