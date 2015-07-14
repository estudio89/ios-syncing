//
//  SyncManagerTests.m
//  Syncing
//
//  Created by Rodrigo Suhr on 7/14/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>
#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>
#import "TestSyncManager.h"
#import <MagicalRecord/MagicalRecord.h>

@interface SyncManagerTests : XCTestCase

@property (nonatomic) TestSyncManager *testSyncManager;

@end

@implementation SyncManagerTests

- (void)setUp {
    [super setUp];
    //[MagicalRecord setupCoreDataStackWithInMemoryStore];
    
    _testSyncManager = [[TestSyncManager alloc] init];
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

- (void)testVerifyFields
{
//    XCTAssertEqual(_testSyncManager.dateAttribute.name, @"pubDate");
//    XCTAssertEqual([[_testSyncManager.parentAttributes allKeys] count], 1);
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF IN %@", [_testSyncManager.parentAttributes allKeys]];
//    XCTAssertTrue([predicate evaluateWithObject:@"parent_id"] == YES);
//    XCTAssertEqual([[_testSyncManager.childrenAttributes allKeys] count], 2);
    assertThat(_testSyncManager.dateAttribute.name, is(@"pubDate"));
    assertThatInt([[_testSyncManager.parentAttributes allKeys] count], equalToInt(1));
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF IN %@", [_testSyncManager.parentAttributes allKeys]];
    assertThatBool([predicate evaluateWithObject:@"parent_id"], isTrue());
    assertThatInt([[_testSyncManager.childrenAttributes allKeys] count], equalToInt(2));
}

@end
