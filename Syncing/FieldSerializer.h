//
//  FieldSerializer.h
//  Syncing
//
//  Created by Rodrigo Suhr on 7/7/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface FieldSerializer : NSObject

- (instancetype)initWithAttribute:(NSAttributeDescription *)attribute
                       withObject:(NSManagedObject *)object
                         withJSON:(NSDictionary *)jsonObject
                   withAnnotation:(NSDictionary *)annotation;
- (NSString *)getAttributename;
- (BOOL)isIgnored;
- (BOOL)isWritable;
- (BOOL)isReadable;
- (BOOL)updateJSON;
- (BOOL)updateField;

@end
