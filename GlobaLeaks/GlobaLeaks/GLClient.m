//
//  GLClient.m
//  GlobaLeaks
//
//  Created by Lorenzo on 19/07/2013.
//  Copyright (c) 2013 Lorenzo Primiterra. All rights reserved.
//

#import "GLClient.h"

@implementation GLClient

-(NSDictionary*)loadNode:(Boolean)use_cache {
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
    if (use_cache && timestamp < [[NSUserDefaults standardUserDefaults] doubleForKey:@"nodeTimestamp"] + [[NSUserDefaults standardUserDefaults] integerForKey:@"Cache"]){
        NSLog(@"cache");
        return [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"node"]];
    }

    NSString *url = [NSString stringWithFormat: @"%@/node", [[NSUserDefaults standardUserDefaults] stringForKey:@"Site"]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString: url]];
    //OPTIONAL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0
    [request setTimeoutInterval:60];
    [request setHTTPMethod: @"GET"];
    NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse: nil error: nil];
    //NSString *stringResponse = [[NSString alloc] initWithData: response encoding: NSUTF8StringEncoding];
    //NSLog(@"%@", stringResponse);
    if(response != nil){
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:response
                              options:kNilOptions
                              error:nil];
        if (json != nil){
            [[NSUserDefaults standardUserDefaults] setDouble:timestamp forKey:@"nodeTimestamp"];
            [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:json] forKey:@"node"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            return json;
        }
    }
    return nil;
}

-(NSArray*)loadData:(Boolean)use_cache ofType:(NSString*)type {
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
    if (use_cache && timestamp < [[NSUserDefaults standardUserDefaults] doubleForKey:[NSString stringWithFormat:@"%@Timestamp", type]] + [[NSUserDefaults standardUserDefaults] integerForKey:@"Cache"])
        return [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:type]];
    
    NSString *url = [NSString stringWithFormat: @"%@/%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"Site"], type];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString: url]];
    [request setTimeoutInterval:60];
    [request setHTTPMethod: @"GET"];
    NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse: nil error: nil];
    if(response != nil){
        NSArray* json = [NSJSONSerialization
                              JSONObjectWithData:response
                              options:kNilOptions
                              error:nil];
        if (json != nil){
            [[NSUserDefaults standardUserDefaults] setDouble:timestamp forKey:[NSString stringWithFormat:@"%@Timestamp", type]];
            [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:json] forKey:type];
            [[NSUserDefaults standardUserDefaults] synchronize];
            return json;
        }
    }
    return nil;
}

-(NSData*)getImage:(Boolean)use_cache withId:(NSString*)receiver_id{
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
    if (use_cache && timestamp < [[NSUserDefaults standardUserDefaults] doubleForKey:[NSString stringWithFormat:@"%@Timestamp", receiver_id]] + [[NSUserDefaults standardUserDefaults] integerForKey:@"Cache"])
        return [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:receiver_id]];
     
    NSString *url = [NSString stringWithFormat: @"%@/static/%@.png", [[NSUserDefaults standardUserDefaults] stringForKey:@"Site"], receiver_id];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString: url]];
    [request setTimeoutInterval:60];
    [request setHTTPMethod: @"GET"];
    NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse: nil error: nil];
    if (response != nil){
        [[NSUserDefaults standardUserDefaults] setDouble:timestamp forKey:[NSString stringWithFormat:@"%@Timestamp", receiver_id]];
        [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:response] forKey:receiver_id];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return response;
}

-(NSDictionary*)createSubmission:(Submission*)s{
    NSString *jsonRequest = [s toString];
    NSLog(@"create submission: %@", [s toString]);
    NSData *requestData = [NSData dataWithBytes:[jsonRequest UTF8String] length:[jsonRequest length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat: @"%@/submission", [[NSUserDefaults standardUserDefaults] stringForKey:@"Site"]]]];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:60];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%d", [requestData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody: requestData];
    NSData *response = [NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil];
    NSString *stringResponse = [[NSString alloc] initWithData: response encoding: NSUTF8StringEncoding];
    NSLog(@"response [cs]: %@", stringResponse);
    if (response != nil){
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:response
                              options:kNilOptions
                              error:nil];
        return json;
    }
    return nil;
}

