//
//  SyncConfig.m
//  Syncing
//
//  Created by Rodrigo Suhr on 2/22/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "SyncConfig.h"
#import "SyncingInjection.h"
#import "DataSyncHelper.h"
#import "DatabaseProvider.h"
#import "E89ManagedObjectContext.h"

@interface SyncConfig()

@property (nonatomic, strong, readwrite) AsyncBus *bus;
@property (nonatomic, strong) DataSyncHelper *dataSyncHelper;
@property (nonatomic, strong, readwrite) NSString *mConfigFile;
@property (nonatomic, strong, readwrite) NSMutableDictionary *syncManagersByIdentifier;
@property (nonatomic, strong, readwrite) NSMutableDictionary *syncManagersByResponseIdentifier;
@property (nonatomic, strong, readwrite) NSString *baseUrl;
@property (nonatomic, strong, readwrite) NSString *mGetDataUrl;
@property (nonatomic, strong, readwrite) NSString *mSendDataUrl;
@property (nonatomic, strong, readwrite) NSString *mAuthenticateUrl;
@property (nonatomic, strong, readwrite) NSString *mEncryptionPassword;
@property BOOL mEncryptionActive;
@property (nonatomic, strong) NSMutableArray *identifiersArray;

@end

@implementation SyncConfig

static NSString *loginActivity;
static NSString *GET_DATA_URL_SUFFIX = @"syncing/get-data-from-server/";
static NSString *SEND_DATA_URL_SUFFIX = @"syncing/send-data-to-server/";
static NSString *AUTHENTICATION_URL_SUFFIX = @"syncing/authenticate/";

/**
 * getInstance
 */
+ (SyncConfig *)getInstance
{
    return [SyncingInjection get:[SyncConfig class]];
}

/**
 * initWithBus
 */
