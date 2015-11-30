//
//  FieldSerializer.h
//  Syncing
//
//  Created by Rodrigo Suhr on 7/7/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Annotations.h"

@interface FieldSerializer : NSObject

- (instancetype)initWithAttribute:(NSString *)attribute
                       withObject:(NSManagedObject *)object
                         withJSON:(NSMutableDictionary *)jsonObject
                   withAnnotation:(JSON *)annotation;
- (NSString *)getAttributename;
- (BOOL)isIgnored;
- (BOOL)isWritable;
- (BOOL)isReadable;
- (BOOL)updateJSON;
- (BOOL)updateField;
- (BOOL)allowOverwrite;
- (NSObject *)parseValue:(NSObject *)value;
- (NSObject *)formatValue:(NSObject *)value;

@end
