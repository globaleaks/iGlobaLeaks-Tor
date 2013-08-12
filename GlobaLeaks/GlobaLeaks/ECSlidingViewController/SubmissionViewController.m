//
//  SubmissionViewController.m
//  GlobaLeaks
//
//  Created by Lorenzo on 19/07/2013.
//  Copyright (c) 2013 Lorenzo Primiterra. All rights reserved.
//

#import "SubmissionViewController.h"

@interface SubmissionViewController ()

@end

@implementation SubmissionViewController
@synthesize alert;
- (void)viewDidLoad
{
    [super viewDidLoad];
    client = [[GLClient alloc] init];
    currentContext = 0;
    receiversForContext = [[NSMutableArray alloc] init];
    fields = [[NSMutableArray alloc] init];
    files = [[NSMutableArray alloc] init];
    fileIDs = [[NSMutableArray alloc] init];
    images = [[NSMutableDictionary alloc] init];
    currentReceivers = [[NSMutableArray alloc] init];
    checkbox = [[NSMutableDictionary alloc] init];
    multiselect = [[NSMutableArray alloc] init];
    submission = [Submission new];
    [submission setFinalize:@"false"];
    [self loadReceiver:nil];
}

-(void)loadReceiver:(id) sender {
    Boolean use_cache;
    if (sender != nil) use_cache = NO;
    else use_cache = YES;
        
    [self showActivityIndicator];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        receivers = [client loadData:use_cache ofType:@"receivers"];
        contexts = [client loadData:use_cache ofType:@"contexts"];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([contexts count] > 0){
                [submission setValue:[[contexts objectAtIndex:currentContext] valueForKey:@"context_gus"] forKey:@"context_gus"];
                [self countReceivers];
                [self createFields];
            }
            [self showReloadButton];
            [table reloadData];
        });
    });
}

- (void)showReloadButton {
    UIBarButtonItem *refreshItem = [[UIBarButtonItem alloc]
                                    initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                    target:self
                                    action:@selector(loadReceiver:)];
    navItem.rightBarButtonItem = refreshItem;
}

