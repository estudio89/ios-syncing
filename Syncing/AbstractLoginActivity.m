//
//  AbstractLoginActivity.m
//  Syncing
//
//  Created by Rodrigo Suhr on 3/12/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "AbstractLoginActivity.h"
#import "SyncConfig.h"

@interface AbstractLoginActivity ()

@end

@implementation AbstractLoginActivity

@synthesize delegate;

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
        [delegate onIncompleteCredentials];
        return;
    }
    ServerAuthenticate *serverAuthenticate = [[ServerAuthenticate alloc] init];
    [serverAuthenticate asyncAuthentication:username withPasswd:password];
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
- (void)onSuccessfulLogin:(SuccessfulLoginEvent *)event
{
    SyncConfig *syncConfig = [[SyncConfig alloc] init];
    [syncConfig setAuthToken:[event getAuthToken]];
    [syncConfig setUsername:[event getUsername]];
}

@end
