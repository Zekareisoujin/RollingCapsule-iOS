//
//  RCS3CredentialsWithExpiration.h
//  memcap
//
//  Created by Trinh Tuan Phuong on 20/7/13.
//  Copyright (c) 2013 Fox Cradle. All rights reserved.
//

#import <AWSS3/AWSS3.h>

@interface RCS3CredentialsWithExpiration : NSObject

@property (nonatomic, strong) NSDate *expiryDate;
@property (nonatomic, strong) AmazonS3Client *s3;

@end
