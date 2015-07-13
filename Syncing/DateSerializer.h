//
//  DateSerializer.h
//  Syncing
//
//  Created by Rodrigo Suhr on 7/7/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "FieldSerializer.h"
#import "Annotations.h"

@interface DateSerializer : FieldSerializer

- (instancetype)initWithAttribute:(NSAttributeDescription *)attribute
                       withObject:(NSManagedObject *)object
                         withJSON:(NSDictionary *)jsonObject
                   withAnnotation:(JSON *)annotation;
- (NSString *)format:(NSDate *)date;
- (NSDate *)parse:(NSObject *)value;

@end
