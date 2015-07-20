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

+ (NSString *)propertyClassNameFor:(objc_property_t)property
{
    const char *type = property_getAttributes(property);
    NSString *typeString = [NSString stringWithUTF8String:type];
    NSArray *attributes = [typeString componentsSeparatedByString:@","];
    NSString *typeAttribute = [attributes objectAtIndex:0];
    NSString *className = @"";
    
    if ([typeAttribute characterAtIndex:0] == 'T' && [typeAttribute characterAtIndex:1] != '@')
    {
        // it's a C primitive type
        className = [typeAttribute substringWithRange:NSMakeRange(1, [typeAttribute length]-1)];
    }
    else if ([typeAttribute characterAtIndex:0] == 'T' && [typeAttribute characterAtIndex:1] == '@' && [typeAttribute length] == 2)
    {
        // it's an ObjC id type
        className = @"id";
    }
    else if ([typeAttribute characterAtIndex:0] == 'T' && [typeAttribute characterAtIndex:1] == '@')
    {
        // it's another ObjC object type
        className = [typeAttribute substringWithRange:NSMakeRange(3, [typeAttribute length]-4)];
    }
    
    return className;
}

+ (NSString *)propertyClassNameFor:(NSString *)propertyName onObject:(SyncEntity *)object
{
    Class superClass = NSClassFromString(object.entity.name);
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([superClass class], &outCount);
    
    for (i = 0; i < outCount; i++)
    {
        objc_property_t property = properties[i];
        NSString *attributeName = [NSString stringWithFormat:@"%s", property_getName(property)];
        
        if ([attributeName isEqualToString:propertyName])
        {
            return [self propertyClassNameFor:property];
        }
    }
    
    return nil;
}

+ (Class)propertyTypeFor:(objc_property_t)property
{
    return NSClassFromString([NSString stringWithFormat:@"%@", [self propertyClassNameFor:property]]);
}

@end
