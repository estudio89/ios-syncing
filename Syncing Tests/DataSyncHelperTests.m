//
//  DataSyncHelperTests.m
//  Syncing
//
//  Created by Rodrigo Suhr on 3/9/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>

#import "SyncManager.h"
#import "SyncConfig.h"
#import "DataSyncHelper.h"
#import "CustomTransactionManager.h"
#import "ThreadChecker.h"
#import "AsyncBus.h"
#import "ServerComm.h"
#import "DatabaseProvider.h"

@interface DataSyncHelperTests : XCTestCase

@property (nonatomic) id <SyncManager> syncManagerRegistros;
@property (nonatomic) id <SyncManager> syncManagerEmpresas;
@property (nonatomic) id <SyncManager> syncManagerFormularios;
@property (nonatomic) SyncConfig *syncConfig;
@property (nonatomic) ServerComm *serverComm;
@property (nonatomic) AsyncBus *bus;
@property (nonatomic) DataSyncHelper *dataSyncHelper;
@property (nonatomic) CustomTransactionManager *customTransactionManager;
@property (nonatomic) ThreadChecker *threadChecker;
@property (nonatomic) DatabaseProvider *database;
@property (nonatomic) NSMutableArray *modifiedFiles;

@end

@implementation DataSyncHelperTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _syncManagerRegistros = mockProtocol(@protocol(SyncManager));
    _syncManagerEmpresas = mockProtocol(@protocol(SyncManager));
    _syncManagerFormularios = mockProtocol(@protocol(SyncManager));
    
    // Registros
    [given([_syncManagerRegistros getIdentifier]) willReturn:@"registros"];
    [given([_syncManagerRegistros saveNewData:anything() withDeviceId:anything() withParameters:anything() withContext:nil]) willReturn:[[NSMutableArray alloc] init]];
    
    NSString *regFile = @"/Users/rodrigosuhr/Dev/ios-syncing/Syncing\ Tests/modified-data-registros.json";
    NSString *jsonStrRegs = [[NSString alloc] initWithContentsOfFile:regFile encoding:NSUTF8StringEncoding error:nil];
    NSData *dataRegs = [jsonStrRegs dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSMutableArray *registrosModified = [NSJSONSerialization JSONObjectWithData:dataRegs options:kNilOptions error:nil];
    
    [given([_syncManagerRegistros getModifiedDataWithContext:nil]) willReturn:registrosModified];
    [given([_syncManagerRegistros shouldSendSingleObject]) willReturnBool:NO];
    
    _modifiedFiles = [[NSMutableArray alloc] init];
    [_modifiedFiles addObject:@"imagem1.jpg"];
    [_modifiedFiles addObject:@"imagem2.jpg"];
    [_modifiedFiles addObject:@"imagem3.jpg"];
    
    [given([_syncManagerRegistros getModifiedFilesWithContext:nil]) willReturn:_modifiedFiles];
    [given([_syncManagerRegistros getResponseIdentifier]) willReturn:@"registros_id"];
    [[given([_syncManagerRegistros getModifiedFilesForObject:anything() withContext:nil]) willReturn:[_modifiedFiles objectAtIndex:0]] willReturn:[_modifiedFiles subarrayWithRange:NSMakeRange(1, [_modifiedFiles count]-1)]];
    [given([_syncManagerRegistros hasModifiedDataWithContext:nil]) willReturnBool:YES];
    
    // Empresas
    [given([_syncManagerEmpresas getIdentifier]) willReturn:@"empresas"];
    [given([_syncManagerEmpresas saveNewData:anything() withDeviceId:anything() withParameters:anything() withContext:nil]) willReturn:[[NSMutableArray alloc] init]];
    
    NSString *empFile = @"/Users/rodrigosuhr/Dev/ios-syncing/Syncing\ Tests/modified-data-empresas.json";
    NSString *jsonStrEmps = [[NSString alloc] initWithContentsOfFile:empFile encoding:NSUTF8StringEncoding error:nil];
    NSData *dataEmps = [jsonStrEmps dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSMutableArray *empresasModified = [NSJSONSerialization JSONObjectWithData:dataEmps options:kNilOptions error:nil];
    
    [given([_syncManagerEmpresas getModifiedDataWithContext:nil]) willReturn:empresasModified];
    [given([_syncManagerEmpresas shouldSendSingleObject]) willReturnBool:NO];
    [given([_syncManagerEmpresas getModifiedFilesWithContext:nil]) willReturn:[[NSMutableArray alloc] init]];
    [given([_syncManagerEmpresas getResponseIdentifier]) willReturn:@"empresas_id"];
    [given([_syncManagerEmpresas hasModifiedDataWithContext:nil]) willReturnBool:YES];
    
    // Formularios
    [given([_syncManagerFormularios getIdentifier]) willReturn:@"formularios"];
    [given([_syncManagerFormularios saveNewData:anything() withDeviceId:anything() withParameters:anything() withContext:nil]) willReturn:[[NSMutableArray alloc] init]];
    [given([_syncManagerFormularios getModifiedDataWithContext:nil]) willReturn:[[NSMutableArray alloc] init]];
    [given([_syncManagerFormularios shouldSendSingleObject]) willReturnBool:NO];
    [given([_syncManagerFormularios getModifiedFilesWithContext:nil]) willReturn:[[NSMutableArray alloc] init]];
    [given([_syncManagerFormularios getResponseIdentifier]) willReturn:@"formularios_id"];
    [given([_syncManagerFormularios hasModifiedDataWithContext:nil]) willReturnBool:NO];
    
    // SyncConfig
    _syncConfig = mock([SyncConfig class]);
    _database = mock([DatabaseProvider class]);
    [given([_syncConfig getAuthToken]) willReturn:@"123"];
    [given([_syncConfig getTimestamps]) willReturn:@"666"];
    [given([_syncConfig getGetDataUrl]) willReturn:@"http://127.0.0.1:8000/api/get-data/"];
    [given([_syncConfig getSendDataUrl]) willReturn:@"http://127.0.0.1:8000/api/send-data/"];
    [given([_syncConfig getDeviceId]) willReturn:@"asdasda"];
    NSMutableArray *syncManagers = [[NSMutableArray alloc] init];
    [syncManagers addObject:_syncManagerRegistros];
    [syncManagers addObject:_syncManagerEmpresas];
    [syncManagers addObject:_syncManagerFormularios];
    [given([_syncConfig getSyncManagers]) willReturn:syncManagers];
    [given([_syncConfig getSyncManager:@"registros"]) willReturn:_syncManagerRegistros];
    [given([_syncConfig getSyncManager:@"empresas"]) willReturn:_syncManagerEmpresas];
    [given([_syncConfig getSyncManager:@"formularios"]) willReturn:_syncManagerFormularios];
    [given([_syncConfig getSyncManagerByResponseId:@"registros_id"]) willReturn:_syncManagerRegistros];
    [given([_syncConfig getSyncManagerByResponseId:@"empresas_id"]) willReturn:_syncManagerEmpresas];
    [given([_syncConfig getSyncManagerByResponseId:@"formularios_id"]) willReturn:_syncManagerFormularios];
    
    [given([_syncConfig getGetDataUrlForModel:@"registros"]) willReturn:@"http://127.0.0.1:8000/api/get-data/registros/"];
    
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
    
    _serverComm = mock([ServerComm class]);
    [given([_serverComm post:[_syncConfig getGetDataUrl] withData:anything()]) willReturn:jsonGetResponse];
    [given([_serverComm post:[_syncConfig getSendDataUrl] withData:anything() withFiles:anything()]) willReturn:jsonSendResponse];
    [given([_serverComm post:[_syncConfig getGetDataUrlForModel:@"registros"] withData:anything()]) willReturn:jsonGetResponseForModel];
    
    // ThreadChecker
    _threadChecker = [[ThreadChecker alloc] init];
    
    // AsyncBus
    _bus = mock([AsyncBus class]);
    
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
    BOOL completed = [_dataSyncHelper getDataFromServer];

    // verificando o post
    NSString *jsonFile = @"/Users/rodrigosuhr/Dev/ios-syncing/Syncing\ Tests/get-data-request.json";
    NSString *json = [[NSString alloc] initWithContentsOfFile:jsonFile encoding:NSUTF8StringEncoding error:nil];
    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];

    MKTArgumentCaptor *argument = [[MKTArgumentCaptor alloc] init];
    [verify(_serverComm) post:[argument capture] withData:[argument capture]];
    assertThat([[argument allValues] objectAtIndex:0], is(@"http://127.0.0.1:8000/api/get-data/"));
    assertThat([[argument allValues] objectAtIndex:1], is(jsonData));
    
    // verificando os dados
    jsonFile = @"/Users/rodrigosuhr/Dev/ios-syncing/Syncing\ Tests/get-data-response.json";
    json = [[NSString alloc] initWithContentsOfFile:jsonFile encoding:NSUTF8StringEncoding error:nil];
    data = [json dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    jsonData = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    
    NSMutableDictionary *registrosObj = [jsonData objectForKey:@"registros"];
    NSArray *registrosArray = [registrosObj objectForKey:@"data"];
    NSMutableDictionary *registrosParams = [[NSMutableDictionary alloc] initWithDictionary:registrosObj];
    [registrosParams removeObjectForKey:@"data"];
    
    NSMutableDictionary *empresasObj = [jsonData objectForKey:@"empresas"];
    NSArray *empresasArray = [empresasObj objectForKey:@"data"];
    NSMutableDictionary *empresasParams = [[NSMutableDictionary alloc] initWithDictionary:empresasObj];
    [empresasParams removeObjectForKey:@"data"];
    
    NSMutableDictionary *formulariosObj = [jsonData objectForKey:@"formularios"];
    NSArray *formulariosArray = [formulariosObj objectForKey:@"data"];
    NSMutableDictionary *formulariosParams = [[NSMutableDictionary alloc] initWithDictionary:formulariosObj];
    [formulariosParams removeObjectForKey:@"data"];
    
    assertThatBool([_customTransactionManager wasSuccessful], isTrue());
    
    // registros
    argument = [[MKTArgumentCaptor alloc] init];
    [MKTVerify(_syncManagerRegistros) saveNewData:[argument capture] withDeviceId:[argument capture] withParameters:[argument capture] withContext:nil];
    assertThat([[argument allValues] objectAtIndex:0], is(registrosArray));
    assertThat([[argument allValues] objectAtIndex:2], is(registrosParams));
    
    // empresas
    argument = [[MKTArgumentCaptor alloc] init];
    [MKTVerify(_syncManagerEmpresas) saveNewData:[argument capture] withDeviceId:[argument capture] withParameters:[argument capture] withContext:nil];
    assertThat([[argument allValues] objectAtIndex:0], is(empresasArray));
    assertThat([[argument allValues] objectAtIndex:2], is(empresasParams));
    
    // formularios
    argument = [[MKTArgumentCaptor alloc] init];
    [MKTVerify(_syncManagerFormularios) saveNewData:[argument capture] withDeviceId:[argument capture] withParameters:[argument capture] withContext:nil];
    assertThat([[argument allValues] objectAtIndex:0], is(formulariosArray));
    assertThat([[argument allValues] objectAtIndex:2], is(formulariosParams));
    
    // verificando o post
    [MKTVerify(_syncManagerRegistros) postEvent:anything() withBus:anything()];
    
    // verificando o timestamp
    [MKTVerify(_syncConfig) setTimestamps:@"777"];
    
    // get data realizado
    assertThatBool(completed, isTrue());
}

/**
 testGetDataFromServerFail
 */
- (void)testGetDataFromServerFail
{
    // thread interrompido
    ThreadChecker *threadChecker = mock([ThreadChecker class]);
    [given([threadChecker isValidThreadId:anything()]) willReturnBool:NO];
    //_dataSyncHelper.threadChecker = threadChecker;
    BOOL completed = [_dataSyncHelper getDataFromServer];
    
    // assegurando que o banco de dados nao fez commit
    //[verifyCount(_database, never()) saveTransaction];
    
    // assegurando que o timestamp nao foi salvo
    [MKTVerifyCount(_syncConfig, never()) setTimestamps:anything()];
    
    // get data naor ealizado
    assertThatBool(completed, isFalse());
}

/**
 testGetDataFromServerForModel
 */
- (void)testGetDataFromServerForModel
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:[NSNumber numberWithInt:5] forKey:@"newest_id"];
    BOOL completed = [_dataSyncHelper getDataFromServer:@"registros" withParameters:parameters];
    
    // verificando o post
    NSString *jsonFile = @"/Users/rodrigosuhr/Dev/ios-syncing/Syncing\ Tests/get-data-for-model-request.json";
    NSString *json = [[NSString alloc] initWithContentsOfFile:jsonFile encoding:NSUTF8StringEncoding error:nil];
    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    
    MKTArgumentCaptor *argument = [[MKTArgumentCaptor alloc] init];
    [MKTVerify(_serverComm) post:[argument capture] withData:[argument capture]];
    assertThat([[argument allValues] objectAtIndex:0], is(@"http://127.0.0.1:8000/api/get-data/registros/"));
    assertThat([[argument allValues] objectAtIndex:1], equalTo(jsonData));
    
    // verificando os dados
    jsonFile = @"/Users/rodrigosuhr/Dev/ios-syncing/Syncing\ Tests/get-data-for-model-response.json";
    json = [[NSString alloc] initWithContentsOfFile:jsonFile encoding:NSUTF8StringEncoding error:nil];
    data = [json dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    jsonData = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    
    NSMutableDictionary *registrosObj = [jsonData objectForKey:@"registros"];
    NSMutableDictionary *empresasObj = [jsonData objectForKey:@"empresas"];
    
    NSArray *registrosArray = [registrosObj objectForKey:@"data"];
    NSArray *empresasArray = [empresasObj objectForKey:@"data"];
    
    NSMutableDictionary *registrosParams = [[NSMutableDictionary alloc] initWithDictionary:registrosObj];
    [registrosParams removeObjectForKey:@"data"];
    
    NSMutableDictionary *empresasParams = [[NSMutableDictionary alloc] initWithDictionary:empresasObj];
    [empresasParams removeObjectForKey:@"data"];
    
    assertThatBool([_customTransactionManager wasSuccessful], isTrue());
    
    // registros
    argument = [[MKTArgumentCaptor alloc] init];
    [MKTVerify(_syncManagerRegistros) saveNewData:[argument capture] withDeviceId:[argument capture] withParameters:[argument capture] withContext:nil];
    assertThat([[argument allValues] objectAtIndex:0], is(registrosArray));
    assertThat([[argument allValues] objectAtIndex:2], is(registrosParams));
    
    // empresas
    argument = [[MKTArgumentCaptor alloc] init];
    [MKTVerify(_syncManagerEmpresas) saveNewData:[argument capture] withDeviceId:[argument capture] withParameters:[argument capture] withContext:nil];
    assertThat([[argument allValues] objectAtIndex:0], is(empresasArray));
    assertThat([[argument allValues] objectAtIndex:2], is(empresasParams));
    
    // formularios
    [verifyCount(_syncManagerFormularios, never()) saveNewData:anything() withDeviceId:anything() withParameters:anything() withContext:anything()];
    
    // verificando o timestamp
    [MKTVerifyCount(_syncConfig, never()) setTimestamps:anything()];
    
    // get data realizado
    assertThatBool(completed, isTrue());
}

