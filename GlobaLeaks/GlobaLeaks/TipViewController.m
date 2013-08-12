//
//  TipViewController.m
//  GlobaLeaks
//
//  Created by Lorenzo on 06/08/2013.
//  Copyright (c) 2013 Lorenzo Primiterra. All rights reserved.
//

#import "TipViewController.h"

@implementation TipViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    fields = [[NSMutableArray alloc] init];
    client = [[GLClient alloc] init];
    sections = 1;
    [self startFetchingTip];
    oldTip = @"";
}

-(void)startFetchingTip{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Search submission", @"") message:NSLocalizedString(@"Enter your receipt number or search in your phonebook", @"") delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Phonebook", @""), NSLocalizedString(@"OK", @""), nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    alertView.tag = 1;
    textField = [alertView textFieldAtIndex:0];
    [textField setKeyboardType:UIKeyboardTypeNumberPad];
    [alertView show];
}

- (IBAction)revealMenu:(id)sender
{
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (sections == 1)
        return NSLocalizedString(@"Tip not fetched" , @"");
    if (section == 0)
     return NSLocalizedString(@"Receiver List" , @"");
    else if (section == 1)
        return NSLocalizedString(@"Fields", @"");
    else if (section == 1)
        return NSLocalizedString(@"Files", @"");
    else if (section == 3)
        return NSLocalizedString(@"Comments", @"");
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (sections == 1)
        return 1;
    if (section == 0)
        return [[s receivers] count];
    else if (section == 1)
        return [fields count];
    else if (section == 2)
        return [[s files] count]+1;
    else if (section == 3)
        return [[s comments] count]+1;
    else
        return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if (sections == 1){
        cell = [tableView dequeueReusableCellWithIdentifier:@"Basic"];
        cell.textLabel.text = NSLocalizedString(@"Fetch Tip" , @"");
        return cell;
    }
    switch (indexPath.section) {
        case 0: {
            NSDictionary *current = [[s receivers] objectAtIndex:indexPath.row];
            cell = [tableView dequeueReusableCellWithIdentifier:@"Sub"];
            cell.textLabel.text = [current objectForKey:@"name"];
            cell.detailTextLabel.text =[NSString stringWithFormat:@"Access counter %@", [current objectForKey:@"access_counter"]];
            break;
        }
        case 1: {
            Field *f = [fields objectAtIndex:indexPath.row];
            cell = [tableView dequeueReusableCellWithIdentifier:@"Sub"];
            cell.textLabel.text = [f name];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [f value]];
            break;
        }
        case 2: {
            if(indexPath.row == [[s files] count]){
                cell = [tableView dequeueReusableCellWithIdentifier:@"Basic"];
                cell.textLabel.text = NSLocalizedString(@"Add file" , @"");
            }
            else {
                NSDictionary *dict = [[s files] objectAtIndex:indexPath.row];
                cell = [tableView dequeueReusableCellWithIdentifier:@"Sub"];
                cell.textLabel.text = [NSString stringWithFormat:@"%@",[dict objectForKey:@"name"]];
                cell.detailTextLabel.text =[NSString stringWithFormat:@"size: %@ type: %@",[dict objectForKey:@"size"], [dict objectForKey:@"content_type"]];
            }
            break;
        }
        case 3: {
            if(indexPath.row == [[s comments] count]){
                cell = [tableView dequeueReusableCellWithIdentifier:@"Basic"];
                cell.textLabel.text = NSLocalizedString(@"Add Comment" , @"");
            }
            else {
                NSDictionary *dict = [[s comments] objectAtIndex:indexPath.row];
                cell = [tableView dequeueReusableCellWithIdentifier:@"Sub"];
                cell.textLabel.text =[NSString stringWithFormat:@"content: %@",[dict objectForKey:@"content"]];
                cell.detailTextLabel.text = [NSString stringWithFormat:@"author: %@",[dict objectForKey:@"author"]];
            }
            break;
        }
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (sections == 1){
        [self startFetchingTip];
    }
    else {
        switch (indexPath.section) {
            case 2:{
                if(indexPath.row == [[s files] count]){
                    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                                  initWithTitle:NSLocalizedString(@"Add an attachment", @"")
                                                  delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                                  destructiveButtonTitle:nil
                                                  otherButtonTitles:NSLocalizedString(@"Add from Gallery", @""), NSLocalizedString(@"Take a picture", @""), nil];
                    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
                    [actionSheet showInView:self.view];
                }
                break;
            }
            case 3:{
                if(indexPath.row == [[s comments] count]){
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add comment", @"") message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
                alertView.tag = 2;
                alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
                textField = [alertView textFieldAtIndex:0];
                textField.keyboardType = UIKeyboardTypeEmailAddress;
                [alertView show];
                }
                break;
            }
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1){
    if (buttonIndex == 0){
        ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
        picker.peoplePickerDelegate = self;
        [self presentViewController:picker animated:YES completion:nil];
    }
    else if (buttonIndex == 1){
        if ([textField.text length] != 0 ) {
            UIActivityIndicatorView * activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            activityView.frame = CGRectMake(121.0f, 75.0f, 37.0f, 37.0f);
            [activityView startAnimating];
            loadingAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Loading", @"") message:NSLocalizedString(@"Checking tip...", @"") delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
            [loadingAlert addSubview:activityView];
            [loadingAlert show];
            [NSThread detachNewThreadSelector:@selector(handleTip:) toTarget:self withObject:textField.text];
        }
    }
    }
    else if (alertView.tag == 2){
        if (buttonIndex == 1 && [textField.text length] != 0){
            UIActivityIndicatorView * activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            activityView.frame = CGRectMake(121.0f, 75.0f, 37.0f, 37.0f);
            [activityView startAnimating];
            loadingAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Loading", @"") message:NSLocalizedString(@"Adding comment...", @"") delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
            [loadingAlert addSubview:activityView];
            [loadingAlert show];
            [NSThread detachNewThreadSelector:@selector(addComment:) toTarget:self withObject:textField.text];
        }
    }
}

