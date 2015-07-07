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

@property (strong, nonatomic) NSAttributeDescription *attribute;
@property (strong, nonatomic) NSManagedObject *object;
@property (strong, nonatomic) NSMutableDictionary *jsonObject;
@property (strong, nonatomic) NSDictionary *annotation;

@end

@implementation FieldSerializer

- (instancetype)initWithAttribute:(NSAttributeDescription *)attribute
                       withObject:(NSManagedObject *)object
                         withJSON:(NSDictionary *)jsonObject
                   withAnnotation:(NSDictionary *)annotation
{
    self = [super init];
    
    if (self)
    {
        _attribute = attribute;
        _object = object;
        _jsonObject = [jsonObject mutableCopy];
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
    BOOL ignore = NO;
    
    if ([_annotation objectForKey:@"ignore"] && ![[_annotation objectForKey:@"ignore"] isKindOfClass:[NSNull class]])
    {
        ignore = [[_annotation objectForKey:@"ignore"] boolValue];
    }
    
    return ignore;
}

- (BOOL)isWritable
{
    BOOL writable = NO;
    
    if ([_annotation objectForKey:@"writable"] && ![[_annotation objectForKey:@"writable"] isKindOfClass:[NSNull class]])
    {
        writable = [[_annotation objectForKey:@"writable"] boolValue];
    }
    
    return writable;
}

- (BOOL)isReadable
{
    BOOL readable = NO;
    
    if ([_annotation objectForKey:@"readable"] && ![[_annotation objectForKey:@"readable"] isKindOfClass:[NSNull class]])
    {
        readable = [[_annotation objectForKey:@"readable"] boolValue];
    }
    
    return readable;
}

- (BOOL)updateJSON
{
    if ([self isIgnored] || ![self isWritable])
    {
        return NO;
    }
    
    NSString *name = [self getAttributename];
    NSObject *value = [_object valueForKey:name];
    
    NSString *ignoreIf = [_annotation valueForKey:@"ignoreIf"];
    NSString *noValue = [_annotation valueForKey:@"noValue"];
    
    if (_annotation != nil && ![ignoreIf isEqualToString:noValue])
    {
        if ([[value description] isEqualToString:ignoreIf])
        {
            return NO;
        }
    }
    
    [_jsonObject setObject:[_object valueForKey:name] forKey:name];
    
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
        [_object setValue:value forKey:name];
    }
    @catch (NSException *exception)
    {
        [NSException raise:NSInvalidArgumentException format:@"Invalid value for field %@. Type should be %lu, but was %@.", value, (unsigned long)[_attribute attributeType], [value class]];
    }
    
    return YES;
}

@end
