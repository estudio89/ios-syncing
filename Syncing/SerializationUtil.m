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
    return [NSString stringWithFormat:@"%s", getPropertyType(property)];
}

+ (Class)propertyTypeFor:(objc_property_t)property
{
    return NSClassFromString([NSString stringWithFormat:@"%s", getPropertyType(property)]);
}

static const char * getPropertyType(objc_property_t property)
{
    const char *attributes = property_getAttributes(property);
    char buffer[1 + strlen(attributes)];
    strcpy(buffer, attributes);
    char *state = buffer, *attribute;
    while ((attribute = strsep(&state, ",")) != NULL)
    {
        if (attribute[0] == 'T' && attribute[1] != '@')
        {
            // it's a C primitive type
            return (const char *)[[NSData dataWithBytes:(attribute + 1) length:strlen(attribute) - 1] bytes];
        }
        else if (attribute[0] == 'T' && attribute[1] == '@' && strlen(attribute) == 2)
        {
            // it's an ObjC id type
            return "id";
        }
        else if (attribute[0] == 'T' && attribute[1] == '@')
        {
            // it's another ObjC object type
            return (const char *)[[NSData dataWithBytes:(attribute + 3) length:strlen(attribute) - 4] bytes];
        }
    }
    
    return "";
}

@end
