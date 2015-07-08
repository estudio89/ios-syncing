//
//  SerializationUtil.m
//  Syncing
//
//  Created by Rodrigo Suhr on 7/7/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "SerializationUtil.h"
#import <ISO8601/ISO8601.h>

@implementation SerializationUtil

+ (NSString *)getAttributeName:(NSAttributeDescription *)attribute withAnnotation:(NSDictionary *)annotation
{
    NSString *name = attribute.name;
    
    if (annotation != nil && [annotation valueForKey:@"name"] && ![[annotation valueForKey:@"name"] isEqualToString:@""])
    {
        name = [annotation valueForKey:@"name"];
    }
    
    return name;
}

+ (NSDate *)parseServerDate:(NSString *)strDate
{
    return [NSDate dateWithISO8601String:strDate];
}

+ (NSString *)formatServerDate:(NSDate *)date
{
    return [date ISO8601String];
}

@end
