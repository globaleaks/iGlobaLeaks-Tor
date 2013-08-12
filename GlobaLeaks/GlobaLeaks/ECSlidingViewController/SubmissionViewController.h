//
//  SubmissionViewController.h
//  GlobaLeaks
//
//  Created by Lorenzo on 19/07/2013.
//  Copyright (c) 2013 Lorenzo Primiterra. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECSlidingViewController.h"
#import "MenuViewController.h"
#import "GLClient.h"
#import "SBTableAlert.h"
#import "Field.h"
#import "Submission.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@interface SubmissionViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, SBTableAlertDelegate, SBTableAlertDataSource, ABUnknownPersonViewControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate> {
    NSArray *receivers, *contexts;
    GLClient *client;
    IBOutlet UITableView *table;
    int currentContext;
    NSMutableArray *receiversForContext;
    NSMutableDictionary *images;
    NSMutableArray *fields;
    NSMutableArray *files;
    NSMutableArray *fileIDs;
    NSMutableArray *currentReceivers;
    UITextField *textField;
    NSArray *options;
    IBOutlet UINavigationItem *navItem;
    Submission *submission;
    UIAlertView *loadingAlert;
    Field *field;
    NSMutableArray *multiselect;
    NSMutableDictionary *checkbox;
}

- (IBAction)revealMenu:(id)sender;
@property (nonatomic, retain) SBTableAlert *alert;

@end