- (void)peoplePickerNavigationControllerDidCancel:
(ABPeoplePickerNavigationController *)peoplePicker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (BOOL)peoplePickerNavigationController:
(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    
    [self displayPerson:person];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    return NO;
}

- (BOOL)peoplePickerNavigationController:
(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
                                property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier
{
    return NO;
}

- (void)displayPerson:(ABRecordRef)person
{
    NSString* phone = nil;
    ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
    
    //TODO: if multiple numbers, let the user choose
    if (ABMultiValueGetCount(phoneNumbers) > 0) {
        phone = (__bridge_transfer NSString*)
        ABMultiValueCopyValueAtIndex(phoneNumbers, 0);
    } else {
        phone = @"[None]";
    }
    //remove all ( ) - and spaes
    phone = [phone stringByReplacingOccurrencesOfString:@" " withString:@""];
    phone = [phone stringByReplacingOccurrencesOfString:@"(" withString:@""];
    phone = [phone stringByReplacingOccurrencesOfString:@")" withString:@""];
    phone = [phone stringByReplacingOccurrencesOfString:@"-" withString:@""];
    //NSLog(@"%@", phone);
    //textField.text = phone;
    
    UIActivityIndicatorView * activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityView.frame = CGRectMake(121.0f, 75.0f, 37.0f, 37.0f);
    [activityView startAnimating];
    loadingAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Loading", @"") message:NSLocalizedString(@"Fetching tip...", @"") delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [loadingAlert addSubview:activityView];
    [loadingAlert show];
    [NSThread detachNewThreadSelector:@selector(handleTip:) toTarget:self withObject:phone];
    
    CFRelease(phoneNumbers);
}

-(void)handleTip:(NSString*)tip{
    if (![oldTip isEqualToString:tip] || loginData == nil){
        loginData = [client login:tip];
        oldTip = tip;
    }
    else NSLog(@"login data reused");
    if (loginData != nil){
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([loginData objectForKey:@"error_message"] != nil){
                [loadingAlert dismissWithClickedButtonIndex:0 animated:YES];
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:[loginData objectForKey:@"error_message"] delegate:nil cancelButtonTitle:NSLocalizedString(@"Close", @"") otherButtonTitles:nil ];
                [alertView show];
                loginData = nil;
            }
            else {
                NSDictionary *tipData = [client fetchTip:[loginData objectForKey:@"user_id"] session:[loginData objectForKey:@"session_id"]];
                NSArray *receivers = [client fetchTipData:[loginData objectForKey:@"user_id"] session:[loginData objectForKey:@"session_id"] ofType:@"receivers"];
                NSArray *comments = [client fetchTipData:[loginData objectForKey:@"user_id"] session:[loginData objectForKey:@"session_id"] ofType:@"comments"];
                //TODO cache?
                [loadingAlert dismissWithClickedButtonIndex:0 animated:YES];
                if (tipData != nil && receivers != nil){
                    s = [[Submission alloc] init];
                    [s setContext_gus:[tipData objectForKey:@"context_gus"]];
                    [s setFiles:[tipData objectForKey:@"files"]];
                    [s setWb_fields:[tipData objectForKey:@"fields"]];
                    [s setSubmission_id:[tipData objectForKey:@"id"]];
                    [s setReceivers:receivers];
                    [s setComments:comments];
                    [self createFields:[tipData objectForKey:@"fields"]];
                    sections = 4;
                    [table reloadData];
                }
                else {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:@"Fetch tip timeout" delegate:nil cancelButtonTitle:NSLocalizedString(@"Close", @"") otherButtonTitles:nil ];
                    [alertView show];
                }
            }
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [loadingAlert dismissWithClickedButtonIndex:0 animated:YES];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:@"Login timeout" delegate:nil cancelButtonTitle:NSLocalizedString(@"Close", @"") otherButtonTitles:nil ];
            [alertView show];
        });
    }
}

