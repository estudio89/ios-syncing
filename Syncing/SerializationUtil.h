//
//  SerializationUtil.h
//  Syncing
//
//  Created by Rodrigo Suhr on 7/7/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <objc/runtime.h>
#import "Annotations.h"
#import "SyncEntity.h"

@interface SerializationUtil : NSObject

+ (NSString *)getAttributeName:(NSString *)attribute withAnnotation:(JSON *)annotation;
+ (NSDate *)parseServerDate:(NSString *)strDate;
+ (NSString *)formatServerDate:(NSDate *)date;
+ (NSString *)propertyClassNameFor:(objc_property_t)property;
+ (Class)propertyTypeFor:(objc_property_t)property;
+ (NSString *)propertyClassNameFor:(NSString *)propertyName onObject:(SyncEntity *)object;

@end
