//
//  SyncModelSerializer.h
//  Syncing
//
//  Created by Rodrigo Suhr on 7/13/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSONSerializer.h"

@interface SyncModelSerializer : JSONSerializer

- (instancetype)initWithModelClass:(Class)modelClass withAnnotations:(Annotations *)annotations;
- (NSArray *)toJSON:(NSManagedObject *)object withJSON:(NSMutableDictionary *)jsonObject;

@end
