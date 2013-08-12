//
//  main.m
//  GlobaLeaks
//
//  Created by Lorenzo on 14/07/2013.
//  Copyright (c) 2013 Lorenzo Primiterra. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"

#import "ProxyURLProtocol.h"

int main(int argc, char *argv[])
{
    @autoreleasepool {
        [NSURLProtocol registerClass:[ProxyURLProtocol class]];
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
