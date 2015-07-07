//
//  AbstractSyncManager.m
//  Syncing
//
//  Created by Rodrigo Suhr on 7/7/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "AbstractSyncManager.h"
#import "ReadOnlyAbstractSyncManager.h"
#import "SerializationUtil.h"

@interface AbstractSyncManager ()

@property (strong, nonatomic) NSDictionary *annotation;
@property (strong, nonatomic) NSDictionary *attributesAnnotation;
@property (strong, nonatomic) NSMutableDictionary *parentAttributes;
@property BOOL shouldPaginate;
@property (strong, nonatomic) NSString *entityName;
@property (strong, nonatomic) NSString *dateAttributeName;

@end

@implementation AbstractSyncManager

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _annotation = [self getAnnotationDictionary];
        _attributesAnnotation = [_annotation objectForKey:@"fields"];
        _parentAttributes = [[NSMutableDictionary alloc] init];
        
        if ([_annotation valueForKey:@"paginateBy"])
        {
            _shouldPaginate = YES;
        }
        else
        {
            _shouldPaginate = NO;
        }
        
        if (_shouldPaginate && [self isKindOfClass:[ReadOnlyAbstractSyncManager class]])
        {
            [NSException raise:NSInvalidArgumentException format:@"ReadOnlyAbstractSyncManager classes cannot paginate. Remove the 'paginateBy' key from your annotation dictionary."];
        }
        
        _entityName = [_annotation valueForKey:@"entityName"];
        [self verifyFields];
        
        if (_entityName == nil)
        {
            [NSException raise:NSInvalidArgumentException format:@"The 'entityName' value was not found in annotation dictionary."];
        }
    }
    
    return self;
}

- (void)verifyFields
{
    //FIXME
    NSEntityDescription *superClassEntity = [NSEntityDescription entityForName:_entityName
                                                        inManagedObjectContext:_context];
    NSDictionary *attributes = [superClassEntity attributesByName];
    NSDictionary *nestedManagers = [_annotation objectForKey:@"nestedManagers"];
    
    NSString *paginateField = @"";
    if (_shouldPaginate)
    {
        paginateField = [_annotation valueForKey:@"paginateBy"];
    }
    
    
    NSDictionary *attributeAnnotation = nil;
    
    for (NSAttributeDescription *attribute in [attributes allValues])
    {
        attributeAnnotation = [_attributesAnnotation objectForKey:attribute.name];
        
        if (_shouldPaginate && [attribute attributeType] == NSDateAttributeType)
        {
            if ([paginateField isEqualToString:@""] || [paginateField isEqualToString:attribute.name])
            {
                _dateAttributeName = attribute.name;
            }
        }
        //FIXME
        else if (![[attributeAnnotation objectForKey:@"ignore"] boolValue])
        {
            NSString *parentAttributeName = [SerializationUtil getAttributeName:attribute
                                                                 withAnnotation:attributeAnnotation];
            [_parentAttributes setObject:attribute forKey:parentAttributeName];
        }
        else if (nestedManagers && [nestedManagers objectForKey:attribute.name])
        {
            //...
        }
    }
}

@end