- (void)showActivityIndicator {
    UIActivityIndicatorView *activityIndicator =
    [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    [activityIndicator startAnimating];
    UIBarButtonItem *activityItem =
    [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    navItem.rightBarButtonItem = activityItem;
}


-(void)countReceivers{
    [currentReceivers removeAllObjects];
    [receiversForContext removeAllObjects];
    NSDictionary *dict = [contexts objectAtIndex:currentContext];
    NSArray *temp = [dict objectForKey:@"receivers"];
    for (int i = 0; i < [receivers count]; i++){
        NSDictionary *r = [receivers objectAtIndex:i];
        if ([temp containsObject:[r objectForKey:@"receiver_gus"]]) {
            [receiversForContext addObject:r];
            [currentReceivers addObject:[r objectForKey:@"receiver_gus"]];
            if ([images objectForKey:[r objectForKey:@"receiver_gus"]] == nil)
                [NSThread detachNewThreadSelector:@selector(downloadImages:) toTarget:self withObject:[r objectForKey:@"receiver_gus"]];
        }
    }
    [submission setValue:currentReceivers forKey:@"receivers"];
}

-(void)createFields{
    [fields removeAllObjects];
    NSDictionary *dict = [contexts objectAtIndex:currentContext];
    NSArray* array = [dict objectForKey:@"fields"];
    for (NSDictionary* dictionary in array){
        Field *temp = [Field new];
        for (NSString *param in dictionary) {
            [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
                //TODO
                if(![(NSString *)key isEqualToString:@"key"])
                [temp setValue:obj forKey:(NSString *)key];
            }];
            [temp setValue:@"" forKey:@"value"];
        }
        [fields addObject:temp];
    }
}


-(void)downloadImages:(NSString*)receiver_id{
    UIImage *img = [UIImage imageWithData:[client getImage:[[NSNumber numberWithBool:YES] boolValue] withId:receiver_id]];
    if (img != nil)
        [images setObject:img forKey:receiver_id];
    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return NSLocalizedString(@"I want to report on" , @"");
    else if (section == 1)
        return NSLocalizedString(@"Receiver selection", @"");
    else if (section == 2)
        return NSLocalizedString(@"Fill out your submission", @"");
    else if (section == 3)
        return NSLocalizedString(@"Attachments", @"");
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return [contexts count];
    else if (section == 1)
        return [receiversForContext count];
    else if (section == 2)
        return [fields count];
    else if (section == 3)
        return [fileIDs count]+1;
    else
        return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    switch (indexPath.section) {
        case 0: {
            NSDictionary *dict = [contexts objectAtIndex:indexPath.row];
            cell = [tableView dequeueReusableCellWithIdentifier:@"Sub"];
            cell.textLabel.text = [dict objectForKey:@"name"];
            cell.detailTextLabel.text =[dict objectForKey:@"description"];
            if (indexPath.row == currentContext) cell.accessoryType = UITableViewCellAccessoryCheckmark;
            else cell.accessoryType = UITableViewCellAccessoryNone;
            cell.imageView.image = nil;
            cell.backgroundColor = [UIColor whiteColor];
            if ([fileIDs count] == 0) cell.userInteractionEnabled = TRUE;
            else cell.userInteractionEnabled = FALSE;
            break;
        }
        case 1: {
            NSDictionary *dict = [receiversForContext objectAtIndex:indexPath.row];
            cell = [tableView dequeueReusableCellWithIdentifier:@"Sub"];
            cell.textLabel.text = [dict objectForKey:@"name"];
            cell.detailTextLabel.text =[dict objectForKey:@"description"];
            cell.imageView.image = [images objectForKey:[dict objectForKey:@"receiver_gus"]];
            if ([currentReceivers containsObject:[dict objectForKey:@"receiver_gus"]])
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            else cell.accessoryType = UITableViewCellAccessoryNone;
            cell.userInteractionEnabled = TRUE;
            cell.backgroundColor = [UIColor whiteColor];
            break;
        }
        case 2: {
            Field *f = [fields objectAtIndex:indexPath.row];
            cell = [tableView dequeueReusableCellWithIdentifier:@"Sub"];
            if ([[f required] boolValue]) cell.textLabel.text = [NSString stringWithFormat:@"%@ *", [f name]];
            else cell.textLabel.text = [f name];
            if (![[f value] isEqualToString:@""] && [f value] != nil)
                cell.detailTextLabel.text = [f value];
            else
                cell.detailTextLabel.text = [f hint];
            
            if ([f value] == nil)
                cell.backgroundColor = [UIColor redColor];
            else
                cell.backgroundColor = [UIColor whiteColor];
            cell.imageView.image = nil;
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.userInteractionEnabled = TRUE;
            break;
        }
        case 3: {
            if(indexPath.row == [fileIDs count]){
                cell = [tableView dequeueReusableCellWithIdentifier:@"Check"];
                cell.textLabel.text = NSLocalizedString(@"Add attachment" , @"");
                cell.imageView.image = nil;
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.backgroundColor = [UIColor whiteColor];
                cell.userInteractionEnabled = TRUE;
            }
            else {
                cell = [tableView dequeueReusableCellWithIdentifier:@"Check"];
                cell.textLabel.text = [NSString stringWithFormat:@"File %d", indexPath.row+1];
                cell.imageView.image = [files objectAtIndex:indexPath.row];
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.backgroundColor = [UIColor whiteColor];
                cell.userInteractionEnabled = FALSE;
            }
            break;
        }
        case 4: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"Button"];
            cell.textLabel.text = NSLocalizedString(@"SEND" , @"");
            cell.imageView.image = nil;
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.backgroundColor = [UIColor clearColor];
            cell.backgroundView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"send.png"] stretchableImageWithLeftCapWidth:0.0 topCapHeight:5.0]];
            cell.userInteractionEnabled = TRUE;
            break;
        }
            break;
    }
    //cell.textLabel.text = [self.menuItems objectAtIndex:indexPath.row];
    //cell.textLabel.textColor = [UIColor whiteColor];
    
    return cell;
}


