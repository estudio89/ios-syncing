//
//  SecuryUtilTests.m
//  Syncing
//
//  Created by Rodrigo Suhr on 6/1/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>
#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>
#import "SyncConfig.h"
#import "SecurityUtil.h"
#import "AsyncBus.h"

@interface SecuryUtilTests : XCTestCase

//@property (nonatomic) SyncConfig *syncConfig;
//@property (nonatomic) SecurityUtil *securityUtil;
//@property (nonatomic) AsyncBus *bus;

@end

@implementation SecuryUtilTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    //_syncConfig = mock([SyncConfig class]);
    //[given([_syncConfig isEncryptionActive]) willReturnBool:YES];
    //[given([_syncConfig getEncryptionPassword]) willReturn:@"1234"];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

- (void)testEncryptionActive
{
    AsyncBus *bus = [[AsyncBus alloc] init];
    SyncConfig *syncConfig = [[SyncConfig alloc] initWithBus:bus];
    id _mSyncConfig = OCMPartialMock(syncConfig);
    OCMStub([_mSyncConfig isEncryptionActive]).andReturn(YES);
    OCMStub([_mSyncConfig getEncryptionPassword]).andReturn(@"1234");
    
    SecurityUtil *securityUtil = [[SecurityUtil alloc] initWithSyncConfig:_mSyncConfig];
    
    NSString *message = @"Ação";
    NSData *encryptedData = [securityUtil encryptMessage:message];
    NSString *encrypted = [[NSString alloc] initWithData:encryptedData
                                                encoding:NSISOLatin1StringEncoding];
    NSString *decrypted = [securityUtil decryptMessage:encrypted];
    NSLog(@"%@", encrypted);
    assertThat(message, is(decrypted));
    
    NSString *strEncrypted = @"\\x03\\x01Y\\x053\\xec\\x03+}\\x9aZ]\\xc1\\xac\\xbd\\xb5\\xa9\\xe1$\\x03\\xaf\\x15\\xfa[\\x16\\x0c\\xa2\\xef\\xf8\\xf0\\x9d\\x04\\xd7\\x1c_\\x9e\\xed\\x17h\\x04^\\xee\\xe9w\\xbc\\xe1\\xa87\\x8c\\xbb5`v\\x82\\xaa\\xe8\\xa41\\xd1\\x80\\x8a\\xfe\\xc8\\xf30\\xb3\\x8b\\xa2\\xcf\\x18 \\xdc\\xc2\\xe0=\\xfb>\\xed\\xf3\\x00D\\x93";
    
    decrypted = [securityUtil decryptMessage:strEncrypted];
    assertThat(message, is(decrypted));
}

- (void)testEncryptionInactive
{
    AsyncBus *bus = [[AsyncBus alloc] init];
    SyncConfig *syncConfig = [[SyncConfig alloc] initWithBus:bus];
    id _mSyncConfig = OCMPartialMock(syncConfig);
    OCMStub([_mSyncConfig isEncryptionActive]).andReturn(NO);
    
    SecurityUtil *securityUtil = [[SecurityUtil alloc] initWithSyncConfig:_mSyncConfig];
    
    NSString *message = @"Rodrigo";
    NSData *encryptedData = [securityUtil encryptMessage:message];
    NSString *encrypted = [[NSString alloc] initWithBytes:[encryptedData bytes]
                                                   length:[encryptedData length]
                                                 encoding:NSUTF8StringEncoding];
    NSString *decrypted = [securityUtil decryptMessage:encrypted];
    
    assertThat(message, is(decrypted));
    assertThat(message, is(encrypted));
}

@end
