//
//  SyncEvent.h
//  Syncing
//
//  Created by Rodrigo Suhr on 6/21/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface SyncEvent : NSObject

@property NSArray *objectsIDs;
- (instancetype)initWithObjects:(NSArray *)objects;
- (NSArray *)getObjectsWithContext:(NSManagedObjectContext *)context;

@end
