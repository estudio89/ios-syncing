//
//  AbstractSyncManager.m
//  Syncing
//
//  Created by Rodrigo Suhr on 7/7/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "AbstractSyncManager.h"
#import <objc/runtime.h>
#import "SerializationUtil.h"
#import "JSONSerializer.h"
#import "SyncModelSerializer.h"
#import "SyncEntity.h"
#import "Annotations.h"
#import "ReadOnlyAbstractSyncManager.h"
#import "DataSyncHelper.h"

@interface AbstractSyncManager ()

@property (strong, nonatomic, readwrite) Annotations *annotations;
@property (strong, nonatomic, readwrite) NSMutableDictionary *parentAttributes;
@property (strong, nonatomic, readwrite) NSMutableDictionary *childrenAttributes;
@property BOOL shouldPaginate;
@property (strong, nonatomic) NSString *entityName;
@property (strong, nonatomic, readwrite) NSString *dateAttribute;
@property (strong, nonatomic) NSString *paginationIdentifier;

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

- (Annotations *)getAnnotations {
    NSDictionary *idServer = @{@"name":@"id",
                               @"ignoreIf":@"0"};
    NSDictionary *modified = @{@"ignore":@YES};
    NSDictionary *isNew = @{@"ignore":@YES};
    NSDictionary *extraAttributes = @{@"idServer":idServer,
                                      @"modified":modified,
                                      @"isNew":isNew};
    
    Annotations *annotations = [[Annotations alloc] initWithAnnotation:extraAttributes];
    return annotations;
}

- (void)verifyFields
{
    Class superClass = NSClassFromString(_entityName);
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([superClass class], &outCount);
    
    NSString *paginateField = @"";
    if (_shouldPaginate)
    {
        paginateField = [_annotations.paginate byField];
        _paginationIdentifier = [_annotations.paginate extraIdentifier];
    }
    
    JSON *attAnnotation = nil;
    for (i = 0; i < outCount; i++)
    {
        objc_property_t property = properties[i];
        NSString *attributeName = [NSString stringWithFormat:@"%s", property_getName(property)];
        
        attAnnotation = [_annotations annotationForAttribute:attributeName];
        NSString *typeName = [SerializationUtil propertyClassNameFor:property];
        Class type = NSClassFromString(typeName);
        
        if (_shouldPaginate && type == [NSDate class])
        {
            if ([paginateField isEqualToString:@""] || [paginateField isEqualToString:attributeName])
            {
                _dateAttribute = attributeName;
            }
        }
        else if ([type isSubclassOfClass:[SyncEntity class]] && !attAnnotation.ignore)
        {
            NSString *parentAttributeName = [SerializationUtil getAttributeName:attributeName
                                                                 withAnnotation:attAnnotation];
            [_parentAttributes setObject:parentAttributeName forKey:attributeName];
        }
        else if ([_annotations hasNestedManagerForAttribute:attributeName])
        {
            NestedManager *nestedManager = [_annotations nestedManagerForAttribute:attributeName];
            [_childrenAttributes setObject:nestedManager forKey:attributeName];
        }
    }
    
    free(properties);
}

- (void)setDataSyncHelper:(DataSyncHelper *)dataSyncHelper
{
    _dataSyncHelper = dataSyncHelper;
}

- (NestedManager *)getNestedManagerForAttribute:(NSString *)attribute
{
    return [_childrenAttributes objectForKey:attribute];
}

- (id<SyncManager>)syncManagerForNestedManager:(NestedManager *)nestedManager
{
    return nestedManager.manager;
}

