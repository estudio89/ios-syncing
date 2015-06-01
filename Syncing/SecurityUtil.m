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
#import <RNCryptor/RNCryptor.h>

@interface SecurityUtil ()

@property (nonatomic, strong, readwrite) SyncConfig *syncConfig;

@end

@implementation SecurityUtil

static const RNCryptorSettings kRNCryptorAES256SettingsE89 = {
    .algorithm = kCCAlgorithmAES128,
    .blockSize = kCCBlockSizeAES128,
    .IVSize = kCCBlockSizeAES128,
    .options = kCCOptionPKCS7Padding,
    .HMACAlgorithm = kCCHmacAlgSHA256,
    .HMACLength = CC_SHA256_DIGEST_LENGTH,
    
    .keySettings = {
        .keySize = kCCKeySizeAES256,
        .saltSize = 8,
        .PBKDFAlgorithm = kCCPBKDF2,
        .PRF = kCCPRFHmacAlgSHA1,
        .rounds = 100
    },
    
    .HMACKeySettings = {
        .keySize = kCCKeySizeAES256,
        .saltSize = 8,
        .PBKDFAlgorithm = kCCPBKDF2,
        .PRF = kCCPRFHmacAlgSHA1,
        .rounds = 100
    }
};

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
                                    withSettings:kRNCryptorAES256SettingsE89
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
                                            withSettings:kRNCryptorAES256SettingsE89
                                                password:[_syncConfig getEncryptionPassword]
                                                   error:&error];
        data = [[NSString alloc] initWithBytes:[decryptedData bytes] length:[decryptedData length] encoding:NSISOLatin1StringEncoding];
    }
    
    return data;
}

@end