- (instancetype)initWithBus:(AsyncBus *)bus withContext:(NSManagedObjectContext *)context
{
    if (self = [super init])
    {
        _bus = bus;
        _context = context;
        _syncManagersByIdentifier = [[NSMutableDictionary alloc] init];
        _syncManagersByResponseIdentifier = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

/**
 * setConfigFile
 */
- (void)setConfigFile:(NSString *)filename withBaseUrl:(NSString *)baseUrl
{
    _mConfigFile = filename;
    _baseUrl = baseUrl;
    if (![baseUrl hasSuffix:@"/"]) {
        _baseUrl = [NSString stringWithFormat:@"%@/", baseUrl];
    }
    [self loadSettings];
    [self loadDefaultSyncManagers];
}

- (void)setDataSyncHelper:(DataSyncHelper *)dataSyncHelper
{
    _dataSyncHelper = dataSyncHelper;
}

/**
 * loadSettings
 */
- (void)loadSettings
{
    @try
    {
        NSString *jsonStr = [[NSString alloc] initWithContentsOfFile:_mConfigFile encoding:NSUTF8StringEncoding error:nil];
        NSData *data = [jsonStr dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        NSDictionary *jsonConfig = [jsonData objectForKey:@"syncing"];
        
        _mGetDataUrl = [NSString stringWithFormat:@"%@%@", _baseUrl, GET_DATA_URL_SUFFIX];
        _mSendDataUrl = [NSString stringWithFormat:@"%@%@", _baseUrl, SEND_DATA_URL_SUFFIX];
        _mAuthenticateUrl = [NSString stringWithFormat:@"%@%@", _baseUrl, AUTHENTICATION_URL_SUFFIX];
        loginActivity = [jsonConfig valueForKey:@"loginActivity"];
        _mEncryptionPassword = [jsonConfig valueForKey:@"encryptionPassword"];
        if ([[jsonConfig valueForKey:@"encryptionActive"] boolValue])
        {
            _mEncryptionActive = YES;
        }
        else
        {
            _mEncryptionActive = NO;
        }
        
        id<SyncManager> syncManager;
        Class klass;
        NSString *identifier = @"";
        NSString *responseIdentifier = @"";
        
        NSArray *syncManagersJson = [jsonConfig objectForKey:@"syncManagers"];
        _identifiersArray = [[NSMutableArray alloc] init];
        for (NSDictionary *syncManagerJson in syncManagersJson)
        {
            klass = NSClassFromString([syncManagerJson valueForKey:@"class"]);
            syncManager = [[klass alloc] init];
            [syncManager setDataSyncHelper:_dataSyncHelper];
            identifier = [syncManager getIdentifier];
            [_identifiersArray addObject:identifier];
            responseIdentifier = [syncManager getResponseIdentifier];
            [self.syncManagersByIdentifier setObject:syncManager forKey:identifier];
            [self.syncManagersByResponseIdentifier setObject:syncManager forKey:responseIdentifier];
        }
    }
    @catch (NSException *e)
    {
        @throw e;
    }
}

- (void)loadDefaultSyncManagers {
    NSArray *syncManagerClasses = @[@"SyncManagerLogout"];
    id<SyncManager> syncManager;
    Class klass;
    NSString *identifier = @"";
    NSString *responseIdentifier = @"";
    
    for (NSString *syncManagerClass in syncManagerClasses) {
        klass = NSClassFromString(syncManagerClass);
        syncManager = [[klass alloc] init];
        [syncManager setDataSyncHelper:_dataSyncHelper];
        identifier = [syncManager getIdentifier];
        [_identifiersArray addObject:identifier];
        responseIdentifier = [syncManager getResponseIdentifier];
        [self.syncManagersByIdentifier setObject:syncManager forKey:identifier];
        [self.syncManagersByResponseIdentifier setObject:syncManager forKey:responseIdentifier];
    }
}

/**
 * showLoginIfNeeded
 */
- (void)showLoginIfNeeded:(UIViewController *)initialVC
{
    if (![self userIsLoggedIn])
    {
        UIViewController *loginVC = [initialVC.storyboard instantiateViewControllerWithIdentifier:loginActivity];
        [initialVC.navigationController pushViewController:loginVC animated:NO];
    }
}

- (void)showLoginIfNeeded:(UIViewController *)initialVC withSegueID:(NSString *)segueID
{
    if (![self userIsLoggedIn])
    {
        [initialVC performSegueWithIdentifier:segueID sender:self];
    }
}

/**
 * userNeverSynced
 */
- (BOOL)userNeverSynced
{
    NSDictionary *timestamps = [self getTimestamps];
    for (NSString *timestamp in [timestamps allValues])
    {
        if (![timestamp isEqualToString:@""] && timestamp != nil) {
            return NO;
        }
    }
    
    return YES;
}

/**
 * logout
 */
- (void)logout
{
    [self logout:YES];
}

- (void)logout:(BOOL)postEvent
{
    [self eraseSyncPreferences];
    [[DataSyncHelper getInstance] stopSyncThreads];
    NSManagedObjectContext *context = [self getContext];
    [DatabaseProvider clearAllCoreDataEntitiesWithContext:context];
    [_context performBlock:^{
        NSError *error = nil;
        [_context save:&error];
    }];
    if (postEvent) {
        [_bus post:[[UserLoggedOutEvent alloc] init] withNotificationName:@"UserLoggedOutEvent"];
        NSLog(@"UserLoggedOutEvent event was posted.");
    }
}

/**
 * userIsLoggedIn
 */
- (BOOL)userIsLoggedIn
{
    BOOL isLogged = NO;
    NSString *storedAuthtoken = [self getAuthToken];
    if ([storedAuthtoken length] > 0)
    {
        isLogged = YES;
    }
    
    return isLogged;
}

/**
 * getAuthenticateUrl
 */
- (NSString *)getAuthenticateUrl
{
    return _mAuthenticateUrl;
}

/**
 * getAuthToken
 */
- (NSString *)getAuthToken
{
    NSString *authtoken = @"";
    NSString *storedAuthtoken = [[NSUserDefaults standardUserDefaults] stringForKey:@"E89.iOS.Syncing-AuthToken"];
    
    if ([storedAuthtoken length] > 0)
    {
        authtoken = storedAuthtoken;
    }
    
    return authtoken;
}

/**
 * setAuthToken
 */
- (void)setAuthToken:(NSString *)authToken
{
    [[NSUserDefaults standardUserDefaults] setValue:authToken forKey:@"E89.iOS.Syncing-AuthToken"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/**
 * getTimestamps
 */
- (NSDictionary *)getTimestamps
{
    NSMutableDictionary *timestampsObject = [[NSMutableDictionary alloc] init];
    NSDictionary *smTimestamp = nil;
    NSString *identifier = nil;
    
    for (id<SyncManager> syncManager in [self getSyncManagers])
    {
        identifier = [syncManager getIdentifier];
        smTimestamp = [self getTimestamp:identifier];
        [timestampsObject setObject:[smTimestamp valueForKey:identifier] forKey:identifier];
    }
    
    return timestampsObject;
}

/**
 * getTimestamps
 */
- (NSDictionary *)getTimestamp:(NSString *)identifier
{
    NSString *timestamp = @"";
    NSString *key = [NSString stringWithFormat:@"E89.iOS.Syncing-Timestamp-%@", identifier];
    NSString *storedTimestamp = [[NSUserDefaults standardUserDefaults] stringForKey:key];
    
    if ([storedTimestamp length] > 0)
    {
        timestamp = storedTimestamp;
    }

    return @{identifier:timestamp};
}

/**
 * setTimestamps
 */
- (void)setTimestamps:(NSDictionary *)timestamps
{
    NSString *timestamp = nil;
    NSString *timestampKey = nil;
    
    for (NSString *identifier in [timestamps allKeys])
    {
        timestamp = [timestamps valueForKey:identifier];
        timestampKey = [NSString stringWithFormat:@"E89.iOS.Syncing-Timestamp-%@", identifier];
        [[NSUserDefaults standardUserDefaults] setValue:timestamp forKey:timestampKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

/**
 * getUsername
 */
- (NSString *)getUsername
{
    NSString *username = @"";
    NSString *storedUsername = [[NSUserDefaults standardUserDefaults] stringForKey:@"E89.iOS.Syncing-Username"];
    
    if ([storedUsername length] > 0)
        username = storedUsername;
    
    return username;
}

/**
 * setUsername
 */
- (void)setUsername:(NSString *)username
{
    [[NSUserDefaults standardUserDefaults] setValue:username forKey:@"E89.iOS.Syncing-Username"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/**
 * eraseSyncPreferences
 */
- (void)eraseSyncPreferences
{
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
}

/**
 * getGetDataUrl
 */
- (NSString *)getGetDataUrl
{
    return self.mGetDataUrl;
}

/**
 * getGetDataUrlForModel
 */
- (NSString *)getGetDataUrlForModel:(NSString *)identifier
{
    return [NSString stringWithFormat:@"%@%@/", _mGetDataUrl, identifier];
}

/**
 * getDeviceId
 */
- (NSString *)getDeviceId
{
    NSString *deviceId = @"";
    NSString *storedDeviceId = [[NSUserDefaults standardUserDefaults] stringForKey:@"E89.iOS.Syncing-DeviceId"];
    
    if ([storedDeviceId length] > 0)
    {
        deviceId = storedDeviceId;
    }
    else
    {
        deviceId = [[NSUUID UUID] UUIDString];
        [self setDeviceId:deviceId];
    }
    
    return deviceId;
}

/**
 * setDeviceId
 */
- (void)setDeviceId:(NSString *)newId
{
    [[NSUserDefaults standardUserDefaults] setValue:newId forKey:@"E89.iOS.Syncing-DeviceId"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

/**
 * getSyncManagers
 */
- (NSArray *)getSyncManagers
{
    NSMutableArray *syncManagers = [[NSMutableArray alloc] init];
    for (NSString *identifier in _identifiersArray)
    {
        [syncManagers addObject:[_syncManagersByIdentifier objectForKey:identifier]];
    }
    
    return syncManagers;
}

/**
 * getSendDataUrl
 */
- (NSString *)getSendDataUrl
{
    return self.mSendDataUrl;
}

/**
 * getSyncManagerByResponseId
 */
- (id<SyncManager>)getSyncManagerByResponseId:(NSString *)responseId
{
    return [self.syncManagersByResponseIdentifier objectForKey:responseId];
}

/**
 * getSyncManager
 */
- (id<SyncManager>)getSyncManager:(NSString *)identifier
{
    return [self.syncManagersByIdentifier objectForKey:identifier];
}

/**
 * getEncryptionPassword
 */
- (NSString *)getEncryptionPassword
{
    return _mEncryptionPassword;
}

/**
 * isEncryptionActive
 */
- (BOOL)isEncryptionActive
{
    return _mEncryptionActive;
}

/**
 * isEncryptionActive
 */
- (void)requestSync
{
    // Should put a sync request in a queue.
    // When a connection is available (Reachability), the sync must be executed.
}

/**
 * getContext
 */
- (NSManagedObjectContext *)getContext
{
    E89ManagedObjectContext *managedObjectContext = [[E89ManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
    [managedObjectContext setParentContext:_context];
    [managedObjectContext setUndoManager:nil];

    return managedObjectContext;
}

@end

@implementation UserLoggedOutEvent

@end
