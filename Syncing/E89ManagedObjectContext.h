//
//  E89ManagedObjectContext.h
//  Syncing
//
//  Created by Rodrigo Suhr on 3/23/16.
//  Copyright © 2016 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface E89ManagedObjectContext : NSManagedObjectContext

- (BOOL)safeSave:(NSError **)error;

@end
