//
//  SyncConfig.h
//  Syncing
//
//  Created by Rodrigo Suhr on 2/22/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SyncConfig : NSObject

- (NSString *)getAuthToken;
- (NSString *)getTimestamp;
- (NSString *)getGetDataUrl;

@end
