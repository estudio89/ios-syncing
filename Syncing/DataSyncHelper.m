//
//  DataSyncHelper.m
//  Syncing
//
//  Created by Rodrigo Suhr on 2/20/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "DataSyncHelper.h"

@interface DataSyncHelper()

@property (nonatomic, strong, readwrite) ServerComm *serverComm;

@end

@implementation DataSyncHelper

- (instancetype)initWithServer:(ServerComm *)serverComm
{
    self = [super init];
    if (self)
    {
        self.serverComm = serverComm;
    }
    return self;
}

- (instancetype)init
{
    return [self initWithServer:[[ServerComm alloc] init]];
}

@end
