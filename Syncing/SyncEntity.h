//
//  SyncEntity.h
//  Syncing
//
//  Created by Rodrigo Suhr on 7/9/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface SyncEntity : NSManagedObject

@property (nonatomic, retain) NSNumber * idServer;
@property (nonatomic, retain) NSNumber * modified;
@property (nonatomic, retain) NSNumber * isNew;

+ (SyncEntity *)getOldestFromEntity:(NSString *)entity withContext:(NSManagedObjectContext *)context;
+ (SyncEntity *)getOldestFromEntity:(NSString *)entity withPredicate:(NSPredicate *)predicate withContext:(NSManagedObjectContext *)context;
+ (SyncEntity *)getOldestFromEntity:(NSString *)entity withKey:(NSString *)key withContext:(NSManagedObjectContext *)context;
+ (SyncEntity *)getOldestFromEntity:(NSString *)entity withPredicate:(NSPredicate *)predicate withKey:(NSString *)key withContext:(NSManagedObjectContext *)context;
+ (NSUInteger)countFromEntity:(NSString *)entity withContext:(NSManagedObjectContext *)context;
+ (NSUInteger)countFromEntity:(NSString *)entity withPredicate:(NSPredicate *)predicate withContext:(NSManagedObjectContext *)context;
- (BOOL)equals:(NSManagedObject *)object withContext:(NSManagedObjectContext *)context;
+ (NSInteger)numberOfIsNewFromEntity:(NSString *)entity withContext:(NSManagedObjectContext *)context;
+ (void)makeOldForEntity:(NSString *)entity withContext:(NSManagedObjectContext *)context;
- (void)saveWithContext:(NSManagedObjectContext *)context;
- (NSDate *)getPubDate;

@end
