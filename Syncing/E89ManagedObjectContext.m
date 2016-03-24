//
//  E89ManagedObjectContext.m
//  Syncing
//
//  Created by Rodrigo Suhr on 3/23/16.
//  Copyright © 2016 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "E89ManagedObjectContext.h"

@implementation E89ManagedObjectContext

- (BOOL)save:(NSError * _Nullable __autoreleasing *)error {
    return YES;
}

- (BOOL)safeSave:(NSError * _Nullable __autoreleasing *)error {
    return [super save:error];
}

@end
