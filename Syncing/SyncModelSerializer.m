//
//  SyncModelSerializer.m
//  Syncing
//
//  Created by Rodrigo Suhr on 7/13/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "SyncModelSerializer.h"

@implementation SyncModelSerializer

- (instancetype)initWithModelClass:(Class)modelClass withAnnotations:(Annotations *)annotations
{
    return [super initWithModelClass:modelClass
                     withAnnotations:annotations];
}

- (NSArray *)toJSON:(NSManagedObject *)object withJSON:(NSMutableDictionary *)jsonObject
{
    NSArray *unusedFields = [super toJSON:object withJSON:jsonObject];
    [jsonObject setValue:[object.objectID.URIRepresentation absoluteString] forKey:@"idClient"];
    return unusedFields;
}

@end
