//
//  Submission.h
//  GlobaLeaks
//
//  Created by Lorenzo on 29/07/2013.
//  Copyright (c) 2013 Lorenzo Primiterra. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Submission : NSObject

@property (nonatomic, retain) NSString * context_gus;
@property (nonatomic, retain) NSString * submission_id;
@property (nonatomic, retain) NSDictionary * wb_fields;
@property (nonatomic, retain) NSArray * files;
@property (nonatomic, retain) NSArray * comments;
@property (nonatomic, retain) NSString * finalize;
@property (nonatomic, retain) NSArray * receivers;

-(NSString*)toString;

@end
