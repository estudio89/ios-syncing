//
//  AbstractSyncManager.h
//  Syncing
//
//  Created by Rodrigo Suhr on 7/7/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SyncManager.h"

@class Annotations;

@interface AbstractSyncManager : NSObject<SyncManager>

@property (strong, nonatomic, readonly) Annotations *annotations;
@property (strong, nonatomic, readonly) NSAttributeDescription *dateAttribute;
@property (strong, nonatomic, readonly) NSMutableDictionary *parentAttributes;
@property (strong, nonatomic, readonly) NSMutableDictionary *childrenAttributes;
- (Annotations *)getAnnotations;

@end
