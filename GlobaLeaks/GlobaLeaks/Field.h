//
//  Field.h
//  GlobaLeaks
//
//  Created by Lorenzo on 29/07/2013.
//  Copyright (c) 2013 Lorenzo Primiterra. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Field : NSObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * hint;
@property (nonatomic, retain) NSString * required;
@property (nonatomic, retain) NSString * presentation_order;
@property (nonatomic, retain) NSString * value;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSArray * options;

@end
