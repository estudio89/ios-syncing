//
//  SyncManager.h
//  Syncing
//
//  Created by Rodrigo Suhr on 2/12/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsyncBus.h"

@protocol SyncManager <NSObject>

- (NSString *)getIdentifier;
- (NSString *)getResponseIdentifier;
- (BOOL)shouldSendSingleObject;
- (NSMutableArray *)getModifiedData;
- (BOOL)hasModifiedData;
- (NSMutableArray *)getModifiedFiles;
- (NSMutableArray *)getModifiedFilesForObject:(NSDictionary *)object;
- (NSMutableArray *)saveNewData:(NSArray *)jsonObjects withDeviceId:(NSString *)deviceId;
- (void)processSendResponse:(NSArray *)jsonResponse;
- (NSDictionary *)serializeObject:(NSObject *)object;
- (id)saveObject:(NSDictionary *)object withDeviceId:(NSString *)deviceId;
- (void)postEvent:(NSArray *)objects withBus:(AsyncBus *)bus;
- (NSString *)getNotificationName;

@end
