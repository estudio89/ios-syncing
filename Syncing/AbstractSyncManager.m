//
//  AbstractSyncManager.m
//  Syncing
//
//  Created by Rodrigo Suhr on 7/7/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "AbstractSyncManager.h"
#import "SerializationUtil.h"
#import <Raven/RavenClient.h>
#import "JSONSerializer.h"
#import "SyncModelSerializer.h"

@interface AbstractSyncManager ()

@property (strong, nonatomic) Annotations *annotations;
@property (strong, nonatomic) NSMutableDictionary *parentAttributes;
@property (strong, nonatomic) NSMutableDictionary *childrenAttributes;
@property BOOL shouldPaginate;
@property (strong, nonatomic) NSString *entityName;
@property (strong, nonatomic) NSAttributeDescription *dateAttribute;
@property (strong, nonatomic) NSString *paginationIdentifier;
@property (strong, nonatomic) NSManagedObject *oldestInCache;

@end

@implementation AbstractSyncManager

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _annotations = [self getAnnotations];
        _parentAttributes = [[NSMutableDictionary alloc] init];
        _childrenAttributes = [[NSMutableDictionary alloc] init];
        
        _shouldPaginate = [_annotations shouldPaginate];
        
        if (_shouldPaginate && [self isKindOfClass:[ReadOnlyAbstractSyncManager class]])
        {
            [NSException raise:NSInvalidArgumentException format:@"ReadOnlyAbstractSyncManager classes cannot paginate. Remove the 'paginateBy' key from your annotation dictionary."];
        }
        
        _entityName = [_annotations entityName];
        
        if (_entityName == nil)
        {
            [NSException raise:NSInvalidArgumentException format:@"The 'entityName' value was not found in annotation dictionary."];
        }
        
        [self verifyFields];
    }
    
    return self;
}

- (void)verifyFields
{
    NSEntityDescription *superClassEntity = [NSEntityDescription entityForName:_entityName
                                                        inManagedObjectContext:[_annotations context]];
    NSDictionary *attributes = [superClassEntity attributesByName];
    
    NSString *paginateField = @"";
    if (_shouldPaginate)
    {
        paginateField = [_annotations.paginate byField];
        _paginationIdentifier = [_annotations.paginate extraIdentifier];
    }
    
    JSON *attAnnotation = nil;
    for (NSAttributeDescription *attribute in [attributes allValues])
    {
        attAnnotation = [_annotations annotationForAttribute:attribute.name];
        Class type = NSClassFromString(attribute.attributeValueClassName);
        
        if (_shouldPaginate && type == [NSDate class])
        {
            if ([paginateField isEqualToString:@""] || [paginateField isEqualToString:attribute.name])
            {
                _dateAttribute = attribute;
            }
        }
        else if ([type isSubclassOfClass:[SyncEntity class]] && !attAnnotation.ignore)
        {
            NSString *parentAttributeName = [SerializationUtil getAttributeName:attribute.name
                                                                 withAnnotation:attAnnotation];
            [_parentAttributes setObject:attribute forKey:parentAttributeName];
        }
        else if ([_annotations hasNestedManagerForAttribute:attribute.name])
        {
            NestedManager *nestedManager = [_annotations nestedManagerForAttribute:attribute.name];
            [_childrenAttributes setObject:nestedManager forKey:attribute.name];
        }
    }
}

- (NSDate *)getDateForObject:(NSManagedObject *)object
{
    return [object valueForKey:_dateAttribute.name];
}

- (id<SyncManager>)getSyncManagerDeleted
{
    return nil;
}

- (NSString *)getIdentifier
{
    return nil;
}

- (NSString *)getResponseIdentifier
{
    return nil;
}

- (BOOL)shouldSendSingleObject
{
    return nil;
}

- (NSMutableArray *)getModifiedDataWithContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:_entityName];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"modified==YES"]];
    
    NSArray *objects = [context executeFetchRequest:fetchRequest error:nil];
    NSMutableArray *modifiedData = [[NSMutableArray alloc] init];
    
    for (NSManagedObject *obj in objects)
    {
        [modifiedData addObject:[self serializeObject:obj withContext:context]];
    }
    
    return modifiedData;
}

- (BOOL)hasModifiedDataWithContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:_entityName];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"modified==YES"]];
    
    NSUInteger rCount = [context countForFetchRequest:fetchRequest error:nil];
    
    return rCount > 0;
}

- (NSMutableArray *)getModifiedFilesWithContext:(NSManagedObjectContext *)context
{
    return nil;
}

