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

- (BOOL)allowOverwrite
{
    if (_annotation == nil) {
        return YES;
    } else {
        SyncEntity *se = (SyncEntity *)_object;
        if (!_annotation.allowOverwrite) {
            return ![se.modified boolValue];
        } else {
            return _annotation.allowOverwrite;
        }
    }
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
    
    NSObject *formatted = [self formatValue:value];
    NSArray *nameTree = [name componentsSeparatedByString:@"."];
    NSMutableDictionary *curJSONObj = _jsonObject;
    int idx = 0;
    
    for (NSString *part in nameTree) {
        if (idx == [nameTree count] - 1) {
            [curJSONObj setObject:formatted forKey:part];
        } else {
            if ([curJSONObj objectForKey:part] != nil) {
                curJSONObj = [curJSONObj objectForKey:part];
            } else {
                NSMutableDictionary *aux = [[NSMutableDictionary alloc] init];
                [curJSONObj setObject:aux forKey:part];
                curJSONObj = aux;
            }
        }
        
        idx += 1;
    }

    return YES;
}

- (BOOL)updateField
{
    if ([self isIgnored] || ![self isReadable] || ![self allowOverwrite])
    {
        return NO;
    }
    
    NSString *name = [self getAttributename];
    NSArray *nameTree = [name componentsSeparatedByString:@"."];
    NSObject *value = [NSNull null];
    NSMutableDictionary *curJSONObj = _jsonObject;
    int idx = 0;
    
    for (NSString *part in nameTree) {
        if (idx == [nameTree count] - 1) {
            value = [curJSONObj valueForKey:part];
        } else {
            curJSONObj = [curJSONObj objectForKey:part];
        }
        idx += 1;
    }
    
    if (![[self parseValue:value] isKindOfClass:[NSNull class]])
    {
        @try
        {
            [_object setValue:[self parseValue:value] forKey:_attribute];
        }
        @catch (NSException *exception)
        {
            [NSException raise:NSInvalidArgumentException format:@"Invalid value for field %@. Type  %@.", value, [value class]];
        }
    }
    
    return YES;
}

@end