- (NSDate *)getDateForObject:(NSManagedObject *)object
{
    return [object valueForKey:_dateAttribute];
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

- (NSUInteger)getDelay
{
    return 0;
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
            deletedObjects = [self listAllWithContext:context];
            [self deleteAllWithContext:context];

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
                JSON *attAnnotation = [_annotations annotationForAttribute:_dateAttribute];
                NSString *jsonAttribute = [SerializationUtil getAttributeName:_dateAttribute withAnnotation:attAnnotation];
                NSString *strDate = [NSString stringWithFormat:@"%@", [objectJSON valueForKey:jsonAttribute]];
                NSDate *pubDate = [SerializationUtil parseServerDate:strDate];
                
                if ([pubDate compare:[self getDateForObject:_oldestInCache]] == NSOrderedAscending)
                {
                    [self saveBooleanPref:[NSString stringWithFormat:@"more%@", [self getPaginationIdentifier:responseParameters]]
                                withValue:YES];
                    continue;
                }
                
            }
            
            NSManagedObject *object = [self saveObject:objectJSON withDeviceId:deviceId withContext:context];
            if (object != nil) {
                [newObjects addObject:object];
            }
        }
    }
    @catch (NSException *e)
    {
        [self throwException:e];
    }
    
    if (deletedObjects != nil)
    {
        id<SyncManager> deletedSyncManager = [self getSyncManagerDeleted];
        if (deletedSyncManager) {
            [_dataSyncHelper addToEventQueue:[deletedSyncManager getIdentifier] withObjects:deletedObjects];
        }
    }
    
    return newObjects;
}

- (void)processSendResponse:(NSArray *)jsonResponse withContext:(NSManagedObjectContext *)context
{
    @try
    {
        for (NSDictionary *obj in jsonResponse)
        {
            
            NSManagedObject *object = [self findItem:[obj valueForKey:@"id"]
                                        withIdClient:[obj valueForKey:@"idClient"]
                                        withDeviceId:@""
                                    withItemDeviceId:nil
                                  withIgnoreDeviceId:YES
                                         withContext:context];
            
            if (object != nil)
            {
                [object setValue:@(NO) forKey:@"modified"];
                [object setValue:[obj valueForKey:@"id"] forKey:@"idServer"];
            }
        }
    }
    @catch (NSException *e)
    {
        [self throwException:e];
    }
}

- (NSDictionary *)serializeObject:(NSObject *)object withContext:(NSManagedObjectContext *)context
{
    NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
    
    SyncModelSerializer *serializer = [[SyncModelSerializer alloc] initWithModelClass:NSClassFromString(_entityName)
                                                                      withAnnotations:_annotations];
    [serializer toJSON:(NSManagedObject *)object withJSON:jsonObject];
    
    if ([_parentAttributes count] > 0)
    {
        for (NSString *attributeName in [_parentAttributes allKeys])
        {
            SyncEntity *parent = [object valueForKey:attributeName];
            if (parent != nil)
            {
                [jsonObject setValue:parent.idServer forKey:[_parentAttributes valueForKey:attributeName]];
            }
            else
            {
                [jsonObject setValue:[NSNull null] forKey:[_parentAttributes valueForKey:attributeName]];
            }
        }
    }

    for (NSString *childAttName in [_childrenAttributes allKeys])
    {
        NestedManager *annotation = [self getNestedManagerForAttribute:childAttName];
        
        if (annotation.writable)
        {
            JSON *jsonAttribute = [_annotations annotationForAttribute:childAttName];
            NSString *attributeName = [SerializationUtil getAttributeName:childAttName withAnnotation:jsonAttribute];
            id<SyncManager> childSyncManager = [self syncManagerForNestedManager:annotation];
            
            NSSet *children = nil;
            if (annotation.accessorMethod != nil)
            {
                children = [object performSelector:annotation.accessorMethod];
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
                [self throwException:e];
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
                              withObject:object
                             withContext:context];
    BOOL checkIsNew = NO;
    if (newItem == nil)
    {
        newItem = [self newObjectForEntity:_entityName withContext:context];
        checkIsNew = YES;
    }
    
    SyncModelSerializer *serializer = [[SyncModelSerializer alloc] initWithModelClass:NSClassFromString(_entityName)
                                                                      withAnnotations:_annotations];
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
            NSString *parentAttributeClass = [SerializationUtil propertyClassNameFor:parentAttributeName onObject:newItem];
            NSObject *parentId = [object valueForKey:[_parentAttributes valueForKey:parentAttributeName]];
            
            SyncEntity *parent = [self findParent:parentAttributeClass withParentId:parentId withContext:context];
            if (parent == nil && [parentId isEqual:@"nil"])
            {
                NSString *reason = [NSString stringWithFormat:@"An item of class %@ with id server %@ was not found for item of class %@ with id_server %@", parentAttributeClass, parentId, _entityName, newItem.idServer];
                @throw [NSException exceptionWithName:@"AbstractSyncManagerException"
                                               reason:reason
                                             userInfo:nil];
            }
            
            [newItem setValue:parent forKey:parentAttributeName];
        }
    }
    
    if ([_childrenAttributes count] > 0)
    {
        for (NSString *childrenAttributeName in [_childrenAttributes allKeys])
        {
            JSON *jsonAttribute = [_annotations annotationForAttribute:childrenAttributeName];
            NSString *jsonName = [SerializationUtil getAttributeName:childrenAttributeName withAnnotation:jsonAttribute];
            NSArray *children = [object objectForKey:jsonName];
            
            NestedManager *annotation = [self getNestedManagerForAttribute:childrenAttributeName];
            id<SyncManager> nestedSyncManager = [self syncManagerForNestedManager:annotation];
            NSDictionary *childParams = nil;
            
            if (![annotation.paginationParams isEqualToString:@""])
            {
                childParams = [object objectForKey:annotation.paginationParams];
            }
            else
            {
                childParams = [[NSDictionary alloc] init];
            }
            
            NSArray *newChildren = [nestedSyncManager saveNewData:children
                                                     withDeviceId:deviceId
                                                   withParameters:childParams
                                                      withContext:context];
            
            if (annotation.discardOnSave && !checkIsNew)
            {
                [self deleteMissingChildrenFromEntity:annotation.entityName
                              withParentAttribute:annotation.attributeName
                                       withParent:newItem
                                      withContext:context
                                   withNewObjects:newChildren];
            }
            
            [_dataSyncHelper addToEventQueue:[nestedSyncManager getIdentifier] withObjects:newChildren];
        }
        
    }
    
    return newItem;
}