- (NSMutableArray *)getModifiedFilesForObject:(NSDictionary *)object withContext:(NSManagedObjectContext *)context
{
    return nil;
}

- (NSString *)getPaginationIdentifier:(NSDictionary *)params
{
    NSString *identifier = @"";
    
    if (![_paginationIdentifier isEqualToString:@""])
    {
        identifier = [NSString stringWithFormat:@".%@", [params valueForKey:_paginationIdentifier]];
    }
    
    return identifier;
}

- (NSMutableArray *)saveNewData:(NSArray *)jsonObjects withDeviceId:(NSString *)deviceId withParameters:(NSDictionary *)responseParameters withContext:(NSManagedObjectContext *)context
{
    if (_shouldPaginate && [responseParameters objectForKey:@"more"] != nil)
    {
        BOOL more = [[responseParameters objectForKey:@"more"] boolValue];
        [self saveBooleanPref:[NSString stringWithFormat:@"more%@", [self getPaginationIdentifier:responseParameters]] withValue:more];
    }
    
    NSArray *deletedObjects = nil;
    BOOL isSyncing = NO;
    if (_shouldPaginate && [responseParameters objectForKey:@"deleteCache"] != nil)
    {
        isSyncing = YES;
        BOOL deleteCache = [[responseParameters objectForKey:@"deleteCache"] boolValue];
        if (deleteCache)
        {
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:_entityName];
            [fetchRequest setIncludesPropertyValues:NO];
            deletedObjects = [context executeFetchRequest:fetchRequest error:nil];
            
            for (NSManagedObject *obj in deletedObjects)
            {
                [context deleteObject:obj];
            }
            [context save:nil];
            
            [self saveBooleanPref:[NSString stringWithFormat:@"more%@", [self getPaginationIdentifier:responseParameters]] withValue:YES];
        }
    }
    
    _oldestInCache = [self getOldestFromContext:context];
    NSMutableArray *newObjects = [[NSMutableArray alloc] init];
    
    @try
    {
        for (NSDictionary *objectJSON in jsonObjects)
        {
            if (_shouldPaginate && isSyncing && _dateAttribute != nil && _oldestInCache != nil)
            {
                JSON *attAnnotation = [_annotations annotationForAttribute:_dateAttribute.name];
                NSString *jsonAttribute = [SerializationUtil getAttributeName:_dateAttribute.name withAnnotation:attAnnotation];
                NSString *strDate = [objectJSON valueForKey:jsonAttribute];
                NSDate *pubDate = [SerializationUtil parseServerDate:strDate];
                
                if ([pubDate compare:[self getDateForObject:_oldestInCache]] == NSOrderedAscending)
                {
                    [self saveBooleanPref:[NSString stringWithFormat:@"more%@", [self getPaginationIdentifier:responseParameters]]
                                withValue:YES];
                    continue;
                }
                
            }
            
            NSManagedObject *object = [self saveObject:objectJSON withDeviceId:deviceId withContext:context];
            [newObjects addObject:object];
        }
    }
    @catch (NSException *e)
    {
        [[RavenClient sharedClient] captureException:e method:__FUNCTION__ file:__FILE__ line:__LINE__ sendNow:YES];
    }
    
    if (deletedObjects != nil)
    {
        [[self getSyncManagerDeleted] postEvent:deletedObjects withBus:[[AsyncBus alloc] init]];
    }
    
    return newObjects;
}

- (void)processSendResponse:(NSArray *)jsonResponse withContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:_entityName];
    NSArray *objectsArray = nil;
    
    @try
    {
        for (NSDictionary *obj in jsonResponse)
        {
            NSURL *objUrl = [NSURL URLWithString:[obj valueForKey:@"idClient"]];
            NSManagedObjectID *objectID = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation:objUrl];
            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"idServer==%@ OR objectID==%@", [obj valueForKey:@"id"], objectID]];
            
            objectsArray = [context executeFetchRequest:fetchRequest error:nil];
            
            if ([objectsArray count] > 0)
            {
                NSManagedObject *object = [objectsArray objectAtIndex:0];
                [object setValue:@(NO) forKey:@"modified"];
                [object setValue:[obj valueForKey:@"id"] forKey:@"idServer"];
            }
        }
        
        [context save:nil];
    }
    @catch (NSException *e)
    {
        [[RavenClient sharedClient] captureException:e method:__FUNCTION__ file:__FILE__ line:__LINE__ sendNow:YES];
    }
}

