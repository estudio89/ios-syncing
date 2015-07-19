//
//  SyncManagerTests.m
//  Syncing
//
//  Created by Rodrigo Suhr on 7/14/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>
#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>
#import "TestSyncManager.h"
#import "ChildSyncManager.h"
#import "TestSyncEntity.h"
#include "ParentSyncEntity.h"
#include "OtherChildSyncEntity.h"
#import "CoreDataHelper.h"
#import "JSONSerializer.h"
#import "TestDataUtil.h"

@interface SyncManagerTests : XCTestCase

@property (nonatomic) TestSyncManager *testSyncManager;
@property (nonatomic) ChildSyncManager *childSyncManager;
@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation SyncManagerTests

- (void)setUp {
    [super setUp];
    
    _context = [CoreDataHelper context];
    
    _testSyncManager = [[TestSyncManager alloc] init];
    //_childSyncManager = mock([ChildSyncManager class]);
    _childSyncManager = OCMClassMock([ChildSyncManager class]);
    
    //-----mock
    //getModifiedDataWithContext
    //hasModifiedDataWithContext
    //processSendResponse
    //getOldestFromContext
    //findItem
    //findParent
    //newObjectForEntity
    //entityDescriptionForName
    //performSaveWithContext
    //deleteAllWithContext
    //deleteAllChildrenFromEntity
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testVerifyFields
{
    assertThat(_testSyncManager.dateAttribute, is(@"pubDate"));
    assertThatInt([[_testSyncManager.parentAttributes allKeys] count], equalToInt(1));
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF IN %@", [_testSyncManager.parentAttributes allValues]];
    assertThatBool([predicate evaluateWithObject:@"parent_id"], isTrue());
    assertThatInt([[_testSyncManager.childrenAttributes allKeys] count], equalToInt(2));
}

- (void)testGetDate
{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"TestSyncEntity" inManagedObjectContext:_context];
    TestSyncEntity *item = [[TestSyncEntity alloc] initWithEntity:entityDesc insertIntoManagedObjectContext:nil];
    item.pubDate = [NSDate date];
    assertThat([_testSyncManager getDateForObject:item], is(item.pubDate));
}

- (void)testSerializeObject
{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"ParentSyncEntity" inManagedObjectContext:_context];
    ParentSyncEntity *parent = [[ParentSyncEntity alloc] initWithEntity:entityDesc insertIntoManagedObjectContext:nil];
    parent.idServer = [NSNumber numberWithInt:10];
    
    entityDesc = [NSEntityDescription entityForName:@"TestSyncEntity" inManagedObjectContext:_context];
    TestSyncEntity *item = [[TestSyncEntity alloc] initWithEntity:entityDesc insertIntoManagedObjectContext:nil];
    item.pubDate = [NSDate date];
    item.name = @"Rodrigo";
    item.idServer = [NSNumber numberWithInt:5];
    item.parent = parent;
    
    entityDesc = [NSEntityDescription entityForName:@"OtherChildSyncEntity" inManagedObjectContext:_context];
    OtherChildSyncEntity *otherChildren = [[OtherChildSyncEntity alloc] initWithEntity:entityDesc insertIntoManagedObjectContext:nil];
    [item addOtherChildrenObject:otherChildren];
    
    [parent addTestSyncObject:item];
    
    NSDictionary *expectedJsonObject = @{@"id":@5,
                                         @"idClient":[item.objectID.URIRepresentation absoluteString],
                                         @"name":@"Rodrigo",
                                         @"other_children_objs":[NSArray arrayWithObject:@{@"idClient":[otherChildren.objectID.URIRepresentation absoluteString], @"other":@"<null>", @"testSync":@"<null>"}],
                                         @"parent_id":@10,
                                         @"pubDate":item.pubDate};
    
    NSDictionary *jsonObject = [_testSyncManager serializeObject:item withContext:_context];
    
    NSString *json = [NSString stringWithFormat:@"%@", jsonObject];
    NSString *expected = [NSString stringWithFormat:@"%@", expectedJsonObject];
    
    assertThat(json, is(expected));
}

