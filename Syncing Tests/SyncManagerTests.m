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
    //OCMStub([[spyTestSyncManager annotations] nestedManagerForAttribute:[OCMArg any]]).andReturn(_childSyncManager);
    OCMStub([[spyTestSyncManager childrenAttributes] objectForKey:@"children"]).andReturn(_childSyncManager);
    
    // 2) my finditem should return nil
    OCMStub([spyTestSyncManager findItem:[OCMArg any] withIdClient:[OCMArg any] withDeviceId:[OCMArg any] withItemDeviceId:[OCMArg any] withIgnoreDeviceId:[OCMArg any] withObject:[OCMArg any] withContext:[OCMArg any]]).andReturn(nil);
    
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
}

@end