- (NSDictionary *)serializeObject:(NSObject *)object withContext:(NSManagedObjectContext *)context
{
    NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
    JSONSerializer *serializer = [[JSONSerializer alloc] initWithModelClass:NSClassFromString(_entityName)
                                                            withAnnotations:_annotations
                                                                withContext:context];
    
    [serializer toJSON:(NSManagedObject *)object withJSON:[[NSDictionary alloc] init]];
    
    if ([_parentAttributes count] > 0)
    {
        for (NSString *attributeName in [_parentAttributes allKeys])
        {
            [jsonObject setValue:[object valueForKey:@"idServer"] forKey:attributeName];
        }
    }
    

    for (NSString *childAttName in [_childrenAttributes allKeys])
    {
        NestedManager *annotation = [_childrenAttributes objectForKey:childAttName];
        
        if (annotation.writable)
        {
            JSON *jsonAttribute = [_annotations annotationForAttribute:childAttName];
            NSString *attributeName = [SerializationUtil getAttributeName:childAttName withAnnotation:jsonAttribute];
            id<SyncManager> childSyncManager = annotation.manager;
            
            NSSet *children = nil;
            if (annotation.accessorMethod != nil)
            {
                children = [self performSelector:annotation.accessorMethod];
            }
            else
            {
                children = [object valueForKey:childAttName];
            }
            
            NSMutableArray *serializedChildren = [[NSMutableArray alloc] init];
            for (SyncEntity *child in children)
            {
                [serializedChildren addObject:[childSyncManager serializeObject:child withContext:context]];
            }
            
            @try
            {
                [jsonObject setObject:serializedChildren forKey:attributeName];
            }
            @catch (NSException *e)
            {
                [[RavenClient sharedClient] captureException:e method:__FUNCTION__ file:__FILE__ line:__LINE__ sendNow:YES];
            }
        }
    }
    
    return jsonObject;
}

- (id)saveObject:(NSDictionary *)object withDeviceId:(NSString *)deviceId withContext:(NSManagedObjectContext *)context
{
    NSNumber *idServer = [object valueForKey:@"id"];
    NSString *idClient = [object valueForKey:@"idClient"];
    NSString *itemDeviceId = [object valueForKey:@"deviceId"];
    
    SyncEntity *newItem = [self findItem:idServer
                            withIdClient:idClient
                            withDeviceId:deviceId
                        withItemDeviceId:itemDeviceId
                              withObject:object];
    BOOL checkIsNew = NO;
    if (newItem == nil)
    {
        newItem = [NSEntityDescription insertNewObjectForEntityForName:_entityName inManagedObjectContext:context];
        checkIsNew = YES;
    }
    
    SyncModelSerializer *serializer = [[SyncModelSerializer alloc] initWithModelClass:NSClassFromString(_entityName)
                                                                      withAnnotations:_annotations
                                                                          withContext:context];
    [serializer updateFromJSON:object withObject:newItem];
    
    if (checkIsNew)
    {
        if (_dateAttribute != nil)
        {
            NSDate *newItemDate = [self getDateForObject:newItem];
            NSDate *oldestDate = [self getDateForObject:_oldestInCache];
            if (_oldestInCache == nil || [newItemDate compare:oldestDate] == NSOrderedDescending)
            {
                newItem.isNew = [NSNumber numberWithBool:YES];
            }
        }
        else
        {
            newItem.isNew = [NSNumber numberWithBool:YES];
        }
    }

    if ([_parentAttributes count] > 0)
    {
        for (NSString *parentAttributeName in [_parentAttributes allKeys])
        {
            NSAttributeDescription *parentAttribute = [_parentAttributes objectForKey:parentAttributeName];
            NSString *parentId = [object valueForKey:parentAttributeName];
            
            SyncEntity *parent = [self findParent:parentAttribute.attributeValueClassName withParentId:parentId];
            if (parent == nil && [parentId isEqual:@"nil"])
            {
                NSString *reason = [NSString stringWithFormat:@"An item of class %@ with id server %@ was not found for item of class %@ with id_server %@", parentAttribute.attributeValueClassName, parentId, _entityName, newItem.idServer];
                @throw [NSException exceptionWithName:@"AbstractSyncManagerException"
                                               reason:reason
                                             userInfo:nil];
            }
            
            [newItem setValue:parent forKey:parentAttributeName];
        }
    }
    
    [context save:nil];
    
    if ([_childrenAttributes count] > 0)
    {
        for (NSString *childrenAttributeName in [_childrenAttributes allKeys])
        {
            JSON *jsonAttribute = [_annotations annotationForAttribute:childrenAttributeName];
            NSString *jsonName = [SerializationUtil getAttributeName:childrenAttributeName withAnnotation:jsonAttribute];
            NSArray *children = [object objectForKey:jsonName];
            
            NestedManager *annotation = [_childrenAttributes objectForKey:childrenAttributeName];
            id<SyncManager> nestedSyncManager = annotation.manager;
            NSDictionary *childParams = nil;
            
            if (![annotation.paginationParams isEqualToString:@""])
            {
                childParams = [object objectForKey:annotation.paginationParams];
            }
            else
            {
                childParams = [[NSDictionary alloc] init];
            }
            
            if (annotation.discardOnSave && newItem.objectID != nil)
            {
                
            }
        }
        
    }
    
    return newItem;
}