- (void)testSaveNewObject
{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"ParentSyncEntity" inManagedObjectContext:_context];
    ParentSyncEntity *parent = [[ParentSyncEntity alloc] initWithEntity:entityDesc insertIntoManagedObjectContext:_context];

    id spyTestSyncManager = OCMPartialMock(_testSyncManager);
    // Checking if children objects were not deleted before being saved (they should not be deleted as this is a new item)
    [[spyTestSyncManager reject] deleteAllChildrenFromEntity:[OCMArg any] withParentAttribute:[OCMArg any] withParentId:[OCMArg any] withContext:_context];

    // 1) my nested sync manager should return childSyncManager
    OCMStub([spyTestSyncManager syncManagerForNestedManager:[OCMArg any]]).andReturn(_childSyncManager);
    
    // 2) my finditem should return nil
    OCMStub([spyTestSyncManager findItem:[OCMArg any] withIdClient:[OCMArg any] withDeviceId:[OCMArg any] withItemDeviceId:[OCMArg any] withObject:[OCMArg any] withContext:_context]).andReturn(nil);
    
    // 3) my findparent should return parent
    OCMStub([spyTestSyncManager findParent:[OCMArg any] withParentId:[OCMArg any] withContext:_context]).andReturn(parent);
    
    // 4) my performsave should do nothing
    OCMStub([spyTestSyncManager performSaveWithContext:[OCMArg any]]).andDo(nil);
    
    // 5) my deleteAllChildren should do nothing
    OCMStub([spyTestSyncManager deleteAllChildrenFromEntity:[OCMArg any] withParentAttribute:[OCMArg any] withParentId:[OCMArg any] withContext:_context]).andDo(nil);
    
    // 6) my childrenSyncManager savenewdata should return nil
    OCMStub([_childSyncManager saveNewData:[OCMArg any] withDeviceId:[OCMArg any] withParameters:[OCMArg any] withContext:_context]).andReturn(nil);
    
    NSDate *now = [NSDate date];
    NSDate *yesterday = [now dateByAddingTimeInterval:-86400.0];
    entityDesc = [NSEntityDescription entityForName:@"TestSyncEntity" inManagedObjectContext:_context];
    TestSyncEntity *oldestItem = [[TestSyncEntity alloc] initWithEntity:entityDesc insertIntoManagedObjectContext:_context];
    oldestItem.pubDate = yesterday;
    [spyTestSyncManager setOldestInCache:oldestItem];

    NSDictionary *jsonObject = @{@"id":@5,
                                 @"name":@"Rodrigo",
                                 @"children_objs":[[NSArray alloc] init],
                                 @"children_pagination":@{@"more":@YES},
                                 @"other_children_objs":[[NSArray alloc] init],
                                 @"parent_id":@10,
                                 @"pubDate":now};
    
    TestSyncEntity *item = [spyTestSyncManager saveObject:jsonObject withDeviceId:@"deviceId" withContext:_context];
    
    assertThat(item.idServer, is([NSNumber numberWithInt:5]));
    assertThat(item.pubDate, is(now));
    assertThat(item.name, is(@"Rodrigo"));
    assertThat(item.parent, is(parent));
    assertThatBool(item.isNew, isTrue());
    
    OCMVerify(([_childSyncManager saveNewData:[OCMArg any] withDeviceId:[OCMArg any] withParameters:[OCMArg checkWithBlock:^BOOL(id value) {
        NSString *arg = [NSString stringWithFormat:@"%@", value];
        NSString *check = [NSString stringWithFormat:@"%@", @{@"more":@YES}];
        if ([arg isEqualToString:check]) {
            return YES;
        } else {
            return NO;
        }
    }] withContext:_context]));
    OCMVerify([_childSyncManager postEvent:[OCMArg any] withBus:[OCMArg any]]);
    
    [spyTestSyncManager verify];
}

