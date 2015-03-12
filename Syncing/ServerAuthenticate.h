//
//  ServerAuthenticate.h
//  Syncing
//
//  Created by Rodrigo Suhr on 3/12/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ServerAuthenticate : NSObject

- (NSString *)syncAuthentication:(NSString *)username withPasswd:(NSString *)password;

@end

@interface AuthenticationAsyncTask : NSObject
@end

@interface WrongCredentialsEvent : NSObject
@end

@interface BlockedLoginEvent : NSObject
@end

@interface ConnectionErrorEvent : NSObject
@end

@interface SuccessfulLoginEvent : NSObject
@end