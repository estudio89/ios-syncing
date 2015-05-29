//
//  SecurityUtil.m
//  Syncing
//
//  Created by Rodrigo Suhr on 5/27/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "SecurityUtil.h"
#import "SyncingInjection.h"
#import <RNCryptor/RNEncryptor.h>
#import <RNCryptor/RNDecryptor.h>

@interface SecurityUtil ()

@property (nonatomic, strong, readwrite) SyncConfig *syncConfig;

@end

@implementation SecurityUtil

/**
 * getInstance
 */
+ (SecurityUtil *)getInstance
{
    return [SyncingInjection get:[SecurityUtil class]];
}

/**
 * initWithSyncConfig
 */
- (instancetype)initWithSyncConfig:(SyncConfig *)syncConfig
{
    self = [super init];
    if (self)
    {
        _syncConfig = syncConfig;
    }
    
    return self;
}

/**
 * encryptMessage
 */
- (NSData *)encryptMessage:(NSString *)message
{
    NSData *encryptedData = [message dataUsingEncoding:NSUTF8StringEncoding];
 
    if ([_syncConfig isEncryptionActive])
    {
        NSError *error;
        NSData *data = [message dataUsingEncoding:NSISOLatin1StringEncoding];
        encryptedData = [RNEncryptor encryptData:data
                                    withSettings:kRNCryptorAES256Settings
                                        password:[_syncConfig getEncryptionPassword]
                                           error:&error];
    }

    return encryptedData;
}

/**
 * decryptMessage
 */
- (NSString *)decryptMessage:(NSString *)data
{
    if ([_syncConfig isEncryptionActive])
    {
        NSError *error;
        NSData *decryptedData = [RNDecryptor decryptData:[data dataUsingEncoding:NSISOLatin1StringEncoding]
                                            withPassword:[_syncConfig getEncryptionPassword]
                                                   error:&error];
        data = [[NSString alloc] initWithBytes:[decryptedData bytes] length:[decryptedData length] encoding:NSISOLatin1StringEncoding];
    }
    
    return data;
}

@end
