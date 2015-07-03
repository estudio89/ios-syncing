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
- (NSData *)encryptMessage:(NSData *)message
{
    NSData *encryptedData = message;
 
    if ([_syncConfig isEncryptionActive])
    {
        NSError *error;
        encryptedData = [RNEncryptor encryptData:message
                                    withSettings:kRNCryptorAES256SettingsE89
                                        password:[_syncConfig getEncryptionPassword]
                                           error:&error];
    }

    return encryptedData;
}

/**
 * decryptMessage
 */
- (NSData *)decryptMessage:(NSData *)message
{
    NSData *decryptedData = message;
    
    if ([_syncConfig isEncryptionActive])
    {
        NSError *error;
        decryptedData = [RNDecryptor decryptData:message
                                    withSettings:kRNCryptorAES256SettingsE89
                                        password:[_syncConfig getEncryptionPassword]
                                           error:&error];
    }
    
    return decryptedData;
}

@end
