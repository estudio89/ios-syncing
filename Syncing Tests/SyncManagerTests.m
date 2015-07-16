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
#import "TestSyncEntity.h"
#include "ParentSyncEntity.h"
#include "OtherChildSyncEntity.h"
#import "CoreDataHelper.h"
#import "JSONSerializer.h"
#import "TestDataUtil.h"

@interface SyncManagerTests : XCTestCase

@property (nonatomic) TestSyncManager *testSyncManager;
@property (nonatomic) NSManagedObjectContext *context;

@end

@implementation SyncManagerTests

- (void)setUp {
    [super setUp];
    
    _context = [CoreDataHelper context];
    
    _testSyncManager = [[TestSyncManager alloc] init];
    
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
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF IN %@", [_testSyncManager.parentAttributes allKeys]];
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
    
    NSDictionary *jsonObject = [_testSyncManager serializeObject:item withContext:_context];
    
    assertThat(jsonObject, is([TestDataUtil annotationsDict]));
}

@end
