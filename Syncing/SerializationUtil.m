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

+ (NSString *)getAttributeName:(NSString *)attribute withAnnotation:(JSON *)annotation
{
    NSString *name = attribute;
    
    if (annotation.name != nil && ![annotation.name isEqualToString:@""])
    {
        name = annotation.name;
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