- (void)testSaveOldObject
{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"ParentSyncEntity" inManagedObjectContext:_context];
    ParentSyncEntity *parent = [[ParentSyncEntity alloc] initWithEntity:entityDesc insertIntoManagedObjectContext:_context];
    
    entityDesc = [NSEntityDescription entityForName:@"TestSyncEntity" inManagedObjectContext:_context];
    TestSyncEntity *oldItem = [[TestSyncEntity alloc] initWithEntity:entityDesc insertIntoManagedObjectContext:_context];
    
    id spyTestSyncManager = OCMPartialMock(_testSyncManager);
    
    // 1) my nested sync manager should return childSyncManager
    OCMStub([spyTestSyncManager syncManagerForNestedManager:[OCMArg any]]).andReturn(_childSyncManager);
    
    // 2) my finditem should return oldItem
    OCMStub([spyTestSyncManager findItem:[OCMArg any] withIdClient:[OCMArg any] withDeviceId:[OCMArg any] withItemDeviceId:[OCMArg any] withObject:[OCMArg any] withContext:_context]).andReturn(oldItem);
    
    // 3) my findparent should return parent
    OCMStub([spyTestSyncManager findParent:[OCMArg any] withParentId:[OCMArg any] withContext:_context]).andReturn(parent);
    
    // 4) my performsave should do nothing
    OCMStub([spyTestSyncManager performSaveWithContext:[OCMArg any]]).andDo(nil);
    
    // 5) my deleteAllChildren should do nothing
    OCMStub([spyTestSyncManager deleteAllChildrenFromEntity:[OCMArg any] withParentAttribute:[OCMArg any] withParentId:[OCMArg any] withContext:_context]).andDo(nil);
    
    // 6) my childrenSyncManager savenewdata should return nil
    OCMStub([_childSyncManager saveNewData:[OCMArg any] withDeviceId:[OCMArg any] withParameters:[OCMArg any] withContext:_context]).andReturn(nil);
    
    NSDate *now = [NSDate date];
    NSDictionary *jsonObject = @{@"id":@5,
                                 @"name":@"Rodrigo",
                                 @"idClient":[oldItem.objectID.URIRepresentation absoluteString],
                                 @"children_objs":[[NSArray alloc] init],
                                 @"children_pagination":@{@"more":@YES},
                                 @"other_children_objs":[[NSArray alloc] init],
                                 @"parent_id":@10,
                                 @"pubDate":now};
    
    TestSyncEntity *item = [spyTestSyncManager saveObject:jsonObject withDeviceId:@"deviceId" withContext:_context];
    
    assertThat(item.idServer, is([NSNumber numberWithInt:5]));
    assertThat(item.pubDate, is(now));
    assertThat(item.name, is(@"Rodrigo"));
    assertThat(item.parent, is(parent));
    assertThatBool(item.isNew, isFalse());
    
    OCMVerify([spyTestSyncManager deleteAllChildrenFromEntity:[OCMArg any] withParentAttribute:[OCMArg any] withParentId:[OCMArg any] withContext:_context]);
    OCMVerify(([_childSyncManager saveNewData:[OCMArg any] withDeviceId:[OCMArg any] withParameters:[OCMArg any] withContext:_context]));
    OCMVerify([_childSyncManager postEvent:[OCMArg any] withBus:[OCMArg any]]);
}

- (void)testSaveNewOldObject
{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"ParentSyncEntity" inManagedObjectContext:_context];
    ParentSyncEntity *parent = [[ParentSyncEntity alloc] initWithEntity:entityDesc insertIntoManagedObjectContext:_context];
    
    id spyTestSyncManager = OCMPartialMock(_testSyncManager);
    
    // 1) my nested sync manager should return childSyncManager
    OCMStub([spyTestSyncManager syncManagerForNestedManager:[OCMArg any]]).andReturn(_childSyncManager);
    
    // 2) my finditem should return oldItem
    OCMStub([spyTestSyncManager findItem:[OCMArg any] withIdClient:[OCMArg any] withDeviceId:[OCMArg any] withItemDeviceId:[OCMArg any] withObject:[OCMArg any] withContext:_context]).andReturn(nil);
    
    // 3) my findparent should return parent
    OCMStub([spyTestSyncManager findParent:[OCMArg any] withParentId:[OCMArg any] withContext:_context]).andReturn(parent);
    
    // 4) my performsave should do nothing
    OCMStub([spyTestSyncManager performSaveWithContext:[OCMArg any]]).andDo(nil);
    
    // 5) my childrenSyncManager savenewdata should return nil
    OCMStub([_childSyncManager saveNewData:[OCMArg any] withDeviceId:[OCMArg any] withParameters:[OCMArg any] withContext:_context]).andReturn(nil);
    
    NSDate *now = [NSDate date];
    
    entityDesc = [NSEntityDescription entityForName:@"TestSyncEntity" inManagedObjectContext:_context];
    TestSyncEntity *oldItem = [[TestSyncEntity alloc] initWithEntity:entityDesc insertIntoManagedObjectContext:_context];
    oldItem.pubDate = now;
    [spyTestSyncManager setOldestInCache:oldItem];
    
    NSDictionary *jsonObject = @{@"id":@5,
                                 @"name":@"Rodrigo",
                                 @"idClient":[oldItem.objectID.URIRepresentation absoluteString],
                                 @"children_objs":[[NSArray alloc] init],
                                 @"children_pagination":@{@"more":@YES},
                                 @"other_children_objs":[[NSArray alloc] init],
                                 @"parent_id":@10,
                                 @"pubDate":now};
    
    TestSyncEntity *item = [spyTestSyncManager saveObject:jsonObject withDeviceId:@"deviceId" withContext:_context];
    
    assertThat(item.idServer, is([NSNumber numberWithInt:5]));
    assertThat(item.pubDate, is(now));
    assertThat(item.name, is(@"Rodrigo"));
    assertThat(item.parent, is(parent));
    assertThatBool(item.isNew, isFalse());
    
    OCMVerify(([_childSyncManager saveNewData:[OCMArg any] withDeviceId:[OCMArg any] withParameters:[OCMArg any] withContext:_context]));
    OCMVerify([_childSyncManager postEvent:[OCMArg any] withBus:[OCMArg any]]);
}

