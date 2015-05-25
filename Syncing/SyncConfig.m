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

@interface SyncConfig()

@property (nonatomic, strong, readwrite) AsyncBus *bus;
@property (nonatomic, strong, readwrite) NSString *mConfigFile;
@property (nonatomic, strong, readwrite) NSMutableDictionary *syncManagersByIdentifier;
@property (nonatomic, strong, readwrite) NSMutableDictionary *syncManagersByResponseIdentifier;
@property (nonatomic, strong, readwrite) NSString *mGetDataUrl;
@property (nonatomic, strong, readwrite) NSString *mSendDataUrl;
@property (nonatomic, strong, readwrite) NSString *mAuthenticateUrl;
@property (nonatomic, strong, readwrite) NSMutableDictionary *mModelGetDataUrls;

@end

@implementation SyncConfig

static NSString *loginActivity;

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
- (instancetype)initWithBus:(AsyncBus *)bus;
{
    if (self = [super init])
    {
        _bus = bus;
        _syncManagersByIdentifier = [[NSMutableDictionary alloc] init];
        _syncManagersByResponseIdentifier = [[NSMutableDictionary alloc] init];
        _mModelGetDataUrls = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

/**
 * setConfigFile
 */
- (void)setConfigFile:(NSString *)filename
{
    _mConfigFile = filename;
    [self loadSettings];
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
        
        _mGetDataUrl = [jsonConfig valueForKey:@"getDataUrl"];
        _mSendDataUrl = [jsonConfig valueForKey:@"sendDataUrl"];
        _mAuthenticateUrl = [jsonConfig valueForKey:@"authenticateUrl"];
        loginActivity = [jsonConfig valueForKey:@"loginActivity"];
        
        id<SyncManager> syncManager;
        Class klass;
        NSString *getDataUrl = @"";
        NSString *identifier = @"";
        NSString *responseIdentifier = @"";
        
        NSArray *syncManagersJson = [jsonConfig objectForKey:@"syncManagers"];
        for (NSDictionary *syncManagerJson in syncManagersJson)
        {
            klass = NSClassFromString([syncManagerJson valueForKey:@"class"]);
            syncManager = [[klass alloc] init];
            getDataUrl = [syncManagerJson valueForKey:@"getDataUrl"];
            identifier = [syncManager getIdentifier];
            responseIdentifier = [syncManager getResponseIdentifier];
            [self.syncManagersByIdentifier setObject:syncManager forKey:identifier];
            [self.syncManagersByResponseIdentifier setObject:syncManager forKey:responseIdentifier];
            [self.mModelGetDataUrls setObject:getDataUrl forKey:identifier];
        }
    }
    @catch (NSException *e)
    {
        @throw e;
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
 * logout
 */
- (void)logout
{
    [self eraseSyncPreferences];
    [[DataSyncHelper getInstance] stopSyncThreads];
    DatabaseProvider *dp = [self getDatabase];
    [dp flushDatabase];
    [_bus post:[[UserLoggedOutEvent alloc] init] withNotificationName:@"UserLoggedOutEvent"];
    NSLog(@"UserLoggedOutEvent event was posted.");
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
        authtoken = storedAuthtoken;
    
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
 * getTimestamp
 */
- (NSString *)getTimestamp
{
    NSString *timestamp = @"";
    NSString *storedTimestamp = [[NSUserDefaults standardUserDefaults] stringForKey:@"E89.iOS.Syncing-Timestamp"];
    
    if ([storedTimestamp length] > 0)
        timestamp = storedTimestamp;
    
    return timestamp;
}

/**
 * setTimestamp
 */
- (void)setTimestamp:(NSString *)timestamp
{
    [[NSUserDefaults standardUserDefaults] setValue:timestamp forKey:@"E89.iOS.Syncing-Timestamp"];
    [[NSUserDefaults standardUserDefaults] synchronize];
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
    NSString *url = [self.mModelGetDataUrls valueForKey:identifier];
    
    if (url == nil)
    {
        @throw([NSException exceptionWithName:@"URL not found" reason:@"URL not found for the identifier." userInfo:nil]);
    }
    
    return url;
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
    return [self.syncManagersByIdentifier allValues];
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
 * getDatabase
 */
- (DatabaseProvider *)getDatabase
{
    return [[DatabaseProvider alloc] init];
}

@end

@implementation UserLoggedOutEvent

@end
