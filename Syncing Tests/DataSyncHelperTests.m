//
//  DataSyncHelperTests.m
//  Syncing
//
//  Created by Rodrigo Suhr on 3/9/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SyncManager.h"

@interface DataSyncHelperTests : XCTestCase

@property (nonatomic) id syncManagerRegistros;
@property (nonatomic) id syncManagerEmpresas;
@property (nonatomic) id syncManagerFormularios;
@property (nonatomic) NSMutableArray *modifiedFiles;

@end

@implementation DataSyncHelperTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _syncManagerRegistros = OCMProtocolMock(@protocol(SyncManager));
    _syncManagerEmpresas = OCMProtocolMock(@protocol(SyncManager));
    _syncManagerFormularios = OCMProtocolMock(@protocol(SyncManager));
    
    // Registros
    OCMStub([_syncManagerRegistros getIdentifier]).andReturn(@"registros");
    OCMStub([_syncManagerRegistros saveNewData:[OCMArg any] withDeviceId:[OCMArg any]]).andReturn([[NSMutableArray alloc] init]);
    
    NSString *regFile = @"/Users/rodrigosuhr/Dev/ios-syncing/Syncing\ Tests/modified-data-registros.json";
    NSString *jsonStrRegs = [[NSString alloc] initWithContentsOfFile:regFile encoding:NSUTF8StringEncoding error:nil];
    NSData *dataRegs = [jsonStrRegs dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSMutableArray *registrosModified = [NSJSONSerialization JSONObjectWithData:dataRegs options:kNilOptions error:nil];
    
    OCMStub([_syncManagerRegistros getModifiedData]).andReturn(registrosModified);
    OCMStub([_syncManagerRegistros shouldSendSingleObject]).andReturn(NO);
    
    _modifiedFiles = [[NSMutableArray alloc] init];
    [_modifiedFiles addObject:@"imagem1.jpg"];
    [_modifiedFiles addObject:@"imagem2.jpg"];
    [_modifiedFiles addObject:@"imagem3.jpg"];
    
    OCMStub([_syncManagerRegistros getModifiedFiles]).andReturn(_modifiedFiles);
    OCMStub([_syncManagerRegistros getResponseIdentifier]).andReturn(@"registros_id");
    OCMStub([_syncManagerRegistros getModifiedFilesForObject:[OCMArg any]]).andReturn(_modifiedFiles);
    OCMStub([_syncManagerRegistros hasModifiedData]).andReturn(YES);
    
    // Empresas
    OCMStub([_syncManagerEmpresas getIdentifier]).andReturn(@"empresas");
    OCMStub([_syncManagerEmpresas saveNewData:[OCMArg any] withDeviceId:[OCMArg any]]).andReturn([[NSMutableArray alloc] init]);
    
    NSString *empFile = @"/Users/rodrigosuhr/Dev/ios-syncing/Syncing\ Tests/modified-data-empresas.json";
    NSString *jsonStrEmps = [[NSString alloc] initWithContentsOfFile:empFile encoding:NSUTF8StringEncoding error:nil];
    NSData *dataEmps = [jsonStrEmps dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSMutableArray *empresasModified = [NSJSONSerialization JSONObjectWithData:dataEmps options:kNilOptions error:nil];
    
    OCMStub([_syncManagerEmpresas getModifiedData]).andReturn(empresasModified);
    OCMStub([_syncManagerEmpresas shouldSendSingleObject]).andReturn(NO);
    OCMStub([_syncManagerEmpresas getModifiedFiles]).andReturn([[NSMutableArray alloc] init]);
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

@end
