//
//  ServerComm.h
//  Syncing
//
//  Created by Rodrigo Suhr on 2/12/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SecurityUtil.h"

@interface ServerComm : NSObject

+ (ServerComm *)getInstance;
- (instancetype)initWithSecurityUtil:(SecurityUtil *)securityUtil withAppVersion:(NSString *)appVersion;
- (NSDictionary *)post:(NSString *)url withData:(NSDictionary *)data;
- (NSDictionary *)post:(NSString *)url withData:(NSDictionary *)data withFiles:(NSArray *)files;

@end
