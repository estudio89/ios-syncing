//
//  ServerAuthenticateTests.m
//  Syncing
//
//  Created by Rodrigo Suhr on 3/12/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>

#import "ServerAuthenticate.h"
#import "ServerComm.h"
#import "SyncConfig.h"
#import "AsyncBus.h"
#import "CustomException.h"

@interface ServerAuthenticateTests : XCTestCase

@property (nonatomic) ServerAuthenticate *serverAuthenticate;
@property (nonatomic) SyncConfig *syncConfig;
@property (nonatomic) ServerComm *serverComm;
@property (nonatomic) AsyncBus *bus;

@end

@implementation ServerAuthenticateTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _syncConfig = mock([SyncConfig class]);
    _serverComm = mock([ServerComm class]);
    _bus = mock([AsyncBus class]);
    _serverAuthenticate = [[ServerAuthenticate alloc] initWithServerComm:_serverComm
                                                          withSyncCOnfig:_syncConfig
                                                            withAsyncBus:_bus];
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
 * testSyncAuthentication
 */
- (void)testSyncAuthentication
{
    NSDictionary *jsonResponse = @{@"verified":@"true", @"token":@"testToken"};
    [given([_serverComm post:[_syncConfig getGetDataUrl] withData:anything()]) willReturn:jsonResponse];
    
    NSString *authToken = [_serverAuthenticate syncAuthentication:@"userT" withPasswd:@"passwdT"];
    
    MKTArgumentCaptor *argument = [[MKTArgumentCaptor alloc] init];
    [verify(_bus) post:[argument capture] withNotificationname:[argument capture]];
    SuccessfulLoginEvent *sLoginEvent = [[argument allValues] objectAtIndex:0];
    assertThat([sLoginEvent getUsername], is(@"userT"));
    assertThat([sLoginEvent getAuthToken], is(@"testToken"));
    assertThat([[argument allValues] objectAtIndex:1], is(@"SuccessfulLoginEvent"));
    assertThat(authToken, is(@"testToken"));
}

/**
 * testSyncAuthenticationFail
 */
- (void)testSyncAuthenticationFail
{
    NSDictionary *jsonResponse = @{@"verified":@"false"};
    [given([_serverComm post:[_syncConfig getGetDataUrl] withData:anything()]) willReturn:jsonResponse];
    
    NSString *authToken = [_serverAuthenticate syncAuthentication:@"userT" withPasswd:@"passwdT"];
    
    MKTArgumentCaptor *argument = [[MKTArgumentCaptor alloc] init];
    [verify(_bus) post:[argument capture] withNotificationname:[argument capture]];
    assertThat([[argument allValues] objectAtIndex:0], instanceOf([WrongCredentialsEvent class]));
    assertThat([[argument allValues] objectAtIndex:1], is(@"WrongCredentialsEvent"));
    XCTAssertNil(authToken);
}

/**
 * testSyncAuthenticationError403
 */
- (void)testSyncAuthenticationError403
{
    Http403Exception *e = [Http403Exception exceptionWithName:@"testSyncAuthenticationError403" reason:@"Test" userInfo:nil];
    [given([_serverComm post:[_syncConfig getGetDataUrl] withData:anything()]) willThrow:e];
    
    NSString *authToken = [_serverAuthenticate syncAuthentication:@"userT" withPasswd:@"passwdT"];
    
    MKTArgumentCaptor *argument = [[MKTArgumentCaptor alloc] init];
    [verify(_bus) post:[argument capture] withNotificationname:[argument capture]];
    assertThat([[argument allValues] objectAtIndex:0], instanceOf([BlockedLoginEvent class]));
    assertThat([[argument allValues] objectAtIndex:1], is(@"BlockedLoginEvent"));
    XCTAssertNil(authToken);
}

/**
 * testSyncAuthenticationException
 */
- (void)testSyncAuthenticationException
{
    NSException *e = [NSException exceptionWithName:@"testSyncAuthenticationException" reason:@"Test" userInfo:nil];
    [given([_serverComm post:[_syncConfig getGetDataUrl] withData:anything()]) willThrow:e];
    
    NSString *authToken = [_serverAuthenticate syncAuthentication:@"userT" withPasswd:@"passwdT"];
    
    MKTArgumentCaptor *argument = [[MKTArgumentCaptor alloc] init];
    [verify(_bus) post:[argument capture] withNotificationname:[argument capture]];
    assertThat([[argument allValues] objectAtIndex:0], instanceOf([ConnectionErrorEvent class]));
    assertThat([[argument allValues] objectAtIndex:1], is(@"ConnectionErrorEvent"));
    XCTAssertNil(authToken);
}

@end
