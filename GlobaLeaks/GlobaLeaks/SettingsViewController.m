//
//  SettingsViewController.m
//  GlobaLeaks
//
//  Created by Lorenzo on 14/07/2013.
//  Copyright (c) 2013 Lorenzo Primiterra. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    defaults = [NSUserDefaults standardUserDefaults];
}

- (IBAction)revealMenu:(id)sender
{
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if (indexPath.row == 0){
        NSString *cellIdentifier = @"Check";
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        cell.textLabel.text = NSLocalizedString(@"Globaleaks Site", @"");
        cell.detailTextLabel.text = [defaults stringForKey:@"Site"];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else if (indexPath.row == 2){
        NSString *cellIdentifier = @"Detail";
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        cell.textLabel.text = NSLocalizedString(@"Cache data", @"");
        cell.detailTextLabel.text = [defaults stringForKey:@"Cache"];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else {
        NSString *cellIdentifier = @"Check";
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        cell.textLabel.text = @"Force Tor";
        cell.detailTextLabel.text = NSLocalizedString(@"When OFF, connection is potentially unsecure", @"");
        if ([defaults boolForKey:@"Tor"])
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        else cell.accessoryType = UITableViewCellAccessoryNone;
    }
    //cell.textLabel.textColor = [UIColor whiteColor];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 1){
        if ([defaults boolForKey:@"Tor"]) [defaults setBool:NO forKey:@"Tor"];
        else [defaults setBool:YES forKey:@"Tor"];
        [defaults synchronize];
    }
    else if (indexPath.row == 0) [self editSite];
    else [self editCache];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView reloadData];
}


- (void) editSite {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Globaleaks Site", @"") message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    alertView.tag = 0;
    textField = [alertView textFieldAtIndex:0];
    [textField setText:[defaults stringForKey:@"Site"]];
    [alertView show];
}

- (void) editCache {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Cache Data", @"") message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    alertView.tag = 1;
    textField = [alertView textFieldAtIndex:0];
    [textField setText:[defaults stringForKey:@"Cache"]];
    [textField setKeyboardType:UIKeyboardTypeNumberPad];
    [alertView show];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1 && [textField.text length] != 0){
        if (alertView.tag == 0) {
            NSString *newURL;
            if ([[textField.text substringFromIndex: [textField.text length] - 1] isEqualToString:@"/"])
                newURL = [textField.text substringToIndex: [textField.text length]-1];
            else
                newURL = textField.text;
            
            if (![newURL isEqualToString:[defaults stringForKey:@"Site"]]){
                NSString *domainName = [[NSBundle mainBundle] bundleIdentifier];
                [defaults removePersistentDomainForName:domainName];
            }            
            [defaults setObject:newURL forKey:@"Site"];
         }
        else {
            [defaults setInteger:[textField.text integerValue] forKey:@"Cache"];
        }
        [defaults synchronize];
        [table reloadData];
    }
}

@end
