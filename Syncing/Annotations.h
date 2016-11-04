//
//  Annotations.h
//  Syncing
//
//  Created by Rodrigo Suhr on 7/9/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SyncManager.h"

@interface Paginate : NSObject

@property (strong, readonly) NSString *byField;
@property (strong, readonly) NSString *extraIdentifier;

- (instancetype)initWithAnnotation:(NSDictionary *)annotation;

@end

@interface JSON : NSObject

@property (strong, readonly) NSString *ignoreIf;
@property BOOL ignore;
@property BOOL writable;
@property BOOL readable;
@property BOOL allowOverwrite;
@property (strong, readonly) NSString *name;

- (instancetype)initWithAnnotation:(NSDictionary *)annotation;

@end

@interface NestedManager : NSObject

@property (strong, readonly) NSString *entityName;
@property (strong, readonly) NSString *attributeName;
@property (strong, readonly) id<SyncManager> manager;
@property BOOL writable;
@property SEL accessorMethod;
@property BOOL discardOnSave;
@property (strong, readonly) NSString *paginationParams;

- (instancetype)initWithAnnotation:(NSDictionary *)annotation;

@end

@interface Annotations : NSObject

@property (strong, readonly) Paginate *paginate;
@property (strong, readonly) NSString *entityName;

- (instancetype)initWithAnnotation:(NSDictionary *)annotation;
- (void)mergeWith:(NSDictionary *)annotation;
- (JSON *)annotationForAttribute:(NSString *)attribute;
- (NestedManager *)nestedManagerForAttribute:(NSString *)attribute;
- (BOOL)hasNestedManagerForAttribute:(NSString *)attribute;
- (BOOL)shouldPaginate;

@end
