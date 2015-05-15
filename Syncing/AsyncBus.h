//
//  AsyncBus.h
//  Syncing
//
//  Created by Rodrigo Suhr on 2/26/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AsyncBus : NSObject

- (void)post:(id)object withNotificationName:(NSString *)notification;
- (void)subscribe:(id)observer withSelector:(SEL)selector withNotificationName:(NSString *)notification withObject:(id)object;
- (void)unsubscribe:(id)observer withNotificationName:(NSString *)notification withObject:(id)object;

@end	
