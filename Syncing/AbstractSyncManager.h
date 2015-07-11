//
//  AbstractSyncManager.h
//  Syncing
//
//  Created by Rodrigo Suhr on 7/7/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Syncing.h>

@interface AbstractSyncManager : NSObject<SyncManager>

- (instancetype)initWithAnnotation:(NSDictionary *)annotation;
- (Annotations *)getAnnotations;

@end