- (IBAction)revealMenu:(id)sender
{
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    switch (indexPath.section) {
        case 0: {
            currentContext = indexPath.row;
            [submission setValue:[[contexts objectAtIndex:currentContext] valueForKey:@"context_gus"] forKey:@"context_gus"];
            [self countReceivers];
            [self createFields];
            break;
        }
        case 1: {
            if ([currentReceivers containsObject:[[receiversForContext objectAtIndex:indexPath.row] valueForKey:@"receiver_gus"]])
                [currentReceivers removeObject:[[receiversForContext objectAtIndex:indexPath.row] valueForKey:@"receiver_gus"]];
            else [currentReceivers addObject:[[receiversForContext objectAtIndex:indexPath.row] valueForKey:@"receiver_gus"]];
            [submission setValue:currentReceivers forKey:@"receivers"];
            break;
        }
        case 2:{
            field = [fields objectAtIndex:indexPath.row];
            if ([[field type] isEqualToString:@"text"]){
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[field name] message:[field hint] delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
                alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
                alertView.tag = indexPath.row;
                textField = [alertView textFieldAtIndex:0];
                //[textField setPlaceholder:@"Nome lega"];
                //[textField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
                textField.keyboardType = UIKeyboardTypeDefault;
                [alertView show];
            }
            else if ([[field type] isEqualToString:@"radio"]){
                alert	= [[SBTableAlert alloc] initWithTitle:[field name] cancelButtonTitle:@"Cancel" messageFormat:[field hint]];
                options = [field options];
                [alert setDelegate:self];
                [alert setDataSource:self];
                [alert show];
            }
            else if ([[field type] isEqualToString:@"select"]){
                alert	= [[SBTableAlert alloc] initWithTitle:[field name] cancelButtonTitle:@"Cancel" messageFormat:[field hint]];
                options = [field options];
                //TODO tenere questo stile o l'altro?
                [alert.view setTag:2];
                [alert setStyle:SBTableAlertStyleApple];
                [alert setDelegate:self];
                [alert setDataSource:self];
                [alert show];
            }
            else if ([[field type] isEqualToString:@"multiple"]){
                alert	= [[SBTableAlert alloc] initWithTitle:[field name] cancelButtonTitle:@"Cancel" messageFormat:[field hint]];
                options = [field options];
                [alert setType:SBTableAlertTypeMultipleSelct];
                [alert.view addButtonWithTitle:@"OK"];
                [alert setDelegate:self];
                [alert setDataSource:self];
                [alert show];
            }
            else if ([[field type] isEqualToString:@"checkboxes"]){
                alert	= [[SBTableAlert alloc] initWithTitle:[field name] cancelButtonTitle:@"Cancel" messageFormat:[field hint]];
                options = [field options];
                [alert setType:SBTableAlertTypeMultipleSelct];
                [alert.view addButtonWithTitle:@"OK"];
                [alert setDelegate:self];
                [alert setDataSource:self];
                [alert show];
            }
            else if ([[field type] isEqualToString:@"textarea"]){
                //TODO use bigger textview
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[field name] message:[field hint] delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
                alertView.tag = indexPath.row;
                alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
                textField = [alertView textFieldAtIndex:0];
                textField.keyboardType = UIKeyboardTypeDefault;
                [alertView show];
            }
            else if ([[field type] isEqualToString:@"number"]){
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[field name] message:[field hint] delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
                alertView.tag = indexPath.row;
                alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
                textField = [alertView textFieldAtIndex:0];
                textField.keyboardType = UIKeyboardTypeNumberPad;
                [alertView show];
            }
            else if ([[field type] isEqualToString:@"url"]){
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[field name] message:[field hint] delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
                alertView.tag = indexPath.row;
                alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
                textField = [alertView textFieldAtIndex:0];
                textField.keyboardType = UIKeyboardTypeURL;
                [alertView show];
            }
            else if ([[field type] isEqualToString:@"phone"]){
                //TODO get phone from contaxts
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[field name] message:[field hint] delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
                alertView.tag = indexPath.row;
                alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
                textField = [alertView textFieldAtIndex:0];
                textField.keyboardType = UIKeyboardTypePhonePad;
                [alertView show];
            }
            else if ([[field type] isEqualToString:@"email"]){
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[field name] message:[field hint] delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
                alertView.tag = indexPath.row;
                alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
                textField = [alertView textFieldAtIndex:0];
                textField.keyboardType = UIKeyboardTypeEmailAddress;
                [alertView show];
            }
            break;
        }
        case 3:{
            UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                          initWithTitle:NSLocalizedString(@"Add an attachment", @"")
                                          delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                          destructiveButtonTitle:nil
                                          otherButtonTitles:NSLocalizedString(@"Add from Gallery", @""), NSLocalizedString(@"Take a picture", @""), nil];
            actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
            [actionSheet showInView:self.view];
            break;
        }
        case 4:{
            if ([self checkFields]) {
                [self addFieldsToSubmission];
                UIActivityIndicatorView * activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
                activityView.frame = CGRectMake(121.0f, 75.0f, 37.0f, 37.0f);
                [activityView startAnimating];
                loadingAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sending", @"") message:NSLocalizedString(@"Sending submission...", @"") delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
                [loadingAlert addSubview:activityView];
                [loadingAlert show];
                [NSThread detachNewThreadSelector:@selector(manageSubmission) toTarget:self withObject:nil];
            }
            else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:NSLocalizedString(@"Some compulsory fields are missing.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"Close", @"") otherButtonTitles:nil ];
                [alertView show];
            }
            break;
        }
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView reloadData];
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