-(void)createFields:(NSDictionary*)wb_fields{
    [fields removeAllObjects];
    for (id key in wb_fields) {
        Field *temp = [Field new];
        [temp setName:(NSString*)key];
        [temp setValue:[wb_fields objectForKey:key]];
        [fields addObject:temp];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0){
        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc]init];
        imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.delegate = self;
        imagePickerController.sourceType =  UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:imagePickerController animated:YES completion:nil];
    }
    else if (buttonIndex == 1){
        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.delegate = self;
        imagePickerController.sourceType =  UIImagePickerControllerSourceTypeCamera;
        [self presentViewController:imagePickerController animated:YES completion:nil];
        
    }
}


- (void)imagePickerController:(UIImagePickerController *)picker
        didFinishPickingImage:(UIImage *)image
                  editingInfo:(NSDictionary *)editingInfo
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self prepareImage:image];
}

-(void)prepareImage:(UIImage*)image{
    UIActivityIndicatorView * activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityView.frame = CGRectMake(121.0f, 75.0f, 37.0f, 37.0f);
    [activityView startAnimating];
    loadingAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Attach file", @"") message:NSLocalizedString(@"Uploading image...", @"") delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [loadingAlert addSubview:activityView];
    [loadingAlert show];
    [NSThread detachNewThreadSelector:@selector(uploadImage:) toTarget:self withObject:image];
}

-(void)uploadImage:(UIImage*)image{
    NSDictionary * file = [client addTipImage:image submissionID:[s submission_id] session:[loginData objectForKey:@"session_id"]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [loadingAlert dismissWithClickedButtonIndex:0 animated:YES];
        if (file != nil){
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Success", @"") message:NSLocalizedString(@"File added.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"Close", @"") otherButtonTitles:nil ];
            [alertView show];
            NSMutableArray *temp = [[NSMutableArray alloc] initWithArray:[s files]];
            [temp addObject:file];
            [s setFiles:temp];
            [table reloadData];
        }
        else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:NSLocalizedString(@"Error uploading your file.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"Close", @"") otherButtonTitles:nil ];
            [alertView show];
        }
    });
}

-(void)addComment:(NSString*)comment{
    NSDictionary *response = [client addTipComment:comment submissionID:[s submission_id] session:[loginData objectForKey:@"session_id"]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [loadingAlert dismissWithClickedButtonIndex:0 animated:YES];
        if (response != nil){
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Success", @"") message:NSLocalizedString(@"Comment added.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"Close", @"") otherButtonTitles:nil ];
            [alertView show];
            NSMutableArray *temp = [[NSMutableArray alloc] initWithArray:[s comments]];
            [temp addObject:response];
            [s setComments:temp];
            [table reloadData];
        }
        else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:NSLocalizedString(@"Error adding your comment.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"Close", @"") otherButtonTitles:nil ];
            [alertView show];
        }
    });
}


@end