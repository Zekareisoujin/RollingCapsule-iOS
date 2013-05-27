//
//  ViewController.m
//  Rolling Capsule
//
//  Created by Nguyen Phi Long Louis on 23/05/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#include "Constants.h"

#import "LoginViewController.h"
#import "SBJson.h"
#import "RegisterViewController.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) alertStatus:(NSString *)msg :(NSString *)title
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:msg
                                                       delegate:self
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil, nil];
    
    [alertView show];
}

- (IBAction)btnLogInClick:(id)sender {
    //Synchronous Request
    @try {
        
        if([[_txtFieldUsername text] isEqualToString:@""] || [[_txtFieldPassword text] isEqualToString:@""] ) {
            [self alertStatus:@"Please enter both Username and Password" :@"Login Failed!"];
        } else {
            /*NSMutableDictionary *postDataJson = [[NSMutableDictionary alloc] init];
            [postDataJson setObject:[_txtFieldUsername text] forKey:@"session[email]"];
            [postDataJson setObject:[_txtFieldPassword text] forKey:@"session[password]"];
            [postDataJson setObject:@"1" forKey:@"mobile"];
            
                        
             NSData *postData = [NSJSONSerialization dataWithJSONObject:postDataJson
                                                                options:0
                                                                  error:nil];*/
            
            NSLog(@"email: %@ password:%@",[_txtFieldUsername text],[_txtFieldPassword text]);
            NSString *post =[[NSString alloc] initWithFormat:@"session[email]=%@&session[password]=%@&mobile=1",[_txtFieldUsername text],[_txtFieldPassword text]];
            NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
            
            NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@", RCServiceURL, RCSessionsResource]];
            
            NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
            
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
            request.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
            [request setURL:url];
            [request setHTTPMethod:@"POST"];
            [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
            //[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
            [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
            [request setHTTPBody:postData];

            
            //[NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:[url host]];
            
            NSError *error = [[NSError alloc] init];
            NSHTTPURLResponse *response = nil;
            NSData *urlData=[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            
            NSLog(@"Response code: %d", [response statusCode]);
            if ([response statusCode] >=200 && [response statusCode] <300)
            {
                NSString *responseData = [[NSString alloc]initWithData:urlData encoding:NSUTF8StringEncoding];
                NSLog(@"Response ==> %@", responseData);
                
                SBJsonParser *jsonParser = [SBJsonParser new];
                NSDictionary *jsonData = (NSDictionary *) [jsonParser objectWithString:responseData error:nil];
                NSLog(@"%@",jsonData);
                
                NSDictionary *userData = (NSDictionary *) [jsonData objectForKey: @"user"];
                NSString *name = (NSString *) [userData objectForKey:@"name"];
                [self alertStatus:[NSString stringWithFormat:@"Welcome, %@!",name] :@"Login Success!"];
        
            } else {
                //if (error) NSLog(@"Error: %@", error);
                [self alertStatus:@"Connection Failed" :@"Login Failed!"];
            }
            
        }
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        [self alertStatus:@"Login Failed." :@"Login Failed!"];
    }

}

- (IBAction)btnRegisterClick:(id)sender {
    RegisterViewController *registerViewController = [[RegisterViewController alloc]
                                                      initWithNibName:@"RegisterViewController"
                                                      bundle:nil];
    //[(UINavigationController *)self.presentingViewController pu]
    [self.navigationController pushViewController:registerViewController animated:NO];
    //[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)btnBackgroundTap:(id)sender {
    [_txtFieldUsername resignFirstResponder];
    [_txtFieldPassword resignFirstResponder];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}
@end
