//
//  ServerComm.m
//  Syncing
//
//  Created by Rodrigo Suhr on 2/12/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "ServerComm.h"
#import "CustomException.h"

@interface ServerComm ()

@property (nonatomic, strong, readwrite) SecurityUtil *securityUtil;

@end

@implementation ServerComm

/**
 * initWithSecurityUtil
 */
- (instancetype)initWithSecurityUtil:(SecurityUtil *)securityUtil
{
    self = [super init];
    if (self)
    {
        _securityUtil = securityUtil;
    }
    return self;
}

/**
 * post
 */
- (NSDictionary *)post:(NSString *)url withData:(NSDictionary *)data
{
    return [self post:url withData:data withFiles:nil];
}

/**
 * post
 */
- (NSDictionary *)post:(NSString *)url withData:(NSDictionary *)data withFiles:(NSArray *)files
{
    NSError *error = nil;
    NSString *boundary = @"--iOSSyncingEstudio89";
    
    //request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setAllowsCellularAccess:YES];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setHTTPShouldHandleCookies:NO];
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    //request data
    NSMutableData *postData = [NSMutableData data];
    
    //if the request has files
    if (files != nil && [files count] > 0)
    {
        NSData *imageData = nil;
        NSString *fileName = nil;
        
        for (NSDictionary *image in files)
        {
            imageData = [image objectForKey:@"image"];
            fileName = [image valueForKey:@"filename"];
            
            [postData appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [postData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", fileName, fileName] dataUsingEncoding:NSUTF8StringEncoding]];
            [postData appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            [postData appendData:imageData];
            [postData appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }
    
    //add the JSON to request
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&error];
    [postData appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[@"Content-Disposition: form-data; name=\"json\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    //encrypt
    NSData *encryptedData = [_securityUtil encryptMessage:[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
    [postData appendData:encryptedData];
    [postData appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    //add the last boudary
    [postData appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    //request body
    [request setHTTPBody:postData];
    
    //timeout (5 minutes)
    [request setTimeoutInterval:300];
    
    //post size
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    NSHTTPURLResponse *requestResponse;
    NSData *requestHandler = [NSURLConnection sendSynchronousRequest:request returningResponse:&requestResponse error:&error];
    
    if (error)
    {
        @throw([HttpException exceptionWithName:@"Http error" reason:@"The http request returned an error." userInfo:nil]);
    }
    else if ([requestResponse statusCode] == 408)
    {
        @throw([Http408Exception exceptionWithName:@"Http request timeout" reason:@"The http request timed out." userInfo:nil]);
    }
    else if ([requestResponse statusCode] == 403)
    {
        @throw([Http403Exception exceptionWithName:@"Http request forbiden" reason:@"The server is refusing to respond." userInfo:nil]);
    }
    else if ([requestResponse statusCode] == 500)
    {
        @throw([Http500Exception exceptionWithName:@"Http internal server error" reason:@"An error occurred on the server." userInfo:nil]);
    }
    
    NSString *ct = [requestResponse.allHeaderFields valueForKey:@"Content-Type"];
    if ([ct rangeOfString:@"application/json"].location == NSNotFound)
    {
        @throw([Http403Exception exceptionWithName:@"Http request forbiden" reason:@"The server is refusing to respond." userInfo:nil]);
    }
    
    NSString *requestReply = [[NSString alloc] initWithBytes:[requestHandler bytes] length:[requestHandler length] encoding:NSISOLatin1StringEncoding];
    
    //decrypt
    requestReply = [_securityUtil decryptMessage:requestReply];
    NSData *dataReply = [requestReply dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSDictionary *jsonReply = [NSJSONSerialization JSONObjectWithData:dataReply options:kNilOptions error:&error];
    
    return jsonReply;
}

@end