-(NSDictionary*)sendSubmission:(Submission*)s{
    NSString *jsonRequest = [s toString];
    NSLog(@"send submission: %@", [s toString]);
    NSData *requestData = [NSData dataWithBytes:[jsonRequest UTF8String] length:[jsonRequest length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat: @"%@/submission", [[NSUserDefaults standardUserDefaults] stringForKey:@"Site"]]]];
    [request setHTTPMethod:@"POST"];

    //[request addValue:@"Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) AppleWebKit/534.10 (KHTML, like Gecko) Chrome/8.0.552.224 Safari/534.10" forHTTPHeaderField:@"User-Agent"];

    [request setTimeoutInterval:60];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%d", [requestData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody: requestData];
    NSData *response = [NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil];
    NSString *stringResponse = [[NSString alloc] initWithData: response encoding: NSUTF8StringEncoding];
    NSLog(@"response [ss]: %@", stringResponse);
    if (response != nil){
        NSDictionary* json = [NSJSONSerialization
                         JSONObjectWithData:response
                         options:kNilOptions
                         error:nil];
        return json;
    }
    return nil;
}

-(NSDictionary*)updateSubmission:(Submission*)s;{
    NSString *jsonRequest = [s toString];
    NSLog(@"update submission %@", [s toString]);
    NSData *requestData = [NSData dataWithBytes:[jsonRequest UTF8String] length:[jsonRequest length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat: @"%@/submission/%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"Site"], [s submission_id]]]];
    [request setHTTPMethod:@"PUT"];
    [request setTimeoutInterval:60];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%d", [requestData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody: requestData];
    NSData *response = [NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil];
    NSString *stringResponse = [[NSString alloc] initWithData: response encoding: NSUTF8StringEncoding];
    NSLog(@"response [us]: %@", stringResponse);
    if (response != nil){
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:response
                              options:kNilOptions
                              error:nil];
        return json;
    }
    return nil;
}

-(NSString*)uploadImage:(UIImage*)image submissionID:(NSString*)submisssion_id{
    NSData *imageData = UIImagePNGRepresentation(image);
    
    if (imageData != nil)
    {
        NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
        NSNumber *timeStampObj = [NSNumber numberWithDouble: timeStamp];
        NSString *filename = [NSString stringWithFormat:@"%d", [timeStampObj integerValue]];
                
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:[NSURL URLWithString:[NSString stringWithFormat: @"%@/submission/%@/file", [[NSUserDefaults standardUserDefaults] stringForKey:@"Site"], submisssion_id]]];
        [request setHTTPMethod:@"POST"];
        
        NSMutableData *body = [NSMutableData data];                
        [body appendData:[NSData dataWithData:imageData]];
        
        [request setValue:[NSString stringWithFormat:@"attachment; filename=\"%@.png\"", filename] forHTTPHeaderField:@"Content-Disposition"];
        [request setValue:@"image/png" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"%d", [imageData length]] forHTTPHeaderField:@"Content-Length"];
        
        [request setHTTPBody:body];
        NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        NSString *returnString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
        NSLog(@"response [ui]: %@", returnString);
        
        if (response != nil){
            NSArray* json = [NSJSONSerialization
                                  JSONObjectWithData:response
                                  options:kNilOptions
                                  error:nil];
            if ([json count] > 0){
                //TODO {"error_message": "Not Authenticated", "error_code": 30, "arguments": []}
                NSDictionary *dict = [json objectAtIndex:0];
                NSLog(@"%@", [dict objectForKey:@"id"]);
                return [dict objectForKey:@"id"];
            }
        }
    }
    return nil;
}

-(NSDictionary*)addTipImage:(UIImage*)image submissionID:(NSString*)submisssion_id session:(NSString*)session_id{
    NSData *imageData = UIImagePNGRepresentation(image);
    
    if (imageData != nil)
    {
        NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
        NSNumber *timeStampObj = [NSNumber numberWithDouble: timeStamp];
        NSString *filename = [NSString stringWithFormat:@"%d", [timeStampObj integerValue]];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:[NSURL URLWithString:[NSString stringWithFormat: @"%@/tip/%@/upload", [[NSUserDefaults standardUserDefaults] stringForKey:@"Site"], submisssion_id]]];
        [request setHTTPMethod:@"POST"];
        
        NSMutableData *body = [NSMutableData data];
        [body appendData:[NSData dataWithData:imageData]];
        [request setValue:session_id forHTTPHeaderField:@"X-Session"];

        [request setValue:[NSString stringWithFormat:@"attachment; filename=\"%@.png\"", filename] forHTTPHeaderField:@"Content-Disposition"];
        [request setValue:@"image/png" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"%d", [imageData length]] forHTTPHeaderField:@"Content-Length"];
        
        [request setHTTPBody:body];
        NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        NSString *returnString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
        NSLog(@"response [ui]: %@", returnString);
        
        if (response != nil){
            NSArray* json = [NSJSONSerialization
                             JSONObjectWithData:response
                             options:kNilOptions
                             error:nil];
            if ([json count] > 0){
                NSDictionary *dict = [json objectAtIndex:0];
                return dict;
            }
        }
    }
    return nil;
}

