//
//  MainViewController.m
//  GlobaLeaks
//
//  Created by Lorenzo on 14/07/2013.
//  Copyright (c) 2013 Lorenzo Primiterra. All rights reserved.
//

#import "MainViewController.h"
#import "SlidingViewController.h"
#import "AppDelegate.h"
#import "SettingsViewController.h"
#import "BridgeTableViewController.h"

static const CGFloat kNavBarHeight = 52.0f;
static const CGFloat kToolBarHeight = 44.0f;
static const CGFloat kLabelHeight = 14.0f;
static const CGFloat kMargin = 10.0f;
static const CGFloat kSpacer = 2.0f;
static const CGFloat kLabelFontSize = 12.0f;
static const CGFloat kAddressHeight = 26.0f;

static const NSInteger kNavBarTag = 1000;
static const NSInteger kAddressFieldTag = 1001;
static const NSInteger kAddressCancelButtonTag = 1002;
static const NSInteger kLoadingStatusTag = 1003;

static const Boolean kForwardButton = YES;
static const Boolean kBackwardButton = NO;
@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    navBar.topItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo.png"]];
    client = [[GLClient alloc] init];
    
    BOOL myBool = YES;
    NSNumber *passedValue = [NSNumber numberWithBool:myBool];
    [self showActivityIndicator];
    //[self loadNode:passedValue];
}

- (void)showReloadButton {
    UIBarButtonItem *refreshItem = [[UIBarButtonItem alloc]
                                    initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                    target:self
                                    action:@selector(reload)];
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

-(void)loadNode:(NSNumber*)use_cache{
    [self showActivityIndicator];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        NSDictionary *json = [client loadNode:[use_cache boolValue]];
        dispatch_async(dispatch_get_main_queue(), ^{
            if(json != nil){
                titleLabel.text = [json objectForKey:@"name"];
                descriptionLabel.text = [json objectForKey:@"description"];
            }
            else {
                titleLabel.text = @"ERROR!";
                descriptionLabel.text = [NSString stringWithFormat:@"Cannot connect to GlobaLeaks node %@ Is it the right URL? Edit iGlobaLeaks settings, prepend \"http://\" or \"https://\" protocol and verify that your node is up and running.", [[NSUserDefaults standardUserDefaults] stringForKey:@"Site"]];
            }
            });
            NSData * imgData = [client getImage:[use_cache boolValue] withId:@"globaleaks_logo"];
            if (imgData != nil){
                UIImage *img = [UIImage imageWithData:imgData];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [logo setImage:img];
                });
            }
            [client loadData:[use_cache boolValue] ofType:@"receivers"];
            [client loadData:[use_cache boolValue] ofType:@"contexts"];
            dispatch_async(dispatch_get_main_queue(), ^{
            [self showReloadButton];
            });
    });
}

-(void)reload {
    BOOL myBool = NO;
    NSNumber *passedValue = [NSNumber numberWithBool:myBool];
    [NSThread detachNewThreadSelector:@selector(loadNode:) toTarget:self withObject:passedValue];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[MenuViewController class]]) {
        self.slidingViewController.underLeftViewController  = [self.storyboard instantiateViewControllerWithIdentifier:@"MenuVC"];
    }
    
    [self.view addGestureRecognizer:self.slidingViewController.panGesture];
}

- (IBAction)revealMenu:(id)sender
{
    [self.slidingViewController anchorTopViewTo:ECRight];
}

-(void)torConnected{
    [torIcon setImage:[UIImage imageNamed:@"tor_on.png"]];
}

- (void)renderTorStatus: (NSString *)statusLine {
    // TODO: really needs cleanup / prettiness
    //       (turn into semi-transparent modal with spinner?)
//    UILabel *loadingStatus = (UILabel *)[self.view viewWithTag:kLoadingStatusTag];
    UILabel *loadingStatus = descriptionLabel;

    _torStatus = [NSString stringWithFormat:@"%@\n%@",
                  _torStatus, statusLine];
    NSRange progress_loc = [statusLine rangeOfString:@"BOOTSTRAP PROGRESS="];
    NSRange progress_r = {
        progress_loc.location+progress_loc.length,
        2
    };
    NSString *progress_str = @"";
    if (progress_loc.location != NSNotFound)
        progress_str = [statusLine substringWithRange:progress_r];
    
    NSRange summary_loc = [statusLine rangeOfString:@" SUMMARY="];
    NSString *summary_str = @"";
    if (summary_loc.location != NSNotFound)
        summary_str = [statusLine substringFromIndex:summary_loc.location+summary_loc.length+1];
    NSRange summary_loc2 = [summary_str rangeOfString:@"\""];
    if (summary_loc2.location != NSNotFound)
        summary_str = [summary_str substringToIndex:summary_loc2.location];
    
    NSString *status = [NSString stringWithFormat:@"Connecting… This may take a minute.\n\nIf this takes longer than 60 seconds, please close and re-open the app to try connecting from scratch.\n\nIf this problem persists, you can try connecting via Tor bridges by pressing the \"options\" button below. Visit http://onionbrowser.com/help/ if you need help with bridges or if you continue to have issues.\n\n%@%%\n%@",
                        progress_str,
                        summary_str];
    loadingStatus.text = status;
}


@end
