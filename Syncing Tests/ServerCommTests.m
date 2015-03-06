//
//  ServerCommTests.m
//  Syncing
//
//  Created by Rodrigo Suhr on 3/5/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "ServerComm.h"

@interface ServerCommTests : XCTestCase

@end

@implementation ServerCommTests

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
 test403Response
 */
- (void)test403Response
{
    ServerComm *serverComm = [[ServerComm alloc] init];
    id test = OCMPartialMock(serverComm);
    
    NSDictionary *data = @{@"token":@"123"};
    
    //[serverComm post:@"http://www.estudio89.com.br/" withData:data];
}

@end
