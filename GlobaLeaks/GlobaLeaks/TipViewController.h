//
//  TipViewController.h
//  GlobaLeaks
//
//  Created by Lorenzo on 06/08/2013.
//  Copyright (c) 2013 Lorenzo Primiterra. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBookUI/AddressBookUI.h>
#import "GLClient.h"
#import "ECSlidingViewController.h"
#import "Field.h"

@interface TipViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, ABPeoplePickerNavigationControllerDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    UIAlertView *loadingAlert;
    UITextField *textField;
    IBOutlet UITableView *table;
    int sections;
    GLClient *client;
    Submission *s;
    NSDictionary *loginData;
    NSMutableArray *fields;
    NSString* oldTip;
}
- (IBAction)revealMenu:(id)sender;

@end
