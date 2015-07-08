//
//  SerializationUtil.h
//  Syncing
//
//  Created by Rodrigo Suhr on 7/7/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface SerializationUtil : NSObject

+ (NSString *)getAttributeName:(NSAttributeDescription *)attribute withAnnotation:(NSDictionary *)annotation;
+ (NSDate *)parseServerDate:(NSString *)strDate;
+ (NSString *)formatServerDate:(NSDate *)date;

@end
