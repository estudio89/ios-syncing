//
//  SharedObjectContext.h
//  Syncing
//
//  Created by Rodrigo Suhr on 7/10/17.
//  Copyright © 2017 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface SharedObjectContext : NSObject
    
+ (NSManagedObjectContext *)managedObjectContext;
    
@end

@interface E89MainManagedObjectContext : NSManagedObjectContext
@end
