//
//  AbstractLoginActivity.h
//  Syncing
//
//  Created by Rodrigo Suhr on 3/12/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ServerAuthenticate.h"

@interface AbstractLoginActivity : UIViewController

- (void)submitLogin:(NSString *)username withPasswd:(NSString *)password;
- (BOOL)verifyCredentials:(NSString *)username withPasswd:(NSString *)password;
- (void)onIncompleteCredentials;
- (void)onSuccessfulLogin:(SuccessfulLoginEvent *)event;
- (void)onWrongCredentials:(WrongCredentialsEvent *)event;
- (void)onBlockedLogin:(BlockedLoginEvent *)event;
- (void)onConnectionError:(ConnectionErrorEvent *)event;

@end
