//
//  ServerCommTests.m
//  Syncing
//
//  Created by Rodrigo Suhr on 3/5/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import "ServerComm.h"
#import "CustomException.h"

@interface ServerCommTests : XCTestCase

@end

@implementation ServerCommTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [OHHTTPStubs removeAllStubs];
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
 test200Response
 */
- (void)test200Response
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        NSDictionary *obj = @{@"response":@"200"};
        return [OHHTTPStubsResponse responseWithJSONObject:obj statusCode:200 headers:nil];
    }];
    
    ServerComm *serverComm = [[ServerComm alloc] init];
    NSDictionary *data = @{@"token":@"123"};
    
    NSDictionary *postResponse = [serverComm post:@"http://www.estudio89.com.br" withData:data];
    
    XCTAssertEqualObjects([postResponse valueForKey:@"response"], @"200");
}

/**
 test403Response
 */
- (void)test403Response
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        NSData *stubData = [@"403response" dataUsingEncoding:NSUTF8StringEncoding];
        return [OHHTTPStubsResponse responseWithData:stubData statusCode:403 headers:nil];
    }];
    
    ServerComm *serverComm = [[ServerComm alloc] init];
    NSDictionary *data = @{@"token":@"123"};
    
    XCTAssertThrowsSpecific([serverComm post:@"http://www.estudio89.com.br" withData:data], Http403Exception);
}

/**
 test408Response
 */
- (void)test408Response
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        NSData *stubData = [@"408response" dataUsingEncoding:NSUTF8StringEncoding];
        return [OHHTTPStubsResponse responseWithData:stubData statusCode:408 headers:nil];
    }];
    
    ServerComm *serverComm = [[ServerComm alloc] init];
    NSDictionary *data = @{@"token":@"123"};
    
    XCTAssertThrowsSpecific([serverComm post:@"http://www.estudio89.com.br" withData:data], Http408Exception);
}

/**
 test500Response
 */
- (void)test500Response
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        NSData *stubData = [@"500response" dataUsingEncoding:NSUTF8StringEncoding];
        return [OHHTTPStubsResponse responseWithData:stubData statusCode:500 headers:nil];
    }];
    
    ServerComm *serverComm = [[ServerComm alloc] init];
    NSDictionary *data = @{@"token":@"123"};
    
    XCTAssertThrowsSpecific([serverComm post:@"http://www.estudio89.com.br" withData:data], Http500Exception);
}

/**
 testContentType
 */
- (void)testContentType
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        NSData *stubData = [@"testContentType" dataUsingEncoding:NSUTF8StringEncoding];
        return [OHHTTPStubsResponse responseWithData:stubData statusCode:200 headers:@{@"Content-Type":@"text/html; charset=utf-8"}];
    }];
    
    ServerComm *serverComm = [[ServerComm alloc] init];
    NSDictionary *data = @{@"token":@"123"};
    
    XCTAssertThrowsSpecific([serverComm post:@"http://www.estudio89.com.br" withData:data], Http403Exception);
}

@end