- (void)saveBooleanPref:(NSString *)key withValue:(BOOL)value
{
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:value] forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSManagedObject *)getOldestFromContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:_entityName];
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:_dateAttribute.name ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    [fetchRequest setFetchLimit:1];
    
    NSArray *oldestArray = [context executeFetchRequest:fetchRequest error:nil];
    
    if (oldestArray == nil || [oldestArray count] == 0)
    {
        return nil;
    }
    
    return [oldestArray objectAtIndex:0];
}

- (SyncEntity *)findItem:(NSNumber *)idServer
            withIdClient:(NSString *)idClient
            withDeviceId:(NSString *)deviceId
        withItemDeviceId:(NSString *)itemDeviceId
{
    return [self findItem:idServer
             withIdClient:idClient
             withDeviceId:deviceId
         withItemDeviceId:itemDeviceId
       withIgnoreDeviceId:NO
               withObject:nil];
    
}

- (SyncEntity *)findItem:(NSNumber *)idServer
            withIdClient:(NSString *)idClient
            withDeviceId:(NSString *)deviceId
        withItemDeviceId:(NSString *)itemDeviceId
      withIgnoreDeviceId:(BOOL)ignoreDeviceId
{
    return [self findItem:idServer
             withIdClient:idClient
             withDeviceId:deviceId
         withItemDeviceId:itemDeviceId
       withIgnoreDeviceId:NO
               withObject:nil];
}

- (SyncEntity *)findItem:(NSNumber *)idServer
            withIdClient:(NSString *)idClient
            withDeviceId:(NSString *)deviceId
        withItemDeviceId:(NSString *)itemDeviceId
              withObject:(NSDictionary *)object
{
    return [self findItem:idServer
             withIdClient:idClient
             withDeviceId:deviceId
         withItemDeviceId:itemDeviceId
       withIgnoreDeviceId:NO
               withObject:object];
}

- (SyncEntity *)findItem:(NSNumber *)idServer
            withIdClient:(NSString *)idClient
            withDeviceId:(NSString *)deviceId
        withItemDeviceId:(NSString *)itemDeviceId
      withIgnoreDeviceId:(BOOL)ignoreDeviceId
              withObject:(NSDictionary *)object
{
    NSArray *objectList = nil;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:_entityName];

    if ((ignoreDeviceId || [deviceId isEqualToString:itemDeviceId]) && idClient != nil)
    {
        NSURL *objUrl = [NSURL URLWithString:idClient];
        NSManagedObjectID *objectID = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation:objUrl];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"idServer==%@ OR objectID==%@", idServer, objectID]];
    }
    else
    {
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"idServer==%@", idServer]];
    }
    
    objectList = [context executeFetchRequest:fetchRequest error:nil];
    
    if ([objectList count] > 0)
    {
        return [objectList objectAtIndex:0];
    }
    else
    {
        return nil;
    }
}

- (SyncEntity *)findParent:(NSString *)parentEntity withParentId:(NSString *)parentId
{
    if (parentId == nil || [parentId isEqualToString:@"nil"])
    {
        return nil;
    }
    
    NSArray *objectList = nil;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:parentEntity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"idServer==%@", parentId]];
    
    objectList = [context executeFetchRequest:fetchRequest error:nil];
    
    if ([objectList count] > 0)
    {
        return [objectList objectAtIndex:0];
    }
    else
    {
        return nil;
    }
}

- (NSString *)stringOrNil:(NSDictionary *)object withKey:(NSString *)key
{
    return [object objectForKey:key] != nil && ![[object valueForKey:key] isEqualToString:@"nil"] ? [object valueForKey:key] : nil;
}

- (void)deleteAllChildren
{
    
}

@end
