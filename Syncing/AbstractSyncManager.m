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

@interface AbstractSyncManager ()

//@property (strong, nonatomic) NSDictionary *annotation;
//@property (strong, nonatomic) NSDictionary *attributesAnnotation;
//@property (strong, nonatomic) NSDictionary *nestedManagersAnnotation;

//@property (strong, nonatomic) Annotations *annotations;
@property (strong, nonatomic) NSMutableDictionary *parentAttributes;
@property (strong, nonatomic) NSMutableDictionary *childrenAttributes;
@property BOOL shouldPaginate;
@property (strong, nonatomic) NSString *entityName;
@property (strong, nonatomic) NSAttributeDescription *dateAttribute;
@property (strong, nonatomic) NSString *paginationIdentifier;
@property (strong, nonatomic) NSManagedObject *oldestInCache;

@end

@implementation AbstractSyncManager
/*
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
    
    for (NSAttributeDescription *attribute in [attributes allValues])
    {
        if (_shouldPaginate && [attribute attributeType] == NSDateAttributeType)
        {
            if ([paginateField isEqualToString:@""] || [paginateField isEqualToString:attribute.name])
            {
                _dateAttribute = attribute;
            }
        }
        //FIXME
        else if (![[attributeAnnotation objectForKey:@"ignore"] boolValue])
        {
            NSString *parentAttributeName = [SerializationUtil getAttributeName:attribute
                                                                 withAnnotation:attributeAnnotation];
            [_parentAttributes setObject:attribute forKey:parentAttributeName];
        }
        else if (_nestedManagersAnnotation && [_nestedManagersAnnotation objectForKey:attribute.name])
        {
            NSDictionary *nestedManager = [_nestedManagersAnnotation objectForKey:attribute.name];
            [_childrenAttributes setObject:[self getNestedSyncManager:[nestedManager valueForKey:@"manager"]]
                                    forKey:attribute.name];
        }
    }
}

- (id<SyncManager>)getNestedSyncManager:(NSString *)className
{
    return [[NSClassFromString(className) alloc] init];
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
                NSDictionary *attributeAnnotation = [_attributesAnnotation objectForKey:_dateAttribute];
                NSString *jsonAttribute = [SerializationUtil getAttributeName:_dateAttribute withAnnotation:attributeAnnotation];
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
                                                             withAnnotation:_attributesAnnotation
                                                                withContext:context];
    
    [serializer toJSON:(NSManagedObject *)object withJSON:[[NSDictionary alloc] init]];
    
    if ([_parentAttributes count] > 0)
    {
        for (NSString *attributeName in [_parentAttributes allKeys])
        {
            [jsonObject setValue:[object valueForKey:@"idServer"] forKey:attributeName];
        }
    }
    
    for (NSString *childAttName in [_nestedManagersAnnotation allKeys])
    {
        NSDictionary *childrenAnnotation = [_nestedManagersAnnotation objectForKey:childAttName];
        
        if ([[childrenAnnotation objectForKey:@"writable"] boolValue])
        {
            NSString *accessorMethod = [childrenAnnotation valueForKey:@"accessorMethod"];
            if (![accessorMethod isEqualToString:@""])
            {
                
            }
        }
    }
    
    Message *message = (Message *)object;
    Conversation *conversation = message.conversation;
    NSMutableDictionary *jsonDict = [[NSMutableDictionary alloc] init];
    
    @try
    {
        [jsonDict setObject:[message.objectID.URIRepresentation absoluteString] forKey:@"idClient"];
        [jsonDict setObject:conversation.idServer forKey:@"conversation_id"];
        [jsonDict setObject:message.content forKey:@"content"];
        [jsonDict setObject:[TimeUtil formatServerDate:message.date] forKey:@"date"];
        [jsonDict setObject:message.isAnonymous forKey:@"isAnonymous"];
    }
    @catch (NSException *e)
    {
        [CrashReportUtil reportException:e withMethod:__FUNCTION__ withFile:__FILE__ atLine:__LINE__ sendNow:YES];
    }
    
    return jsonDict;
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
*/
@end
