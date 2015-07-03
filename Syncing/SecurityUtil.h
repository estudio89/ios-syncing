//
//  SecurityUtil.h
//  Syncing
//
//  Created by Rodrigo Suhr on 5/27/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SyncConfig.h"

@interface SecurityUtil : NSObject

+ (SecurityUtil *)getInstance;
- (instancetype)initWithSyncConfig:(SyncConfig *)syncConfig;
- (NSData *)encryptMessage:(NSData *)message;
- (NSData *)decryptMessage:(NSData *)message;

@end
