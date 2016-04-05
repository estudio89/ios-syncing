//
//  DatabaseProvider.h
//  Syncing
//
//  Created by Rodrigo Suhr on 2/27/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "E89ManagedObjectContext.h"

@interface DatabaseProvider : NSObject

+ (void)clearAllCoreDataEntitiesWithContext:(E89ManagedObjectContext *)context;

@end
