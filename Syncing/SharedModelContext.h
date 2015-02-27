//
//  SharedModelContext.h
//  Syncing
//
//  Created by Rodrigo Suhr on 2/27/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface SharedModelContext : NSObject

@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
+ (SharedModelContext *)sharedModelContext;
- (void)setSharedModelContext:(NSManagedObjectContext *)context;
- (NSManagedObjectContext *)getSharedModelContext;

@end