- (void)testSaveNewDataPaginationMore
{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"TestSyncEntity" inManagedObjectContext:_context];
    TestSyncEntity *item = [[TestSyncEntity alloc] initWithEntity:entityDesc insertIntoManagedObjectContext:_context];
    
    NSString *jsonFile = @"/Users/rodrigosuhr/Dev/ios-syncing/Syncing\ Tests/save-new-data-more.json";
    NSString *jsonStr = [[NSString alloc] initWithContentsOfFile:jsonFile encoding:NSUTF8StringEncoding error:nil];
    NSData *dataJson = [jsonStr dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSArray *newObjects = [NSJSONSerialization JSONObjectWithData:dataJson options:kNilOptions error:nil];

    NSDictionary *parameters = @{@"more":@YES,
                                 @"paginationIdentifier":@1};
    
    id spyDeletedSyncManager = OCMClassMock([TestSyncManager class]);
    id spyTestSyncManager = OCMPartialMock(_testSyncManager);
    
    OCMStub([spyTestSyncManager saveBooleanPref:[OCMArg any] withValue:[OCMArg any]]).andDo(nil);
    OCMStub([spyTestSyncManager getOldestFromContext:_context]).andReturn(nil);
    OCMStub([spyTestSyncManager saveObject:[OCMArg any] withDeviceId:[OCMArg any] withContext:_context]).andReturn(item);
    OCMStub([spyTestSyncManager getSyncManagerDeleted]).andReturn(spyDeletedSyncManager);
    [[spyTestSyncManager reject] deleteAllWithContext:_context];
    [[spyTestSyncManager expect] saveObject:[OCMArg any] withDeviceId:[OCMArg any] withContext:_context];
    [[spyTestSyncManager expect] saveObject:[OCMArg any] withDeviceId:[OCMArg any] withContext:_context];
    [[spyTestSyncManager reject] postEvent:[OCMArg any] withBus:[OCMArg any]];
    
    NSMutableArray *savedbjects = [spyTestSyncManager saveNewData:newObjects withDeviceId:@"" withParameters:parameters withContext:_context];
    
    OCMVerify([spyTestSyncManager saveBooleanPref:@"more.1" withValue:YES]);
    assertThatInt([savedbjects count], equalToInt(2));
    
    [spyTestSyncManager verify];
}

- (void)testSaveNewDataSyncDeleteCache
{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"TestSyncEntity" inManagedObjectContext:_context];
    TestSyncEntity *item = [[TestSyncEntity alloc] initWithEntity:entityDesc insertIntoManagedObjectContext:_context];
    
    NSDate *now = [NSDate date];
    TestSyncEntity *oldItem = [[TestSyncEntity alloc] initWithEntity:entityDesc insertIntoManagedObjectContext:_context];
    oldItem.pubDate = [now dateByAddingTimeInterval:-86400.0];
    
    NSString *jsonFile = @"/Users/rodrigosuhr/Dev/ios-syncing/Syncing\ Tests/save-new-data-more.json";
    NSString *jsonStr = [[NSString alloc] initWithContentsOfFile:jsonFile encoding:NSUTF8StringEncoding error:nil];
    NSData *dataJson = [jsonStr dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSArray *newObjects = [NSJSONSerialization JSONObjectWithData:dataJson options:kNilOptions error:nil];
    
    NSDictionary *parameters = @{@"deleteCache":@YES,
                                 @"paginationIdentifier":@1};
    
    id spyDeletedSyncManager = OCMClassMock([TestSyncManager class]);
    id spyTestSyncManager = OCMPartialMock(_testSyncManager);
    
    OCMStub([spyTestSyncManager saveBooleanPref:[OCMArg any] withValue:[OCMArg any]]).andDo(nil);
    OCMStub([spyTestSyncManager getOldestFromContext:_context]).andReturn(oldItem);
    OCMStub([spyTestSyncManager deleteAllWithContext:_context]).andDo(nil);
    OCMStub([spyTestSyncManager saveObject:[OCMArg any] withDeviceId:[OCMArg any] withContext:_context]).andReturn(item);
    OCMStub([spyTestSyncManager getSyncManagerDeleted]).andReturn(spyDeletedSyncManager);
    
    NSMutableArray *savedbjects = [spyTestSyncManager saveNewData:newObjects withDeviceId:@"" withParameters:parameters withContext:_context];
    
    OCMVerify([spyTestSyncManager saveBooleanPref:@"more.1" withValue:YES]);
    OCMVerify([spyTestSyncManager deleteAllWithContext:_context]);
    OCMVerify([spyTestSyncManager saveObject:[OCMArg any] withDeviceId:[OCMArg any] withContext:_context]);
    OCMVerify([spyTestSyncManager saveObject:[OCMArg any] withDeviceId:[OCMArg any] withContext:_context]);
    assertThatInt([savedbjects count], equalToInt(2));
    OCMVerify([spyTestSyncManager postEvent:[OCMArg any] withBus:[OCMArg any]]);
}

