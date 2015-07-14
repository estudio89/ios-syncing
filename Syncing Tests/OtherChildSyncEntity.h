//
//  OtherChildSyncEntity.h
//  Syncing
//
//  Created by Rodrigo Suhr on 7/14/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "SyncEntity.h"
#import "TestSyncEntity.h"

@interface OtherChildSyncEntity : SyncEntity

@property (nonatomic, retain) NSString *other;
@property (nonatomic, retain) TestSyncEntity *testSync;

@end
