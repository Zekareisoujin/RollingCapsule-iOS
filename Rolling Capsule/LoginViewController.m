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
#import "Util.h"

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
    [self asynchLoginRequest];
}

- (void)asynchLoginRequest
{
    //Asynchronous Request
    @try {
        
        if([[_txtFieldUsername text] isEqualToString:@""] || [[_txtFieldPassword text] isEqualToString:@""] ) {
            [self alertStatus:@"Please enter both Username and Password" :@"Login Failed!"];
        } else {
            NSString *post =[[NSString alloc] initWithFormat:@"session[email]=%@&session[password]=%@&mobile=1",[_txtFieldUsername text],[_txtFieldPassword text]];
            NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
            
            NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@", RCServiceURL, RCSessionsResource]];
            
            NSURLRequest *request = CreateHttpPostRequest(url, postData);
            
            NSURLConnection *connection = [[NSURLConnection alloc]
                                                   initWithRequest:request
                                                   delegate:self
                                                   startImmediately:YES];
            _receivedData = [[NSMutableData alloc] init];
            
            if(!connection) {
                NSLog(@"Login Connection Failed.");
            } else {
                NSLog(@"Login Connection Succeeded.");
            }
            
        }
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        [self alertStatus:@"Login Failed." :@"Login Failed!"];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
 	//NSLog(@"Received response: %@", response);
 	
    [_receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
 	//NSLog(@"Received %d bytes of data", [data length]);
 	
    [_receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
 	NSLog(@"Error receiving response: %@", error);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSString *responseData = [[NSString alloc]initWithData:_receivedData encoding:NSUTF8StringEncoding];
    
    SBJsonParser *jsonParser = [SBJsonParser new];
    NSDictionary *jsonData = (NSDictionary *) [jsonParser objectWithString:responseData error:nil];
    NSLog(@"%@",jsonData);
    
    //Temporary:
    if (jsonData != NULL) {
        NSDictionary *userData = (NSDictionary *) [jsonData objectForKey: @"user"];
        NSString *name = (NSString *) [userData objectForKey:@"name"];
        [self alertStatus:[NSString stringWithFormat:@"Welcome, %@!",name] :@"Login Success!"];
    }else {
        [self alertStatus:[NSString stringWithFormat:@"Please try again!"] :@"Login Failed!"];
    }
}

- (IBAction)btnRegisterClick:(id)sender {
}

- (IBAction)btnBackgroundTap:(id)sender {
    [_txtFieldUsername resignFirstResponder];
    [_txtFieldPassword resignFirstResponder];
    
}
@end
