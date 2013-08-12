//
//  GLClient.h
//  GlobaLeaks
//
//  Created by Lorenzo on 19/07/2013.
//  Copyright (c) 2013 Lorenzo Primiterra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Submission.h"

@interface GLClient : NSObject
-(NSDictionary*)loadNode:(Boolean)use_cache;
-(NSArray*)loadData:(Boolean)use_cache ofType:(NSString*)type;
-(NSData*)getImage:(Boolean)use_cache withId:(NSString*)receiver_id;
-(NSDictionary*)createSubmission:(Submission*)s;
-(NSDictionary*)sendSubmission:(Submission*)s;
-(NSDictionary*)updateSubmission:(Submission*)s;
-(NSString*)uploadImage:(UIImage*)image submissionID:(NSString*)submisssion_id;
-(NSDictionary*)addTipImage:(UIImage*)image submissionID:(NSString*)submisssion_id session:(NSString*)session_id;
-(NSDictionary*)login:(NSString*)receipt;
-(NSDictionary*)logout;
-(NSDictionary*)fetchTip:(NSString*)tip_id session:(NSString*)session_id;
-(NSArray*)fetchTipData:(NSString*)tip_id session:(NSString*)session_id ofType:(NSString*)type;
-(NSDictionary*)addTipComment:(NSString*)comment submissionID:(NSString*)submisssion_id session:(NSString*)session_id;

@end