- (void)saveBooleanPref:(NSString *)key withValue:(BOOL)value
{
    NSString *prefKey = [NSString stringWithFormat:@"%@.%@", _entityName, key];
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:value] forKey:prefKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)booleanPref:(NSString *)key
{
    NSNumber *pref = [[NSUserDefaults standardUserDefaults] valueForKey:key];
    return [pref boolValue];
}

- (BOOL)booleanPref:(NSString *)key withDefaultValue:(BOOL)defaultValue
{
    NSString *fullKey = [NSString stringWithFormat:@"%@.%@", _entityName, key];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:fullKey] == nil) {
        return defaultValue;
    } else {
        return [self booleanPref:fullKey];
    }
}

- (NSManagedObject *)getOldestFromContext:(NSManagedObjectContext *)context
{
    if (_dateAttribute == nil)
    {
        return nil;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:_entityName];
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:_dateAttribute ascending:YES];
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
             withContext:(NSManagedObjectContext *)context
{
    return [self findItem:idServer
             withIdClient:idClient
             withDeviceId:deviceId
         withItemDeviceId:itemDeviceId
       withIgnoreDeviceId:NO
               withObject:nil
              withContext:context];
    
}

- (SyncEntity *)findItem:(NSNumber *)idServer
            withIdClient:(NSString *)idClient
            withDeviceId:(NSString *)deviceId
        withItemDeviceId:(NSString *)itemDeviceId
      withIgnoreDeviceId:(BOOL)ignoreDeviceId
             withContext:(NSManagedObjectContext *)context
{
    return [self findItem:idServer
             withIdClient:idClient
             withDeviceId:deviceId
         withItemDeviceId:itemDeviceId
       withIgnoreDeviceId:ignoreDeviceId
               withObject:nil
              withContext:context];
}

