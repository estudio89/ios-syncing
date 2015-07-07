//
//  DateSerializer.m
//  Syncing
//
//  Created by Rodrigo Suhr on 7/7/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "DateSerializer.h"
#import <ISO8601/ISO8601.h>

@implementation DateSerializer

- (instancetype)initWithAttribute:(NSAttributeDescription *)attribute
                       withObject:(NSManagedObject *)object
                         withJSON:(NSDictionary *)jsonObject
                   withAnnotation:(NSDictionary *)annotation;
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
    
    return [date ISO8601String];
}

- (NSDate *)parse:(NSObject *)value
{
    if (value == nil)
    {
        return [NSDate date];
    }
    
    return [NSDate dateWithISO8601String:(NSString *)value];
}

@end
