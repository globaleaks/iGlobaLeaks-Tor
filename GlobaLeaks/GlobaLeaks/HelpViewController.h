//
//  HelpViewController.h
//  GlobaLeaks
//
//  Created by Lorenzo on 14/07/2013.
//  Copyright (c) 2013 Lorenzo Primiterra. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECSlidingViewController.h"
#import "MenuViewController.h"

@interface HelpViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
}

- (IBAction)revealMenu:(id)sender;
@end
