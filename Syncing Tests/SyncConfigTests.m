//
//  SyncConfigTests.m
//  Syncing
//
//  Created by Rodrigo Suhr on 3/5/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "SyncConfig.h"
#import "TestSyncManager.h"

@interface SyncConfigTests : XCTestCase

@end

@implementation SyncConfigTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
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

/**
 testSyncConfig
 */
- (void)testSyncConfig
{
    SyncConfig *syncC = [[SyncConfig alloc] init];
    
    [syncC setConfigFile:@"/Users/rodrigosuhr/Dev/ios-syncing/Syncing\ Tests/syncing-config.json"];
    
    // GetDataUrl
    XCTAssertEqualObjects([syncC getGetDataUrl], @"http://api.estudio89.com.br/get-data");
    
    // SendDataUrl
    XCTAssertEqualObjects([syncC getSendDataUrl], @"http://api.estudio89.com.br/send-data");
    
    // AuthenticateUrl
    XCTAssertEqualObjects([syncC getAuthenticateUrl], @"http://api.estudio89.com.br/auth");
    
    // AccountType
    XCTAssertEqualObjects([syncC getAccountType], @"br.com.estudio89");
    
    // SyncManagers
    XCTAssertTrue([syncC.getSyncManagers count] == 1);
    XCTAssertEqualObjects([TestSyncManager class], [[syncC.getSyncManagers objectAtIndex:0] class]);
    XCTAssertEqualObjects([TestSyncManager class], [[syncC getSyncManager:@"test"] class]);
    XCTAssertEqualObjects([TestSyncManager class], [[syncC getSyncManagerByResponseId:@"test_id"] class]);
    XCTAssertEqualObjects([syncC getGetDataUrlForModel:@"test"], @"http://api.estudio89.com.br/test/");
}

@end
