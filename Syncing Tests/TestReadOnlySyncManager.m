//
//  TestReadOnlySyncManager.m
//  Syncing
//
//  Created by Rodrigo Suhr on 7/14/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "TestReadOnlySyncManager.h"

@implementation TestReadOnlySyncManager

- (Annotations *)getAnnotations
{
    return nil;
}

- (NSString *)getIdentifier
{
    return @"test";
}

- (NSDictionary *)serializeObject:(NSObject *)object withContext:(NSManagedObjectContext *)context
{
    return [[NSDictionary alloc] init];
}

@end
