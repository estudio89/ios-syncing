//
//  TestSyncEntity.h
//  Syncing
//
//  Created by Rodrigo Suhr on 7/14/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "SyncEntity.h"
#import "ParentSyncEntity.h"

@interface TestSyncEntity : SyncEntity

@property (nonatomic, retain) NSDate *pubDate;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) ParentSyncEntity *parent;
@property (nonatomic, retain) NSSet *children;
@property (nonatomic, retain) NSSet *otherChildren;

@end