- (void)testSaveNewDataSyncOldObject
{
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"TestSyncEntity" inManagedObjectContext:_context];
    TestSyncEntity *item = [[TestSyncEntity alloc] initWithEntity:entityDesc insertIntoManagedObjectContext:_context];
    
    TestSyncEntity *oldItem = [[TestSyncEntity alloc] initWithEntity:entityDesc insertIntoManagedObjectContext:_context];
    oldItem.pubDate = [NSDate date];
    
    NSString *jsonFile = @"/Users/rodrigosuhr/Dev/ios-syncing/Syncing\ Tests/save-new-data-more.json";
    NSString *jsonStr = [[NSString alloc] initWithContentsOfFile:jsonFile encoding:NSUTF8StringEncoding error:nil];
    NSData *dataJson = [jsonStr dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSArray *newObjects = [NSJSONSerialization JSONObjectWithData:dataJson options:kNilOptions error:nil];
    
    NSDictionary *parameters = @{@"deleteCache":@NO,
                                 @"paginationIdentifier":@1};
    
    id spyDeletedSyncManager = OCMClassMock([TestSyncManager class]);
    id spyTestSyncManager = OCMPartialMock(_testSyncManager);
    
    OCMStub([spyTestSyncManager saveBooleanPref:[OCMArg any] withValue:[OCMArg any]]).andDo(nil);
    OCMStub([spyTestSyncManager getOldestFromContext:_context]).andReturn(oldItem);
    OCMStub([spyTestSyncManager deleteAllWithContext:_context]).andDo(nil);
    OCMStub([spyTestSyncManager saveObject:[OCMArg any] withDeviceId:[OCMArg any] withContext:_context]).andReturn(item);
    OCMStub([spyTestSyncManager getSyncManagerDeleted]).andReturn(spyDeletedSyncManager);
    
    NSMutableArray *savedbjects = [spyTestSyncManager saveNewData:newObjects withDeviceId:@"" withParameters:parameters withContext:_context];
    
    OCMVerify([spyTestSyncManager saveBooleanPref:[OCMArg any] withValue:[OCMArg any]]);
    [[spyTestSyncManager reject] deleteAllWithContext:_context];
    OCMVerify([spyTestSyncManager saveObject:[OCMArg any] withDeviceId:[OCMArg any] withContext:_context]);
    assertThatInt([savedbjects count], equalToInt(1));
    [[spyTestSyncManager reject] postEvent:[OCMArg any] withBus:[OCMArg any]];
    
    [spyTestSyncManager verify];
}

- (void)testProcessSendResponse
{
    NSString *jsonFile = @"/Users/rodrigosuhr/Dev/ios-syncing/Syncing\ Tests/send-response.json";
    NSString *jsonStr = [[NSString alloc] initWithContentsOfFile:jsonFile encoding:NSUTF8StringEncoding error:nil];
    NSData *dataJson = [jsonStr dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSArray *sendResponse = [NSJSONSerialization JSONObjectWithData:dataJson options:kNilOptions error:nil];
    
    id existingItem = OCMClassMock([TestSyncEntity class]);
    id spyTestSyncManager = OCMPartialMock(_testSyncManager);
    
    OCMStub([spyTestSyncManager findItem:[OCMArg any] withIdClient:[OCMArg any] withDeviceId:[OCMArg any] withItemDeviceId:[OCMArg any] withObject:[OCMArg any] withContext:_context]).andReturn(existingItem);
    OCMStub([existingItem save:nil]).andDo(nil);
    
    assertThatBool([existingItem modified], isFalse());
    assertThat([existingItem idServer], is([NSNumber numberWithInt:2]));
    
    OCMVerify([existingItem save:nil]);
}

- (void)testReadOnlySyncManager
{
    
}

@end
