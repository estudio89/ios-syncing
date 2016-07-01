//
//  SyncingInjection.h
//  Syncing
//
//  Created by Rodrigo Suhr on 5/4/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface SyncingInjection : NSObject

+ (void)initWithContext:(NSManagedObjectContext *)context
         withConfigFile:(NSString *)fileName
            withBaseUrl:(NSString *)baseUrl;
+ (void)initWithContext:(NSManagedObjectContext *)context
         withConfigFile:(NSString *)fileName
            withBaseUrl:(NSString *)baseUrl
        withInitialSync:(BOOL)initialSync;
+ (void)executeInjectionWithContext:(NSManagedObjectContext *)context;
+ (id)get:(Class)class;
+ (NSString *)library_version;

@end
