//
//  ServerComm.m
//  Syncing
//
//  Created by Rodrigo Suhr on 2/12/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "ServerComm.h"

@implementation ServerComm

+ (id)getInstance
{
    return [self class];
}

- (NSDictionary *)post:(NSString *)url withData:(NSDictionary *)data
{
    return [self post:url withData:data withFiles:nil];
}

- (NSDictionary *)post:(NSString *)url withData:(NSDictionary *)data withFiles:(NSArray *)files
{
    return [[NSDictionary alloc] init];
}

@end