-(NSString*)createSubmission{
    NSString *submission_id;
    if ([submission submission_id] == nil) {
        NSDictionary *dict = [client createSubmission:submission];
        if (dict != nil){
            submission_id = [dict objectForKey:@"id"];
            [submission setSubmission_id:[dict objectForKey:@"id"]];
            return [dict objectForKey:@"id"];
        }
    }
    return [submission submission_id];
}

-(void)uploadImage:(UIImage*)image{
    NSString *submission_id = [self createSubmission];
    if (submission_id != nil){
        NSString * file = [client uploadImage:image submissionID:[submission submission_id]];
        dispatch_async(dispatch_get_main_queue(), ^{
        if (file != nil){
                [loadingAlert dismissWithClickedButtonIndex:0 animated:YES];
                [fileIDs addObject:file];
                [files addObject:image];
                [submission setFiles:fileIDs];
                [table reloadData];
        }
        else {
            [loadingAlert dismissWithClickedButtonIndex:0 animated:YES];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:NSLocalizedString(@"Error uploading your file.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"Close", @"") otherButtonTitles:nil ];
            [alertView show];
        }
        });
    }
    else {
        [loadingAlert dismissWithClickedButtonIndex:0 animated:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:NSLocalizedString(@"Error sending your request.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"Close", @"") otherButtonTitles:nil ];
            [alertView show];
        });
    }
}

-(void)manageSubmission{
    NSDictionary *result = nil;
    [submission setValue:@"true" forKey:@"finalize"];

    if ([files count] == 0)
        result = [client sendSubmission:submission];
    else
        result = [client updateSubmission:submission];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [loadingAlert dismissWithClickedButtonIndex:0 animated:YES];
        NSLog(@"%@", result);
        if (result == nil) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:NSLocalizedString(@"Error sending your request.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"Close", @"") otherButtonTitles:nil ];
            [alertView show];
        }
        else if ([result objectForKey:@"error_message"] != nil){
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:[result objectForKey:@"error_message"] delegate:nil cancelButtonTitle:NSLocalizedString(@"Close", @"") otherButtonTitles:nil ];
            [alertView show];
        }
        else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Submission successfully sent", @"") message:[NSString stringWithFormat:@"%@ %@. %@", NSLocalizedString(@"Ticket number", @""), [result valueForKey:@"receipt"], NSLocalizedString(@"Do you want to save it in your phonebook?", @"")] delegate:self cancelButtonTitle:NSLocalizedString(@"No", @"") otherButtonTitles:NSLocalizedString(@"Yes", @""), nil];
            alertView.tag = -1;
            textField.text = [result valueForKey:@"receipt"];
            [alertView show];
        }
    });
}

