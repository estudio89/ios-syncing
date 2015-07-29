//
//  DateSerializer.m
//  Syncing
//
//  Created by Rodrigo Suhr on 7/7/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "DateSerializer.h"
#import "SerializationUtil.h"

@implementation DateSerializer

- (instancetype)initWithAttribute:(NSString *)attribute
                       withObject:(NSManagedObject *)object
                         withJSON:(NSMutableDictionary *)jsonObject
                   withAnnotation:(JSON *)annotation;
{
    self = [super initWithAttribute:attribute
                         withObject:object
                           withJSON:jsonObject
                     withAnnotation:annotation];
    
    return self;
}

- (NSObject *)formatValue:(NSObject *)value
{
    if (value == nil)
    {
        return [NSNull null];
    }
    
    return [SerializationUtil formatServerDate:(NSDate *)value];
}

- (NSObject *)parseValue:(NSObject *)value
{
    if (value == nil || [value isKindOfClass:[NSNull class]])
    {
        return [NSDate date];
    }
    
    return [SerializationUtil parseServerDate:[NSString stringWithFormat:@"%@", value]];
}

@end
