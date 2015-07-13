//
//  JSONSerializer.m
//  Syncing
//
//  Created by Rodrigo Suhr on 7/7/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "JSONSerializer.h"
#import "DateSerializer.h"
#import <objc/runtime.h>

@interface JSONSerializer ()

@property (strong, nonatomic) Class modelClass;
@property (strong, nonatomic) Annotations *annotations;
@property (strong, nonatomic) NSManagedObjectContext *context;

@end

@implementation JSONSerializer

- (instancetype)initWithModelClass:(Class)modelClass withAnnotations:(Annotations *)annotations withContext:(NSManagedObjectContext *)context
{
    self = [super init];
    
    if (self)
    {
        _modelClass = modelClass;
        _annotations = annotations;
        _context = context;
    }
    
    return self;
}

- (NSArray *)toJSON:(NSManagedObject *)object withJSON:(NSDictionary *)jsonObject
{
    Class superClass = _modelClass;
    NSMutableArray *unusedAttributes = [[NSMutableArray alloc] init];
    
    while (superClass != nil)
    {
        NSString *superClassName = [NSString stringWithUTF8String:class_getName(superClass)];
        NSEntityDescription *superClassEntity = [NSEntityDescription entityForName:superClassName
                                                            inManagedObjectContext:_context];
        NSDictionary *attributes = [superClassEntity attributesByName];
        
        for (NSAttributeDescription *attribute in [attributes allValues])
        {
            FieldSerializer *fieldSerializer = [self getFieldSerializer:attribute
                                                             withObject:object
                                                               withJSON:jsonObject];
            
            if (fieldSerializer == nil || ![fieldSerializer updateJSON])
            {
                [unusedAttributes addObject:attribute];
            }
        }
        
        superClass = class_getSuperclass(superClass);
        if (superClass == [NSManagedObject class])
        {
            break;
        }
    }
    
    return unusedAttributes;
}

- (NSArray *)updateFromJSON:(NSDictionary *)jsonObject withObject:(NSManagedObject *)object
{
    Class superClass = _modelClass;
    NSMutableArray *unusedAttributes = [[NSMutableArray alloc] init];
    
    while (superClass != nil)
    {
        NSString *superClassName = [NSString stringWithUTF8String:class_getName(superClass)];
        NSEntityDescription *superClassEntity = [NSEntityDescription entityForName:superClassName
                                                            inManagedObjectContext:_context];
        NSDictionary *attributes = [superClassEntity attributesByName];
        
        for (NSAttributeDescription *attribute in [attributes allValues])
        {
            FieldSerializer *fieldSerializer = [self getFieldSerializer:attribute
                                                             withObject:object
                                                               withJSON:jsonObject];
            
            if (fieldSerializer == nil || ![fieldSerializer updateField])
            {
                [unusedAttributes addObject:attribute];
            }
        }
        
        superClass = class_getSuperclass(superClass);
        if (superClass == [NSManagedObject class])
        {
            break;
        }
    }
    
    return unusedAttributes;
}

- (FieldSerializer *)getFieldSerializer:(NSAttributeDescription *)attribute withObject:(NSManagedObject *)object withJSON:(NSDictionary *)jsonObject
{
    JSON *fieldAnnotation = [_annotations annotationForAttribute:attribute.name];
    
    if ([attribute attributeType] == NSDateAttributeType)
    {
        return [[DateSerializer alloc] initWithAttribute:attribute
                                              withObject:object
                                                withJSON:jsonObject
                                          withAnnotation:fieldAnnotation];
    }
    else
    {
        return [[FieldSerializer alloc] initWithAttribute:attribute
                                               withObject:object
                                                 withJSON:jsonObject
                                           withAnnotation:fieldAnnotation];
    }
}

@end
