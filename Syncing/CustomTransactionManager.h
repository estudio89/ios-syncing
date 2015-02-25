//
//  CustomTransactionManager.h
//  Syncing
//
//  Created by Rodrigo Suhr on 2/25/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SyncConfig.h"

@interface CustomTransactionManager : NSObject

- (void)doInTransaction:(void(^)(void))manipulateInTransaction withSyncConfig:(SyncConfig *)syncConfig;
- (BOOL)wasSuccessful;

@end
