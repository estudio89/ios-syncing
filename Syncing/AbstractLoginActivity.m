//
//  AbstractLoginActivity.m
//  Syncing
//
//  Created by Rodrigo Suhr on 3/12/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "AbstractLoginActivity.h"
#import "SyncConfig.h"
#import "ServerAuthenticate.h"

@implementation AbstractLoginActivity

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
- (void)onSuccessfulLogin:(NSNotification *)notification
{
    SuccessfulLoginEvent *successfullLogin = notification.object;
    [[SyncConfig getInstance] setAuthToken:[successfullLogin getAuthToken]];
    [[SyncConfig getInstance] setUsername:[successfullLogin getUsername]];
}

- (void)onSyncError:(NSNotification *)notification
{
    [[SyncConfig getInstance] logout:NO];
}

/**
 * onWrongCredentials
 *
 * @param event
 */
- (void)onWrongCredentials:(NSNotification *)notification
{
    
}

/**
 * onBlockedLogin
 *
 * @param event
 */
- (void)onBlockedLogin:(NSNotification *)notification
{
    
}

/**
 * onConnectionError
 *
 * @param event
 */
- (void)onConnectionError:(NSNotification *)notification
{
    
}

@end
