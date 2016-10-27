//
//  Annotations.m
//  Syncing
//
//  Created by Rodrigo Suhr on 7/9/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "Annotations.h"

//============================================|Annotations|============================================

@interface Annotations ()

@property (strong, readwrite) NSDictionary *Annotation;
@property (strong, readwrite) NSMutableDictionary *jsonAnnotations;
@property (strong, readwrite) Paginate *paginate;
@property (strong, readwrite) NSMutableDictionary *nestedManagers;
@property (strong, readwrite) NSString *entityName;

@end

@implementation Annotations

- (instancetype)initWithAnnotation:(NSDictionary *)annotation
{
    self = [super init];
    
    if (self)
    {
        _Annotation = annotation;
        _jsonAnnotations = [[NSMutableDictionary alloc] init];
        _nestedManagers = [[NSMutableDictionary alloc] init];
        [self instantiateAnnotations];
    }
    
    return self;
}

- (void)mergeWith:(NSDictionary *)annotation {
    NSMutableDictionary *mutableAnnotationDict = [annotation mutableCopy];
    NSMutableDictionary *fieldsAnnotationDict = [mutableAnnotationDict objectForKey:@"fields"];
    
    [fieldsAnnotationDict addEntriesFromDictionary:_Annotation];
    [mutableAnnotationDict setObject:fieldsAnnotationDict forKey:@"fields"];
    
    _Annotation = [mutableAnnotationDict copy];
    
    _jsonAnnotations = [[NSMutableDictionary alloc] init];
    _nestedManagers = [[NSMutableDictionary alloc] init];
    [self instantiateAnnotations];
}

- (void)instantiateAnnotations
{
    // Entity  name instantiation
    _entityName = [_Annotation valueForKey:@"entityName"];
    
    // JSON instantiation
    NSDictionary *fields = [_Annotation objectForKey:@"fields"];
    for (NSString *field in [fields allKeys])
    {
        JSON *jsonAnnotation = [[JSON alloc] initWithAnnotation:[fields objectForKey:field]];
        [_jsonAnnotations setObject:jsonAnnotation forKey:field];
    }
    
    // Paginate instantiation
    if ([_Annotation objectForKeyedSubscript:@"paginate"] != nil)
    {
        _paginate = [[Paginate alloc] initWithAnnotation:[_Annotation objectForKey:@"paginate"]];
    }
    else
    {
        _paginate = nil;
    }
    
    // NestedManagers instantiation
    NSDictionary *nestedManagers = [_Annotation objectForKey:@"nestedManagers"];
    for (NSString *field in [nestedManagers allKeys])
    {
        NestedManager *nestedManager = [[NestedManager alloc] initWithAnnotation:[nestedManagers objectForKey:field]];
        [_nestedManagers setObject:nestedManager forKey:field];
    }
}

- (JSON *)annotationForAttribute:(NSString *)attribute
{
    return [_jsonAnnotations objectForKey:attribute];
}

- (NestedManager *)nestedManagerForAttribute:(NSString *)attribute
{
    return [_nestedManagers objectForKey:attribute];
}

- (BOOL)hasNestedManagerForAttribute:(NSString *)attribute
{
    BOOL hasNestedManager = NO;
    
    if ([_nestedManagers objectForKey:attribute] != nil)
    {
        hasNestedManager = YES;
    }
    
    return hasNestedManager;
}

- (BOOL)shouldPaginate
{
    return _paginate != nil;
}

@end

//============================================|JSON|============================================

@interface JSON ()

@property (strong, readwrite) NSString *ignoreIf;
@property (strong, readwrite) NSString *name;

@end

@implementation JSON

- (instancetype)initWithAnnotation:(NSDictionary *)annotation
{
    self = [super init];
    
    if (self)
    {
        // ignoreIf
        if ([annotation valueForKey:@"ignoreIf"] != nil) {
            _ignoreIf = [annotation valueForKey:@"ignoreIf"];
        } else {
            _ignoreIf = nil;
        }
        
        // ignore
        if ([annotation objectForKey:@"ignore"] != nil) {
            _ignore = [[annotation objectForKey:@"ignore"] boolValue];
        } else {
            _ignore = NO;
        }
        
        // writable
        if ([annotation objectForKey:@"writable"] != nil) {
            _writable = [[annotation objectForKey:@"writable"] boolValue];
        } else {
            _writable = YES;
        }
        
        // readable
        if ([annotation objectForKey:@"readable"] != nil) {
            _readable = [[annotation objectForKey:@"readable"] boolValue];
        } else {
            _readable = YES;
        }
        
        // name
        if ([annotation valueForKey:@"name"] != nil) {
            _name = [annotation valueForKey:@"name"];
        } else {
            _name = @"";
        }
        
        // allowOverwrite
        if ([annotation objectForKey:@"allowOverwrite"] != nil) {
            _allowOverwrite = [[annotation objectForKey:@"allowOverwrite"] boolValue];
        } else {
            _allowOverwrite = YES;
        }
    }
    
    return self;
}

@end

//============================================|Paginate|============================================

@interface Paginate ()

@property (strong, readwrite) NSString *byField;
@property (strong, readwrite) NSString *extraIdentifier;

@end

@implementation Paginate

- (instancetype)initWithAnnotation:(NSDictionary *)annotation
{
    self = [super init];
    
    if (self)
    {
        _byField = [annotation valueForKey:@"byField"];
        
        if ([annotation valueForKey:@"extraIdentifier"] != nil) {
            _extraIdentifier = [annotation valueForKey:@"extraIdentifier"];
        } else {
            _extraIdentifier = @"";
        }
    }
    
    return self;
}

@end

//============================================|NestedManager|============================================

@interface NestedManager ()

@property (strong, readwrite) NSString *entityName;
@property (strong, readwrite) NSString *attributeName;
@property (strong, readwrite) id<SyncManager> manager;
@property (strong, readwrite) NSString *paginationParams;

@end

@implementation NestedManager

- (instancetype)initWithAnnotation:(NSDictionary *)annotation
{
    self = [super init];
    
    if (self)
    {
        // entityName
        _entityName = [annotation valueForKey:@"entityName"];
        
        // attributeName
        _attributeName = [annotation valueForKey:@"parentAttribute"];
        
        // manager
        Class klass = NSClassFromString([annotation valueForKey:@"manager"]);
        _manager = [[klass alloc] init];
        
        // writable
        if ([annotation objectForKey:@"writable"] != nil) {
            _writable = [[annotation objectForKey:@"writable"] boolValue];
        } else {
            _writable = NO;
        }
        
        // accessorMethod
        if ([annotation objectForKey:@"accessorMethod"] != nil) {
            _accessorMethod = NSSelectorFromString([annotation valueForKey:@"accessorMethod"]);
        } else {
            _accessorMethod = nil;
        }
        
        // discardOnSave
        if ([annotation objectForKey:@"discardOnSave"] != nil) {
            _discardOnSave = [[annotation objectForKey:@"discardOnSave"] boolValue];
        } else {
            _discardOnSave = NO;
        }
        
        // paginationParams
        if ([annotation valueForKey:@"paginationParams"] != nil) {
            _paginationParams = [annotation valueForKey:@"paginationParams"];
        } else {
            _paginationParams = @"";
        }
        
    }
    
    return self;
}

@end
