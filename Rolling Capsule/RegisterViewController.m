//
//  RegisterViewController.m
//  Rolling Capsule
//
//  Created by Trinh Tuan Phuong on 26/5/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//
#include "Constants.h"

#import "SBJson.h"
#import "Util.h"
#import "RegisterViewController.h"

@implementation RegisterViewController

- (void)asynchRegisterRequest
{
    //Asynchronous Request
    @try {
        
        if([[_txtFieldName text] isEqualToString:@""] || [[_txtFieldPassword text] isEqualToString:@""] 
           || [[_txtFieldEmail text] isEqualToString:@""] || [[_txtFieldPasswordConfirmation text] isEqualToString:@""] ) {
            alertStatus(@"Please enter all needed information", @"Login Failed!",self);
        } else {
            NSMutableString *dataSt = initQueryString(@"user[email]", [_txtFieldEmail text]);
            addArgumentToQueryString(dataSt, @"user[password]", [_txtFieldPassword text]);
            addArgumentToQueryString(dataSt, @"user[name]", [_txtFieldName text]);
            addArgumentToQueryString(dataSt, @"user[password_confirmation]", [_txtFieldPasswordConfirmation text]);
            NSData *postData = [dataSt dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
            
            NSURL *url=[NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@%@", RCServiceURL, RCUsersResource]];
            
            NSURLRequest *request = CreateHttpPostRequest(url, postData);
            
            NSURLConnection *connection = [[NSURLConnection alloc]
                                           initWithRequest:request
                                           delegate:self
                                           startImmediately:YES];
            _receivedData = [[NSMutableData alloc] init];
            
            if(!connection) {
                NSLog(@"Registration Connection Failed.");
            } else {
                NSLog(@"Registration Connection Succeeded.");
            }
            
        }
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        alertStatus(@"Registration Failed.",@"Registration Failed!",self);
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
        alertStatus([NSString stringWithFormat:@"Welcome, %@!",name], @"Registration Success!", self);
    }else {
        alertStatus([NSString stringWithFormat:@"Please try again! %@", responseData], @"Registration Failed!", self);
    }
}

- (IBAction)btnBackgroundTap:(id)sender {
    [_txtFieldName resignFirstResponder];
    [_txtFieldPassword resignFirstResponder];
    [_txtFieldPasswordConfirmation resignFirstResponder];
    [_txtFieldEmail resignFirstResponder];
    
}

- (IBAction)registerTouchUpInside:(id)sender {
    [self asynchRegisterRequest];
}
@end
