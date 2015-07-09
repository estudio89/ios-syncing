//
//  Annotations.h
//  Syncing
//
//  Created by Rodrigo Suhr on 7/9/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Syncing.h"

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
@property (strong, readonly) NSString *name;

- (instancetype)initWithAnnotation:(NSDictionary *)annotation;

@end

@interface NestedManager : NSObject

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
@property (strong, readonly) NSManagedObjectContext *context;

- (instancetype)initWithAnnotation:(NSDictionary *)annotation withContext:(NSManagedObjectContext *)context;
- (BOOL)shouldPaginate;

@end
