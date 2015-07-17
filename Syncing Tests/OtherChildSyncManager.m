//
//  OtherChildSyncManager.m
//  Syncing
//
//  Created by Rodrigo Suhr on 7/14/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "OtherChildSyncManager.h"
#import "Annotations.h"

@implementation OtherChildSyncManager

- (Annotations *)getAnnotationsWithAbstractAttributes:(NSDictionary *)abstractAttributes
{
    NSMutableDictionary *fields = [[NSMutableDictionary alloc] initWithDictionary:abstractAttributes];
    [fields setObject:[[NSDictionary alloc] init] forKey:@"other"];
    [fields setObject:[[NSDictionary alloc] init] forKey:@"testSync"];
    
    NSDictionary *annotationDict = @{@"entityName":@"OtherChildSyncEntity",
                                     @"fields":fields};
    
    Annotations *annotations = [[Annotations alloc] initWithAnnotation:annotationDict];
    
    return annotations;
}

- (NSString *)getIdentifier
{
    return nil;
}

- (NSString *)getResponseIdentifier
{
    return nil;
}

- (BOOL)shouldSendSingleObject
{
    return NO;
}

- (NSMutableArray *)getModifiedFilesWithContext:(NSManagedObjectContext *)context
{
    return nil;
}

- (NSMutableArray *)getModifiedFilesForObject:(NSDictionary *)object withContext:(NSManagedObjectContext *)context
{
    return nil;
}

- (void)processSendResponse:(NSArray *)jsonResponse withContext:(NSManagedObjectContext *)context
{
}

- (void)postEvent:(NSArray *)objects withBus:(AsyncBus *)bus
{
}

@end
