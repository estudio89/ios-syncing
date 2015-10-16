//
//  GzipUtil.h
//  Syncing
//
//  Created by Rodrigo Suhr on 10/15/15.
//  Copyright © 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GzipUtil : NSObject

+ (NSData *)gzippedData:(NSData *)unzippedData;
+ (NSData *)gunzippedData:(NSData *)zippedData;

@end
