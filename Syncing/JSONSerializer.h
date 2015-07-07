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

@interface JSONSerializer : NSObject

- (instancetype)initWithModelClass:(Class)modelClass withAnnotation:(NSDictionary *)annotation withContext:(NSManagedObjectContext *)context;
- (NSArray *)toJSON:(NSManagedObject *)object withJSON:(NSDictionary *)jsonObject;
- (NSArray *)updateFromJSON:(NSDictionary *)jsonObject withObject:(NSManagedObject *)object;
- (FieldSerializer *)getFieldSerializer:(NSAttributeDescription *)attribute withObject:(NSManagedObject *)object withJSON:(NSDictionary *)jsonObject;

@end