- (SyncEntity *)findItem:(NSNumber *)idServer
            withIdClient:(NSString *)idClient
            withDeviceId:(NSString *)deviceId
        withItemDeviceId:(NSString *)itemDeviceId
              withObject:(NSDictionary *)object
             withContext:(NSManagedObjectContext *)context
{
    return [self findItem:idServer
             withIdClient:idClient
             withDeviceId:deviceId
         withItemDeviceId:itemDeviceId
       withIgnoreDeviceId:NO
               withObject:object
              withContext:context];
}

- (SyncEntity *)findItem:(NSNumber *)idServer
            withIdClient:(NSString *)idClient
            withDeviceId:(NSString *)deviceId
        withItemDeviceId:(NSString *)itemDeviceId
      withIgnoreDeviceId:(BOOL)ignoreDeviceId
              withObject:(NSDictionary *)object
             withContext:(NSManagedObjectContext *)context
{
    NSArray *objectList = nil;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:_entityName];

    if ((ignoreDeviceId || [deviceId isEqualToString:itemDeviceId]) && idClient != nil && ![idClient isKindOfClass:[NSNull class]])
    {
        NSURL *objUrl = [NSURL URLWithString:idClient];
        NSManagedObjectID *objectID = [[context persistentStoreCoordinator] managedObjectIDForURIRepresentation:objUrl];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"idServer==%@ OR SELF==%@", idServer, objectID]];
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

- (SyncEntity *)findParent:(NSString *)parentEntity withParentId:(NSObject *)parentId withContext:(NSManagedObjectContext *)context
{
    if (parentId == nil || [parentId isKindOfClass:[NSNull class]])
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

- (id)newObjectForEntity:(NSString *)entityName withContext:(NSManagedObjectContext *)context
{
    return [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:context];
}

- (NSEntityDescription *)entityDescriptionForName:(NSString *)entityName
                                      withContext:(NSManagedObjectContext *)context
{
    return [NSEntityDescription entityForName:entityName
                       inManagedObjectContext:context];
}

- (NSArray *)deleteAllWithContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:_entityName];
    [fetchRequest setIncludesPropertyValues:NO];
    NSArray *deletedObjects = [context executeFetchRequest:fetchRequest error:nil];
    
    for (NSManagedObject *obj in deletedObjects)
    {
        [context deleteObject:obj];
    }
    
    return deletedObjects;
}

- (NSArray *)listAllWithContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:_entityName];
    NSArray *allObjects = [context executeFetchRequest:fetchRequest error:nil];
    
    return allObjects;
}

- (void)deleteMissingChildrenFromEntity:(NSString *)entity
                withParentAttribute:(NSString *)parentAttribute
                         withParent:(NSManagedObject *)parent
                        withContext:(NSManagedObjectContext *)context
                     withNewObjects:(NSArray *)newObjects
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entity];
    [fetchRequest setIncludesPropertyValues:NO];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"%K==%@ AND NOT (self IN %@)", parentAttribute, parent, newObjects]];
    
    NSArray *deletedObjects = [context executeFetchRequest:fetchRequest error:nil];
    
    for (NSManagedObject *obj in deletedObjects)
    {
        [context deleteObject:obj];
    }
}

- (BOOL)moreOnServer
{
    return [self moreOnServerWithPaginationIdentifier:nil];
}

- (BOOL)moreOnServerWithPaginationIdentifier:(NSString *)paginationIdentifier
{
    if (paginationIdentifier == nil || [paginationIdentifier isEqualToString:@""])
    {
        paginationIdentifier = @"";
    }
    else if (![paginationIdentifier hasPrefix:@"."])
    {
        paginationIdentifier = [NSString stringWithFormat:@".%@", paginationIdentifier];
    }
    
    return [self booleanPref:[NSString stringWithFormat:@"%@.more%@", _entityName, paginationIdentifier]];
}

- (void)throwException:(NSException *)exception
{
    NSString *msg = [NSString stringWithFormat:@"%@. While processing SyncManager with identifier %@.", exception.reason, [self getIdentifier]];
    @throw [NSException exceptionWithName:exception.name
                                   reason:msg
                                 userInfo:exception.userInfo];
}

@end
