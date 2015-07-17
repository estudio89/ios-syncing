//
//  FieldSerializer.m
//  Syncing
//
//  Created by Rodrigo Suhr on 7/7/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "FieldSerializer.h"
#import "SerializationUtil.h"

@interface FieldSerializer ()

@property (strong, nonatomic) NSString *attribute;
@property (strong, nonatomic) NSManagedObject *object;
@property (strong, nonatomic) NSMutableDictionary *jsonObject;
@property (strong, nonatomic) JSON *annotation;

@end

@implementation FieldSerializer

- (instancetype)initWithAttribute:(NSString *)attribute
                       withObject:(NSManagedObject *)object
                         withJSON:(NSMutableDictionary *)jsonObject
                   withAnnotation:(JSON *)annotation
{
    self = [super init];
    
    if (self)
    {
        _attribute = attribute;
        _object = object;
        _jsonObject = jsonObject;
        _annotation = annotation;
    }
    
    return self;
}

- (NSString *)getAttributename
{
    return [SerializationUtil getAttributeName:_attribute
                                withAnnotation:_annotation];
}

- (BOOL)isIgnored
{
    return _annotation.ignore;
}

- (BOOL)isWritable
{
    return _annotation.writable;
}

- (BOOL)isReadable
{
    return _annotation.readable;
}

- (NSObject *)parseValue:(NSObject *)value
{
    return [self checkNill:value];
}

- (NSObject *)formatValue:(NSObject *)value
{
    return [self checkNill:value];
}

- (NSObject *)checkNill:(NSObject *)value
{
    if (value == nil)
    {
        return [NSNull null];
    }
    else
    {
        return value;
    }
}

- (BOOL)updateJSON
{
    if ([self isIgnored] || ![self isWritable])
    {
        return NO;
    }
    
    NSString *name = [self getAttributename];
    NSObject *value = [_object valueForKey:_attribute];
    
    if (_annotation.ignoreIf != nil)
    {
        if ([[value description] isEqualToString:_annotation.ignoreIf])
        {
            return NO;
        }
    }
    
    [_jsonObject setObject:[self formatValue:value] forKey:name];

    return YES;
}

- (BOOL)updateField
{
    if ([self isIgnored] || ![self isReadable])
    {
        return NO;
    }
    
    NSString *name = [self getAttributename];
    NSObject *value = [_jsonObject valueForKey:name];
    
    @try
    {
        [_object setValue:[self parseValue:value] forKey:name];
    }
    @catch (NSException *exception)
    {
        [NSException raise:NSInvalidArgumentException format:@"Invalid value for field %@. Type  %@.", value, [value class]];
    }
    
    return YES;
}

@end