-(NSDictionary*)login:(NSString*)receipt{
    NSString *jsonRequest = [NSString stringWithFormat:@"{\"username\":\"wb\",\"password\":\"%@\",\"role\":\"wb\"}", receipt];
    NSLog(@"%@", jsonRequest);
    NSData *requestData = [NSData dataWithBytes:[jsonRequest UTF8String] length:[jsonRequest length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat: @"%@/authentication", [[NSUserDefaults standardUserDefaults] stringForKey:@"Site"]]]];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:60];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%d", [requestData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody: requestData];
    NSData *response = [NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil];
    NSString *stringResponse = [[NSString alloc] initWithData: response encoding: NSUTF8StringEncoding];
    NSLog(@"%@", stringResponse);
    if (response != nil){
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:response
                              options:kNilOptions
                              error:nil];
        return json;
    }
    return nil;
}

-(NSDictionary*)logout{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat: @"%@/authentication", [[NSUserDefaults standardUserDefaults] stringForKey:@"Site"]]]];
    [request setHTTPMethod:@"DELETE"];
    [request setTimeoutInterval:60];
    NSData *response = [NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil];
    NSString *stringResponse = [[NSString alloc] initWithData: response encoding: NSUTF8StringEncoding];
    NSLog(@"%@", stringResponse);
    if (response != nil){
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:response
                              options:kNilOptions
                              error:nil];
        return json;
    }
    return nil;
}

-(NSDictionary*)fetchTip:(NSString*)tip_id session:(NSString*)session_id{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat: @"%@/tip/%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"Site"], tip_id]]];
    [request setHTTPMethod:@"GET"];
    [request setTimeoutInterval:90];
    [request setValue:session_id forHTTPHeaderField:@"X-Session"];
    NSData *response = [NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil];
    NSString *stringResponse = [[NSString alloc] initWithData: response encoding: NSUTF8StringEncoding];
    NSLog(@"%@", stringResponse);
    if (response != nil){
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:response
                              options:kNilOptions
                              error:nil];
        return json;
    }
    return nil;
}

-(NSArray*)fetchTipData:(NSString*)tip_id session:(NSString*)session_id ofType:(NSString*)type{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat: @"%@/tip/%@/%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"Site"], tip_id, type]]];
    [request setHTTPMethod:@"GET"];
    [request setTimeoutInterval:90];
    [request setValue:session_id forHTTPHeaderField:@"X-Session"];
    NSData *response = [NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil];
    NSString *stringResponse = [[NSString alloc] initWithData: response encoding: NSUTF8StringEncoding];
    NSLog(@"tip data [%@] %@", type, stringResponse);
    if (response != nil){
        NSArray* json = [NSJSONSerialization
                              JSONObjectWithData:response
                              options:kNilOptions
                              error:nil];
        return json;
    }
    return nil;
}

-(NSDictionary*)addTipComment:(NSString*)comment submissionID:(NSString*)submisssion_id session:(NSString*)session_id{
    NSString *jsonRequest = [NSString stringWithFormat:@"{\"tip_id\":\"%@\",\"content\":\"%@\"}", submisssion_id, comment];
    NSLog(@"%@", jsonRequest);
    NSData *requestData = [NSData dataWithBytes:[jsonRequest UTF8String] length:[jsonRequest length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat: @"%@/tip/%@/comments", [[NSUserDefaults standardUserDefaults] stringForKey:@"Site"], submisssion_id]]];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:60];
    [request setValue:session_id forHTTPHeaderField:@"X-Session"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%d", [requestData length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody: requestData];
    NSData *response = [NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil];
    NSString *stringResponse = [[NSString alloc] initWithData: response encoding: NSUTF8StringEncoding];
    NSLog(@"%@", stringResponse);
    if (response != nil){
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:response
                              options:kNilOptions
                              error:nil];
        return json;
    }
    return nil;
}

@end
