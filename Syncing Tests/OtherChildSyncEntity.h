//
//  OtherChildSyncEntity.h
//  Syncing
//
//  Created by Rodrigo Suhr on 7/15/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "SyncEntity.h"

@class TestSyncEntity;

@interface OtherChildSyncEntity : SyncEntity

@property (nonatomic, retain) NSString * other;
@property (nonatomic, retain) TestSyncEntity *testSync;

@end
