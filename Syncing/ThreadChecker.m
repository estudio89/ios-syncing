//
//  ThreadChecker.m
//  Syncing
//
//  Created by Rodrigo Suhr on 2/11/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "ThreadChecker.h"

@interface ThreadChecker()

@property (strong, readwrite) NSMutableArray *threadIds;

@end

@implementation ThreadChecker

/**
 * Init
 */
- (id)init
{
    if(self = [super init])
    {
        self.threadIds = [[NSMutableArray alloc] init];
    }
    
    return self;
}

/**
 * Generates a new identifier and add it to the threadIds array.
 * @return The new threadId.
 */
- (NSString *)setNewThreadId
{
    NSDateFormatter *dateFormater = [[NSDateFormatter alloc] init];
    [dateFormater setDateFormat:@"yyyyMMdd_HHmmssSSS"];
    NSString *threadId = [dateFormater stringFromDate:[NSDate date]];
    [self.threadIds addObject:threadId];
    return threadId;
}

/**
 * Checks if the threadIds array has the parameter threadId.
 * @param threadId The thread identifier.
 * @return YES if the threadIds array has the parameter threadId, otherwise NO.
 */
- (BOOL)isValidThreadId:(NSString *)threadId
{
    return [self.threadIds containsObject:threadId];
}

/**
 * Removes a threadId from threadIds array.
 * @param threadId The thread identifier.
 */
- (void)removeThreadId:(NSString *)threadId
{
    [self.threadIds removeObject:threadId];
}

/**
 * Clears the threadIds array.
 */
- (void)clear
{
    [self.threadIds removeAllObjects];
}

@end
