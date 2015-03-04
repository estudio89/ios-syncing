//
//  Syncing_Tests.m
//  Syncing Tests
//
//  Created by Rodrigo Suhr on 3/2/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SyncConfig.h"

@interface Syncing_Tests : XCTestCase

@end

@implementation Syncing_Tests

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

- (void)testSyncConfig
{
    SyncConfig *syncC = [[SyncConfig alloc] init];
    id mockSyncC = [OCMockObject partialMockForObject:syncC];
    
    [mockSyncC setTimestamp:@"03-02-2015 17:16:21"];
    
    XCTAssertEqualObjects([mockSyncC getTimestamp], @"03-02-2015 17:16:21");
    
    [mockSyncC setConfigFile:@"/Syncing Tests/syncing-config.json"];
    //[mockSyncC setConfigFile:[[NSBundle mainBundle] pathForResource:@"syncing-config" ofType:@"json"]];
}

@end
	