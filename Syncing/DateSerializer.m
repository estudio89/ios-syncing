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

- (NSString *)format:(NSDate *)date
{
    if (date == nil)
    {
        return nil;
    }
    
    return [SerializationUtil formatServerDate:date];
}

- (NSDate *)parse:(NSObject *)value
{
    if (value == nil)
    {
        return [NSDate date];
    }
    
    return [SerializationUtil parseServerDate:(NSString *)value];
}

@end
