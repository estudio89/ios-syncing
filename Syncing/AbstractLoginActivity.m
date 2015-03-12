//
//  AbstractLoginActivity.m
//  Syncing
//
//  Created by Rodrigo Suhr on 3/12/15.
//  Copyright (c) 2015 Estúdio 89 Desenvolvimento de Software. All rights reserved.
//

#import "AbstractLoginActivity.h"

@interface AbstractLoginActivity ()

@end

@implementation AbstractLoginActivity

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 * isForeground
 *
 * @return
 */
- (BOOL)isForeground
{
    return NO;
}

/**
 * submitLogin
 *
 * @param
 */
- (void)submitLogin:(NSString *)username withPasswd:(NSString *)password
{
    
}

/**
 * verifyCredentials
 *
 * @param
 * @return
 */
- (BOOL)verifyCredentials:(NSString *)username withPasswd:(NSString *)password
{
    return NO;
}

/**
 * onSuccessfulLogin
 *
 * @param
 */
- (void)onSuccessfulLogin:(SuccessfulLoginEvent *)event
{
    
}

/**
 * onSuccessfulLogin
 *
 */
- (void)onBacPressed
{
    
}

@end
