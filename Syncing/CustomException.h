//
//  CustomException.h
//  Syncing
//
//  Created by Rodrigo Suhr on 2/27/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CustomException : NSException
@end

@interface InvalidThreadIdException : CustomException
@end

@interface TimeoutException : CustomException
@end

@interface ConnectionErrorException : CustomException
@end

@interface HttpException : CustomException
@end

@interface Http403Exception : HttpException
@end

@interface Http408Exception : HttpException
@end

@interface Http500Exception : HttpException
@end

@interface Http502Exception : HttpException
@end

@interface Http503Exception : HttpException
@end

@interface Http504Exception : HttpException
@end