-(void)saveToContacts:(NSString*)number{
	ABRecordRef aContact = ABPersonCreate();
	CFErrorRef anError = NULL;
    ABMutableMultiValueRef multiPhone = ABMultiValueCreateMutable(kABMultiStringPropertyType);
    
    bool didAdd = ABMultiValueAddValueAndLabel(multiPhone, (__bridge CFStringRef)number, kABPersonPhoneMobileLabel, NULL);
    
	if (didAdd == YES)
	{
        ABRecordSetValue(aContact, kABPersonPhoneProperty, multiPhone,nil);
		if (anError == NULL)
		{
			ABUnknownPersonViewController *picker = [[ABUnknownPersonViewController alloc] init];
			picker.unknownPersonViewDelegate = self;
			picker.displayedPerson = aContact;
			picker.allowsAddingToAddressBook = YES;
		    picker.allowsActions = YES;
			picker.alternateName = @"GlobaLeaks Ticket";
			picker.title = @"GlobaLeaks Ticket";
			picker.message = @"Edit the name and save in your contacts";
            [self presentViewController:picker animated:YES completion:nil];
		}
		else
		{
			UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Error"
                                                              message:@"Could not create contact"
                                                             delegate:nil
                                                    cancelButtonTitle:@"Cancel"
                                                    otherButtonTitles:nil];
			[message show];
		}
	}
	CFRelease(multiPhone);
	CFRelease(aContact);
}

-(Boolean)checkFields{
    if([[submission context_gus] length] == 0) return false;
    Boolean returnValue = true;
    for (Field *f in fields){
        if ([[f required] boolValue] && ([[f value] isEqualToString:@""] || [f value] == nil)){
            returnValue = false;
            [f setValue:nil forKey:@"value"];
        }
    }
    return returnValue;
}

- (void) addFieldsToSubmission{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    for (Field *f in fields){
        if ([f value] != nil && ![[f value] isEqualToString:@""])
            [dict setValue:[f value] forKey:[f name]];
    }
    [submission setWb_fields:dict];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1 && [textField.text length] > 0 && alertView.tag == -1){
        [self saveToContacts:textField.text];
        NSLog(@"save phonebook %@", textField.text);
    }
    else if (buttonIndex == 1 && [textField.text length] > 0){
        Field *current = [fields objectAtIndex:alertView.tag];
        [current setValue:textField.text forKey:@"value"];
    }
    [table reloadData];
}

#pragma mark - SBTableAlertDataSource

