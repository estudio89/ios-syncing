//
//  JSONSerializer.h
//  Syncing
//
//  Created by Rodrigo Suhr on 7/7/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "FieldSerializer.h"
#import "Annotations.h"

@interface JSONSerializer : NSObject

- (instancetype)initWithModelClass:(Class)modelClass withAnnotations:(Annotations *)annotations;
- (NSArray *)toJSON:(NSManagedObject *)object withJSON:(NSMutableDictionary *)jsonObject;
- (NSArray *)updateFromJSON:(NSMutableDictionary *)jsonObject withObject:(NSManagedObject *)object;
- (FieldSerializer *)getFieldSerializer:(NSString *)attribute withAttributeType:(Class)type withObject:(NSManagedObject *)object withJSON:(NSMutableDictionary *)jsonObject;

@end