/**
 testGetDataFromServerForModelFail
 */
- (void)testGetDataFromServerForModelFail
{
    // thread interrompido
    ThreadChecker *threadChecker = mock([ThreadChecker class]);
    [given([threadChecker isValidThreadId:anything()]) willReturnBool:NO];
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    [parameters setObject:[NSNumber numberWithInt:5] forKey:@"newest_id"];
    //_dataSyncHelper.threadChecker = threadChecker;
    
    BOOL completed = [_dataSyncHelper getDataFromServer:@"registros" withParameters:parameters];
    
    // assegurando que o banco de dados nao fez commit
    //[verifyCount(_database, never()) saveTransaction];
    
    // assegurando que o timestamp nao foi salvo
    [MKTVerifyCount(_syncConfig, never()) setTimestamps:anything()];
    
    // get data naor ealizado
    assertThatBool(completed, isFalse());
}

/**
 testSendDataToServerMultiple
 */
- (void)testSendDataToServerMultiple
{
    BOOL completed = [_dataSyncHelper sendDataToServer:nil];
    
    // verificando o post
    NSString *jsonFile = @"/Users/rodrigosuhr/Dev/ios-syncing/Syncing\ Tests/send-data-request.json";
    NSString *json = [[NSString alloc] initWithContentsOfFile:jsonFile encoding:NSUTF8StringEncoding error:nil];
    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    
    MKTArgumentCaptor *argument = [[MKTArgumentCaptor alloc] init];
    [MKTVerify(_serverComm) post:[argument capture] withData:[argument capture] withFiles:[argument capture]];
    assertThat([[argument allValues] objectAtIndex:0], is(@"http://127.0.0.1:8000/api/send-data/"));
    assertThat([[argument allValues] objectAtIndex:1], is(jsonData));
    assertThat([[argument allValues] objectAtIndex:2], is(_modifiedFiles));
    
    // verificando os dados
    jsonFile = @"/Users/rodrigosuhr/Dev/ios-syncing/Syncing\ Tests/send-data-response.json";
    json = [[NSString alloc] initWithContentsOfFile:jsonFile encoding:NSUTF8StringEncoding error:nil];
    data = [json dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    jsonData = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    NSArray *registrosArray = [jsonData objectForKey:@"registros_id"];
    NSArray *empresasArray = [jsonData objectForKey:@"empresas_id"];
    
    assertThatBool([_customTransactionManager wasSuccessful], isTrue());
    
    // registros
    argument = [[MKTArgumentCaptor alloc] init];
    [MKTVerify(_syncManagerRegistros) processSendResponse:[argument capture] withContext:nil];
    assertThat([[argument allValues] objectAtIndex:0], is(registrosArray));
    
    // empresas
    argument = [[MKTArgumentCaptor alloc] init];
    [MKTVerify(_syncManagerEmpresas) processSendResponse:[argument capture] withContext:nil];
    assertThat([[argument allValues] objectAtIndex:0], is(empresasArray));
    
    NSMutableDictionary *newEmpresasObj = [jsonData objectForKey:@"empresas"];
    NSArray *newEmpresasArray = [newEmpresasObj objectForKey:@"data"];
    NSMutableDictionary *newEmpresasParams = [[NSMutableDictionary alloc] initWithDictionary:newEmpresasObj];
    [newEmpresasParams removeObjectForKey:@"data"];
    
    argument = [[MKTArgumentCaptor alloc] init];
    [MKTVerify(_syncManagerEmpresas) saveNewData:[argument capture] withDeviceId:[argument capture] withParameters:[argument capture] withContext:nil];
    assertThat([[argument allValues] objectAtIndex:0], is(newEmpresasArray));
    assertThat([[argument allValues] objectAtIndex:2], is(newEmpresasParams));
    
    // verificando o post
    [verifyCount(_syncManagerRegistros, never()) postEvent:anything() withBus:anything()];
    [MKTVerify(_syncManagerEmpresas) postEvent:anything() withBus:anything()];
    
    // verificando o timestamp
    [MKTVerify(_syncConfig) setTimestamps:@"777"];
    
    // get data realizado
    assertThatBool(completed, isTrue());
}

/**
 testSendDataToServerSingle
 */
- (void)testSendDataToServerSingle
{
    [given([_syncManagerRegistros shouldSendSingleObject]) willReturnBool:YES];
    
    NSString *jsonFile = @"/Users/rodrigosuhr/Dev/ios-syncing/Syncing\ Tests/send-data-response-first.json";
    NSString *json = [[NSString alloc] initWithContentsOfFile:jsonFile encoding:NSUTF8StringEncoding error:nil];
    NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSDictionary *jsonData1 = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    
    jsonFile = @"/Users/rodrigosuhr/Dev/ios-syncing/Syncing\ Tests/send-data-response-second.json";
    json = [[NSString alloc] initWithContentsOfFile:jsonFile encoding:NSUTF8StringEncoding error:nil];
    data = [json dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSDictionary *jsonData2 = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    
    jsonFile = @"/Users/rodrigosuhr/Dev/ios-syncing/Syncing\ Tests/send-data-response-third.json";
    json = [[NSString alloc] initWithContentsOfFile:jsonFile encoding:NSUTF8StringEncoding error:nil];
    data = [json dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSDictionary *jsonData3 = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    
    // nos posts subsequents, diferentes respostas sao devolvidas pelo servidor
    [[[given([_serverComm post:[_syncConfig getSendDataUrl] withData:anything() withFiles:anything()]) willReturn:jsonData1] willReturn:jsonData2] willReturn:jsonData3];
    
    // apos enviar todos os dados, o syncManagerRegistros avisa que nao possui mais dados
    [[[[given([_syncManagerRegistros hasModifiedDataWithContext:nil]) willReturnBool:YES] willReturnBool:YES] willReturnBool:YES] willReturnBool:YES];
    BOOL completed = [_dataSyncHelper sendDataToServer:nil];
    
    jsonFile = @"/Users/rodrigosuhr/Dev/ios-syncing/Syncing\ Tests/send-data-request.json";
    json = [[NSString alloc] initWithContentsOfFile:jsonFile encoding:NSUTF8StringEncoding error:nil];
    data = [json dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSDictionary *sendRequestJSON = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    
    MKTArgumentCaptor *argument = [[MKTArgumentCaptor alloc] init];
    [verifyCount(_serverComm, times(3)) post:[argument capture] withData:[argument capture] withFiles:[argument capture]];
    NSArray *args = [argument allValues];
    NSArray *capturedUrls = [args subarrayWithRange:NSMakeRange(0,3)];
    NSArray *capturedData = [args subarrayWithRange:NSMakeRange(3,3)];
    NSArray *capturedFiles = [args subarrayWithRange:NSMakeRange(6,3)];
    
    // primeiro post - registro 1
    jsonFile = @"/Users/rodrigosuhr/Dev/ios-syncing/Syncing\ Tests/send-data-request-first.json";
    json = [[NSString alloc] initWithContentsOfFile:jsonFile encoding:NSUTF8StringEncoding error:nil];
    data = [json dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSDictionary *firstRequestJSON = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    assertThat([capturedUrls objectAtIndex:0], is(@"http://127.0.0.1:8000/api/send-data/"));
    assertThat([capturedData objectAtIndex:0], is(firstRequestJSON));
    assertThat([capturedFiles objectAtIndex:0], is([_modifiedFiles objectAtIndex:0]));
    
    // segundo post - registro 2
    jsonFile = @"/Users/rodrigosuhr/Dev/ios-syncing/Syncing\ Tests/send-data-request-second.json";
    json = [[NSString alloc] initWithContentsOfFile:jsonFile encoding:NSUTF8StringEncoding error:nil];
    data = [json dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSDictionary *secondRequestJSON = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    
    assertThat([capturedUrls objectAtIndex:1], is(@"http://127.0.0.1:8000/api/send-data/"));
    assertThat([capturedData objectAtIndex:1], is(secondRequestJSON));
    assertThat([capturedFiles objectAtIndex:1], is([_modifiedFiles subarrayWithRange:NSMakeRange(1, [_modifiedFiles count]-1)]));
    
    // terceiro post - registro 3
    jsonFile = @"/Users/rodrigosuhr/Dev/ios-syncing/Syncing\ Tests/send-data-request-third.json";
    json = [[NSString alloc] initWithContentsOfFile:jsonFile encoding:NSUTF8StringEncoding error:nil];
    data = [json dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSDictionary *thirdRequestJSON = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    assertThat([capturedUrls objectAtIndex:2], is(@"http://127.0.0.1:8000/api/send-data/"));
    assertThat([capturedData objectAtIndex:2], is(thirdRequestJSON));
    assertThat([capturedFiles objectAtIndex:2], instanceOf([NSArray class]));
    
    // verificando se os dados foram atualizados
    // registros
    argument = [[MKTArgumentCaptor alloc] init];
    [verifyCount(_syncManagerRegistros, times(2)) processSendResponse:[argument capture] withContext:nil];
    assertThat([[argument allValues] objectAtIndex:0], is([jsonData1 objectForKey:@"registros_id"]));
    assertThat([[argument allValues] objectAtIndex:1], is([jsonData2 objectForKey:@"registros_id"]));
    
    NSMutableDictionary *empresasObj = [jsonData2 objectForKey:@"empresas"];
    NSArray *empresasArray = [empresasObj objectForKey:@"data"];
    NSMutableDictionary *empresasParams = [[NSMutableDictionary alloc] initWithDictionary:empresasObj];
    [empresasParams removeObjectForKey:@"data"];
    
    // empresas
    argument = [[MKTArgumentCaptor alloc] init];
    [MKTVerify(_syncManagerEmpresas) processSendResponse:[argument capture] withContext:nil];
    [verifyCount(_syncManagerEmpresas, times(1)) saveNewData:empresasArray withDeviceId:anything() withParameters:empresasParams withContext:anything()];
    
    assertThat([[argument allValues] objectAtIndex:0], is([jsonData3 objectForKey:@"empresas_id"]));

    // envio realizado
    assertThatBool(completed, isTrue());
}

/**
 testSendDataToServerFail
 */
- (void)testSendDataToServerFail
{
    // thread interrompido
    ThreadChecker *threadChecker = mock([ThreadChecker class]);
    [given([threadChecker isValidThreadId:anything()]) willReturnBool:NO];

    //_dataSyncHelper.threadChecker = threadChecker;
    
    BOOL completed = [_dataSyncHelper sendDataToServer:nil];
    
    // assegurando que o banco de dados nao fez commit
    //[verifyCount(_database, never()) saveTransaction];
    
    // assegurando que o timestamp nao foi salvo
    [MKTVerifyCount(_syncConfig, never()) setTimestamps:anything()];
    
    // get data naor ealizado
    assertThatBool(completed, isFalse());
}

/**
 testEvents
 */
- (void)testEvents
{
    // get finished
    [_dataSyncHelper postGetFinishedEvent];
    MKTArgumentCaptor *argument = [[MKTArgumentCaptor alloc] init];
    [verifyCount(_bus, times(1)) post:[argument capture] withNotificationName:anything()];
    assertThat([[argument allValues] objectAtIndex:0], instanceOf([GetFinishedEvent class]));
    
    // send finished
    [_dataSyncHelper postSendFinishedEvent];
    argument = [[MKTArgumentCaptor alloc] init];
    [verifyCount(_bus, times(2)) post:[argument capture] withNotificationName:anything()];
    assertThat([[argument allValues] objectAtIndex:1], instanceOf([SendFinishedEvent class]));
    
    // sync finished
    [_dataSyncHelper postSyncFinishedEvent];
    argument = [[MKTArgumentCaptor alloc] init];
    [verifyCount(_bus, times(3)) post:[argument capture] withNotificationName:anything()];
    assertThat([[argument allValues] objectAtIndex:2], instanceOf([SyncFinishedEvent class]));
}

@end
