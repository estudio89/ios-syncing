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
#import "SyncConfig.h"
#import "DataSyncHelper.h"
#import "CustomTransactionManager.h"
#import "ThreadChecker.h"
#import "AsyncBus.h"

@interface DataSyncHelperTests : XCTestCase

@property (nonatomic) id syncManagerRegistros;
@property (nonatomic) id syncManagerEmpresas;
@property (nonatomic) id syncManagerFormularios;
@property (nonatomic) id syncConfig;
@property (nonatomic) id serverComm;
@property (nonatomic) id bus;
@property (nonatomic) NSMutableArray *modifiedFiles;
@property (nonatomic) DataSyncHelper *dataSyncHelper;
@property (nonatomic) CustomTransactionManager *customTransactionManager;
@property (nonatomic) ThreadChecker *threadChecker;

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
    OCMStub([_syncManagerEmpresas getResponseIdentifier]).andReturn(@"empresas_id");
    OCMStub([_syncManagerEmpresas hasModifiedData]).andReturn(YES);
    
    // Formularios
    OCMStub([_syncManagerFormularios getIdentifier]).andReturn(@"formularios");
    OCMStub([_syncManagerFormularios saveNewData:[OCMArg any] withDeviceId:[OCMArg any]]).andReturn([[NSMutableArray alloc] init]);
    OCMStub([_syncManagerFormularios getModifiedData]).andReturn([[NSMutableArray alloc] init]);
    OCMStub([_syncManagerFormularios shouldSendSingleObject]).andReturn(NO);
    OCMStub([_syncManagerFormularios getModifiedFiles]).andReturn([[NSMutableArray alloc] init]);
    OCMStub([_syncManagerFormularios getResponseIdentifier]).andReturn(@"formularios_id");
    OCMStub([_syncManagerFormularios hasModifiedData]).andReturn(NO);
    
    // SyncConfig
    _syncConfig = OCMClassMock([SyncConfig class]);
    OCMStub([_syncConfig getAuthToken]).andReturn(@"123");
    OCMStub([_syncConfig getTimestamp]).andReturn(@"666");
    //OCMStub([_syncConfig getDatabase]).andReturn(@"");
    OCMStub([_syncConfig getGetDataUrl]).andReturn(@"http://127.0.0.1:8000/api/get-data/");
    OCMStub([_syncConfig getSendDataUrl]).andReturn(@"http://127.0.0.1:8000/api/send-data/");
    OCMStub([_syncConfig getDeviceId]).andReturn(@"asdasda");
    NSMutableArray *syncManagers = [[NSMutableArray alloc] init];
    [syncManagers addObject:_syncManagerRegistros];
    [syncManagers addObject:_syncManagerEmpresas];
    [syncManagers addObject:_syncManagerFormularios];
    OCMStub([_syncConfig getSyncManagers]).andReturn(syncManagers);
    OCMStub([_syncConfig getSyncManager:@"registros"]).andReturn(_syncManagerRegistros);
    OCMStub([_syncConfig getSyncManager:@"empresas"]).andReturn(_syncManagerEmpresas);
    OCMStub([_syncConfig getSyncManager:@"formularios"]).andReturn(_syncManagerFormularios);
    OCMStub([_syncConfig getSyncManagerByResponseId:@"registros_id"]).andReturn(_syncManagerRegistros);
    OCMStub([_syncConfig getSyncManagerByResponseId:@"empresas_id"]).andReturn(_syncManagerEmpresas);
    OCMStub([_syncConfig getSyncManagerByResponseId:@"formularios_id"]).andReturn(_syncManagerFormularios);
    
    OCMStub([_syncConfig getGetDataUrlForModel:@"registros"]).andReturn(@"http://127.0.0.1:8000/api/get-data/registros/");
    
    // CustomTransactionManager
    _customTransactionManager = [[CustomTransactionManager alloc] init];
    
    // ServerComm
    NSString *jsonFile = @"/Users/rodrigosuhr/Dev/ios-syncing/Syncing\ Tests/get-data-response.json";
    NSString *jsonResponse = [[NSString alloc] initWithContentsOfFile:jsonFile encoding:NSUTF8StringEncoding error:nil];
    NSData *dataJsonResponse = [jsonResponse dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSDictionary *jsonGetResponse = [NSJSONSerialization JSONObjectWithData:dataJsonResponse options:kNilOptions error:nil];
    
    jsonFile = @"/Users/rodrigosuhr/Dev/ios-syncing/Syncing\ Tests/send-data-response.json";
    jsonResponse = [[NSString alloc] initWithContentsOfFile:jsonFile encoding:NSUTF8StringEncoding error:nil];
    dataJsonResponse = [jsonResponse dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSDictionary *jsonSendResponse = [NSJSONSerialization JSONObjectWithData:dataJsonResponse options:kNilOptions error:nil];
    
    jsonFile = @"/Users/rodrigosuhr/Dev/ios-syncing/Syncing\ Tests/get-data-for-model-response.json";
    jsonResponse = [[NSString alloc] initWithContentsOfFile:jsonFile encoding:NSUTF8StringEncoding error:nil];
    dataJsonResponse = [jsonResponse dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSDictionary *jsonGetResponseForModel = [NSJSONSerialization JSONObjectWithData:dataJsonResponse options:kNilOptions error:nil];
    
    _serverComm = OCMClassMock([ServerComm class]);
    OCMStub([_serverComm post:[_syncConfig getGetDataUrl] withData:[OCMArg any]]).andReturn(jsonGetResponse);
    OCMStub([_serverComm post:[_syncConfig getSendDataUrl] withData:[OCMArg any] withFiles:[OCMArg any]]).andReturn(jsonSendResponse);
    OCMStub([_serverComm post:[_syncConfig getGetDataUrlForModel:@"registros"] withData:[OCMArg any]]).andReturn(jsonGetResponseForModel);
    
    // ThreadChecker
    _threadChecker = [[ThreadChecker alloc] init];
    
    // AsyncBus
    _bus = OCMClassMock([AsyncBus class]);
    
    // DataSyncHelper
    _dataSyncHelper = [[DataSyncHelper alloc] initWithServer:_serverComm
                                           withThreadChecker:_threadChecker
                                              withSyncConfig:_syncConfig
                                      withTransactionManager:_customTransactionManager
                                                     withBus:_bus];
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
 testGetDataFromServer
 */
- (void)testGetDataFromServer
{
    NSString *jsonFile = @"/Users/rodrigosuhr/Dev/ios-syncing/Syncing\ Tests/get-data-request.json";
    NSString *json = [[NSString alloc] initWithContentsOfFile:jsonFile encoding:NSUTF8StringEncoding error:nil];
    NSData *dataRequest = [json dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSDictionary *jsonDataRequest = [NSJSONSerialization JSONObjectWithData:dataRequest options:kNilOptions error:nil];
    
    jsonFile = @"/Users/rodrigosuhr/Dev/ios-syncing/Syncing\ Tests/get-data-response.json";
    json = [[NSString alloc] initWithContentsOfFile:jsonFile encoding:NSUTF8StringEncoding error:nil];
    NSData *dataResponse = [json dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    
    NSDictionary *data = @{@"token":[jsonDataRequest valueForKey:@"token"],
                           @"timestamp":[jsonDataRequest valueForKey:@"timestamp"]};
    
    BOOL completed = [_dataSyncHelper getDataFromServer];
    
    NSDictionary *dd = @{@"tosken":@"1sd23", @"timestsamp":@"66sd60", @"sdsds":@"sdfsdf"};
    OCMVerify([_serverComm post:@"http://127.0.0.1:8000/api/get-data/" withData:dd]);
    //OCMVerify([_serverComm post:@"http://127.0.0.1:8000/api/get-data/" withData:[OCMArg any]]);
}

@end
