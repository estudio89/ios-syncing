//
//  AbstractLoginActivity.h
//  Syncing
//
//  Created by Rodrigo Suhr on 3/12/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ServerAuthenticate.h"

@protocol AbstractLoginActivityProtocol <NSObject>

- (void)onIncompleteCredentials;
- (void)onWrongCredentials:(WrongCredentialsEvent *)event;
- (void)onBlockedLogin:(BlockedLoginEvent *)event;
- (void)onConnectionError:(ConnectionErrorEvent *)event;

@end

@interface AbstractLoginActivity : UIViewController

@property (nonatomic, weak) id <AbstractLoginActivityProtocol> delegate;

- (void)submitLogin:(NSString *)username withPasswd:(NSString *)password;
- (BOOL)verifyCredentials:(NSString *)username withPasswd:(NSString *)password;
- (void)onSuccessfulLogin:(SuccessfulLoginEvent *)event;

@end