- (UITableViewCell *)tableAlert:(SBTableAlert *)tableAlert cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell;
	
	if (tableAlert.view.tag == 0 || tableAlert.view.tag == 1) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	} else {
		// Note: SBTableAlertCell
		cell = [[SBTableAlertCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	}
    
    NSDictionary * thisOptions = [options objectAtIndex:indexPath.row];
	cell.textLabel.text = [NSString stringWithFormat:@"%@",[thisOptions objectForKey:@"name"]];
	
	return cell;
}

- (NSInteger)tableAlert:(SBTableAlert *)tableAlert numberOfRowsInSection:(NSInteger)section {
	//if (tableAlert.type == SBTableAlertTypeSingleSelect)
	//	return 3;
	//else
    return [options count];
}

- (NSInteger)numberOfSectionsInTableAlert:(SBTableAlert *)tableAlert {
    return 1;
}

- (NSString *)tableAlert:(SBTableAlert *)tableAlert titleForHeaderInSection:(NSInteger)section {
	//if (tableAlert.view.tag == 3)
	//	return [NSString stringWithFormat:@"Section Header %d", section];
	//else
    return nil;
}

#pragma mark - SBTableAlertDelegate

- (void)tableAlert:(SBTableAlert *)tableAlert didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary * thisOptions = [options objectAtIndex:indexPath.row];

    if (tableAlert.type == SBTableAlertTypeMultipleSelct) {
		UITableViewCell *cell = [tableAlert.tableView cellForRowAtIndexPath:indexPath];		
        if ([[field type] isEqualToString:@"multiple"]){
            if (cell.accessoryType == UITableViewCellAccessoryNone)
                [multiselect addObject:[thisOptions objectForKey:@"name"]];
            else
                [multiselect removeObject:[thisOptions objectForKey:@"name"]];
            NSLog(@"%@", multiselect);
        }
        else if ([[field type] isEqualToString:@"checkboxes"]){
            if (cell.accessoryType == UITableViewCellAccessoryNone)
                [checkbox setObject:@"true" forKey:[thisOptions objectForKey:@"name"]];
            else
                [checkbox setObject:@"false" forKey:[thisOptions objectForKey:@"name"]];
            NSLog(@"%@", checkbox);
        }
        
        if (cell.accessoryType == UITableViewCellAccessoryNone)
			[cell setAccessoryType:UITableViewCellAccessoryCheckmark];
		else
			[cell setAccessoryType:UITableViewCellAccessoryNone];
        
		[tableAlert.tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
    else {
        [field setValue:[thisOptions objectForKey:@"name"] forKey:@"value"];
        [table reloadData];
    }
}

- (void)tableAlert:(SBTableAlert *)tableAlert didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (tableAlert.type == SBTableAlertTypeMultipleSelct) {
        if ([[field type] isEqualToString:@"multiple"]){
            if ([multiselect count] > 0){
            [field setValue:[NSString stringWithFormat:@"[\"%@\"]", [multiselect componentsJoinedByString:@"\", \""]] forKey:@"value"];
            [multiselect removeAllObjects];
            }
        }
        else if ([[field type] isEqualToString:@"checkboxes"]){
            if ([checkbox count] > 0){
                NSString *checkString = @"";
                for (id key in checkbox) {
                    checkString = [checkString stringByAppendingFormat:@"\"%@\":%@,", key, [checkbox objectForKey:key]];
                }
                if ( [checkString length] > 0)
                    checkString = [checkString substringToIndex:[checkString length] - 1];
            [field setValue:[NSString stringWithFormat:@"{%@}" ,checkString] forKey:@"value"];
            [checkbox removeAllObjects];
            }
        }
        [table reloadData];
    }
	NSLog(@"Dismissed: %i", buttonIndex);
}


#pragma mark ABUnknownPersonViewControllerDelegate methods
// Dismisses the picker when users are done creating a contact or adding the displayed person properties to an existing contact.
- (void)unknownPersonViewController:(ABUnknownPersonViewController *)unknownPersonView didResolveToPerson:(ABRecordRef)person
{
	[self dismissViewControllerAnimated:YES completion:nil];
}


// Does not allow users to perform default actions such as emailing a contact, when they select a contact property.
- (BOOL)unknownPersonViewController:(ABUnknownPersonViewController *)personViewController shouldPerformDefaultActionForPerson:(ABRecordRef)person
						   property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
	return NO;
}

@end
