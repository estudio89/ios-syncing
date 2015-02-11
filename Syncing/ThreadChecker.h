//
//  ThreadChecker.h
//  Syncing
//
//  Created by Rodrigo Suhr on 2/11/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ThreadChecker : NSObject

- (id)init;
- (NSString *)setNewThreadId;
- (BOOL)isValidThreadId:(NSString *)threadId;
- (void)removeThreadId:(NSString *)threadId;
- (void)clear;

@end
