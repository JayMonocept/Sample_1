//
//  TrackerOptInViewController.m
//  Monocept
//
//  Created by JayaGanesh on 5/14/13.
//  Copyright (c) 2013 Monocept. All rights reserved.
//

#import "TrackerOptInViewController.h"
#import "OrderSummary.h"
#import <QuartzCore/QuartzCore.h>
#import "StyleManager.h"
#import "AlertView.h"
#import "SavedAddress.h"
#import "Error.h"
#import "MBProgressHUD.h"
#import "DataServices+iPadSupport.h"

#define kWIDTH_PADDING 10
#define kSwitchPushTag 21
#define kSwitchSTag 22
#define kSeparatorImageTag 23

#define kTABLE_MAX_HEIGHT_NO_SUBMIT_BUTTON_iPHONE 107
#define kTABLE_MAX_HEIGHT_NO_SUBMIT_BUTTON_iPAD 122
#define kTABLE_MAX_HEIGHT_SUBMIT_BUTTON_iPhone 163
#define kTABLE_MAX_HEIGHT_SUBMIT_BUTTON_iPad 190
#define KTABLE_MAX_HEIGHT_SUBMISSION 41

#define kTickImageName @"icon_cell_full"
#define kCrossImageName @"icon_cell_full"
#define kTickImageName_IPAD @"icon_cell_full"
#define kCrossImageName_IPAD @"icon_cell_full"

#define kIPAD_BUTTON_IMAGE @"btn_blue_submit_order"
#define kIPHONE_BUTTON_IMAGE_ON @"btn_generic_grey_on"
#define kIPHONE_BUTTON_IMAGE_OFF @"btn_generic_grey_off"

#define PLACEHOLDER_DEFAULT_TEXT NSLocalizedString(@"FoodTracker.PhonePlaceHolderText", nil)
#define PLACEHOLDER_TEXT_COLOR [UIColor lightGrayColor]
#define TEXTFIELD_DEFAULT_TEXT_COLOR [UIColor blackColor]
#define kDEFAULT_BACKGROUND_COLOR [UIColor colorWithRed:254.0f/255.0f green:252.0f/255.0f blue:247.0f/255.0f alpha:1.0] //this is fefcf7


enum TrackerOptionRow {
    TrackerOptionRowText = 0,
    TrackerOptionRowSPhone,
    TrackerOptionNumberOfRows
};

@interface TrackerOptInViewController ()

@property (nonatomic, strong) TrackingPreferences *preferences;
@property (nonatomic, strong) OrderSummary *orderSummary;
@property (nonatomic) NSInteger rowCount;
@property (nonatomic) TrackerLayoutType selectedLayoutType;
@property (nonatomic) BOOL submitButtonHidden;

//This will load the table with a single row, checkmark
@property (nonatomic) BOOL successfulSubmission;

//Cell Elements
@property (nonatomic, strong) UITextField *phoneNumberField;
@property (nonatomic, strong) UIButton *submitButton;
@property (nonatomic, strong) UIImageView *separatorImageView;
@property (nonatomic, strong) UIImageView *textFieldImageView;
@property (nonatomic, strong) UIView *padding;
@property (nonatomic, strong) UILabel *legalLabel;

//Flag that submission is in process to the notification server, ie:
//the user has hit the submit button, and for the UI to ignore subsequent
//UI element interactions.
@property (nonatomic, getter = isSubmissionInProcess) BOOL submissionStarted;

@end

@implementation TrackerOptInViewController

- (TrackingPreferences*)getTrackingPreferences{
    return _preferences;
}

- (void)doneButtonTappedFromReceipt {
    [self.phoneNumberField resignFirstResponder];
}

- (id)initWithOrder:(OrderSummary *)summary layoutType:(TrackerLayoutType)type {
    
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        
        // Custom initialization
        _preferences = [[TrackingPreferences alloc]initWithDelegate:self];
        _rowCount = TrackerOptionNumberOfRows;
        _selectedLayoutType = type;
        _successfulSubmission = NO;
        _submitButtonHidden = YES;
        _submissionStarted = NO;
        [self setOrderSummary:summary];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:kDEFAULT_BACKGROUND_COLOR];
    
    //These values will change based on the device the Opt-In is displayed.
    if (self.selectedLayoutType == TrackerLayoutTypeIphone) {
        CGRect frame = CGRectMake(0.0f, 0.0f, 300.0f, (self.selectedLayoutType == TrackerLayoutTypeIphone ? kTABLE_MAX_HEIGHT_NO_SUBMIT_BUTTON_iPHONE :kTABLE_MAX_HEIGHT_NO_SUBMIT_BUTTON_iPAD));
        [self.view setFrame:frame];
        
    }
    else { //ipad
        CGRect frame = CGRectMake(0.0f, 0.0f, 438.0f, (self.selectedLayoutType == TrackerLayoutTypeIphone ? kTABLE_MAX_HEIGHT_NO_SUBMIT_BUTTON_iPHONE :kTABLE_MAX_HEIGHT_NO_SUBMIT_BUTTON_iPAD));
        [self.view setFrame:frame];
        [self.tableView setAutoresizingMask: UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth];
    }
    
    
    UIView *footer = [[UIView alloc]initWithFrame:CGRectZero];
    [self.tableView setTableFooterView:footer];
    [self.view.layer setCornerRadius:(self.selectedLayoutType == TrackerLayoutTypeIphone ? 5.0f : 10.0f)];
    [self.view.layer setBorderWidth:1.5f];
    [self.view.layer setBorderColor:[UIColor lightGrayColor].CGColor];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    //May want to turn off transparency for older devices.
    [self.view setBackgroundColor:[UIColor colorWithRed:255.0f/255.0f green:255.0f/255.0f blue:255.0f/255.0f alpha:0.7]];
    [self.tableView setScrollEnabled:NO];
    
    
    /*Set exclusiveTouch to YES for each of the UI elements as needed.
     
     Discussion
     Setting this property to YES causes the receiver to block the delivery of touch events to other views in the same window. The default value of this property is NO.
     */
    
    [_submitButton setExclusiveTouch:YES];
    [_phoneNumberField setExclusiveTouch:YES];
    [_pushSwitch setExclusiveTouch:YES];
    [_sSwitch setExclusiveTouch:YES];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    
    if (self.successfulSubmission == YES)
        return 1;
    
    return self.rowCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = nil;
    
    if (self.successfulSubmission == YES) {
        
        static NSString *CellId = @"Cell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellId];
        if (cell == nil) {
            
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellId];
            [[cell contentView] setBackgroundColor:kDEFAULT_BACKGROUND_COLOR];
        }
    }
    else {
    
        NSString *CellIdentifier = [NSString stringWithFormat:@"Cell%i",indexPath.row];
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
            [[cell contentView] setBackgroundColor:kDEFAULT_BACKGROUND_COLOR];
        }
        
        if (self.selectedLayoutType == TrackerLayoutTypeIphone) {
            
            [cell.textLabel setFont:[StyleManager H11Font]];
            [cell.textLabel setTextColor:[StyleManager darkGreyColor]];
            [cell.detailTextLabel setFont:[StyleManager H16Font]];
            [cell.detailTextLabel setTextColor:[StyleManager darkGreyColor]];
        }
        else {
            [cell.textLabel setFont:[UIFont boldSystemFontOfSize:17]];
            [cell.textLabel setTextColor:[StyleManager darkGreyColor]];
            [cell.detailTextLabel setFont:[UIFont systemFontOfSize:14]];
            [cell.detailTextLabel setTextColor:[StyleManager darkGreyColor]];
        }
        
        
    }
    
    [cell.textLabel setBackgroundColor:kDEFAULT_BACKGROUND_COLOR];
    [cell.detailTextLabel setBackgroundColor:kDEFAULT_BACKGROUND_COLOR];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    return cell;
}


#pragma mark - Table view delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    //This indexPath.row represents the submit button row.
    if (indexPath.row == TrackerOptionNumberOfRows){
        
        //The button layouts are different on iPad / iPhone
        if (self.selectedLayoutType == TrackerLayoutTypeIphone) {
            return 47.0f;
        }
        else {
            return 57.0f;
        }
    }
    
    //Represents the row with the TextField
    if (indexPath.row == TrackerOptionRowSPhone)
        return 61.0f;//return 51.0f;
    
    //Default to this value
    return 55.0f;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
     [self configureCell:cell AtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([self.phoneNumberField isFirstResponder] == YES)
        [self.phoneNumberField resignFirstResponder];
}

#pragma mark - Cell Display

- (void)configureCell:(UITableViewCell *)cell AtIndexPath:(NSIndexPath *)path {
    
    
    if (self.successfulSubmission == YES) {
        
        UIImageView *tick = [[UIImageView alloc]initWithImage:[UIImage imageNamed:(self.selectedLayoutType == TrackerLayoutTypeIphone ? kTickImageName : kTickImageName_IPAD)]];
        
        UILabel *label = [[UILabel alloc]init];
        [label setText:@"Your notifications have been set."];
        [label setBackgroundColor:kDEFAULT_BACKGROUND_COLOR];
        [label setFont:(self.selectedLayoutType == TrackerLayoutTypeIphone ? [StyleManager H11Font] : [StyleManager H29Font])];
        [label setTextColor:[StyleManager darkGreyColor]];
        [label sizeToFit];
        CGRect labelRect = label.frame;
        labelRect.origin.x = (CGRectGetMidX(cell.bounds) - ((CGRectGetWidth(labelRect) - 5.0f - CGRectGetWidth(tick.frame)) / 2));
        labelRect.origin.y = CGRectGetMidY(cell.bounds) - (CGRectGetMaxY(labelRect));
        [label setFrame:labelRect];
        [cell.contentView addSubview:label];

        [cell.textLabel setText:@""];
        [cell.detailTextLabel setText:@""];
        
        CGRect tickRect = tick.frame;
        tickRect.origin.x = CGRectGetMinX(labelRect) - CGRectGetWidth(tick.frame) - 5.0f;
        tickRect.origin.y = CGRectGetMinY(labelRect);
        [tick setFrame:tickRect];
        [cell.contentView addSubview:tick];
        
        return;
    }
    
    
    else if (path.row == TrackerOptionRowText) {
        
        if (self.sSwitch == nil) {
           
            _sSwitch = [[UISwitch alloc]init];
            [self toggleSwitch:_sSwitch setOn:NO animated:NO];
            [self.sSwitch setAutoresizingMask: UIViewAutoresizingFlexibleLeftMargin];
            [self.sSwitch setTag:kSwitchSTag];
            [self.sSwitch addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
            
            [cell.accessoryView setBackgroundColor:kDEFAULT_BACKGROUND_COLOR];
            cell.accessoryView = self.sSwitch;
        }
        
        [cell.textLabel setText:@"Text Messages"];
        [cell.detailTextLabel setNumberOfLines:2];
        [cell.detailTextLabel setText:@"Enter your 10-digit mobile phone number to be notified when your food is ready"];
        
        CGRect toggleFrame = self.sSwitch.frame;
        toggleFrame.origin.y = 15.0f;
        toggleFrame.origin.x = CGRectGetMaxX(cell.contentView.frame) - (self.sSwitch.frame.size.width + 10.0f);
        [self.sSwitch setFrame:toggleFrame];
    }
    else if (path.row == TrackerOptionRowSPhone) {
        
        
        [cell.textLabel setText:@""];
        [cell.detailTextLabel setText:@""];
        CGRect frame = CGRectInset(cell.contentView.bounds, 10, 0);
        frame.size.height = 41.0f;
        
        if (!_legalLabel) {
            _legalLabel = [[UILabel alloc]initWithFrame:CGRectZero];
            [_legalLabel setFont:[UIFont italicSystemFontOfSize:11]];
            [_legalLabel setTextColor:[UIColor darkGrayColor]];
            [_legalLabel setText:NSLocalizedString(@"FoodTracker.LegalMessage", nil)];
            CGRect labelRect = CGRectMake(15.0f, CGRectGetHeight(frame), CGRectGetWidth(frame), 15.0f);
            [_legalLabel setFrame:labelRect];
            _legalLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            [_legalLabel setAlpha:0.0f];
            [_legalLabel setBackgroundColor:kDEFAULT_BACKGROUND_COLOR];
            [_legalLabel setTextColor:[StyleManager darkGreyColor]];
            [cell.contentView addSubview:_legalLabel];
        }
        
        if (self.phoneNumberField == nil) {
          
            _phoneNumberField = [[UITextField alloc]initWithFrame:frame];
            [self.phoneNumberField setBackgroundColor:kDEFAULT_BACKGROUND_COLOR];
            NSString *phoneNum = self.orderSummary.deliveryAddress.phoneNumber;
            self.phoneNumberField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            [self.phoneNumberField setText:(phoneNum.length > 0? phoneNum : @"")];
            [self.phoneNumberField setPlaceholder:PLACEHOLDER_DEFAULT_TEXT];
            [cell.contentView addSubview:self.phoneNumberField];
            //Checkmark and Cross X
            _textFieldImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 25, 15)];
            [self.textFieldImageView setContentMode:UIViewContentModeScaleAspectFit];
            //Padding for the TextField when user is not in editing mode.
            _padding = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 10, 15)];
            [self.padding setBackgroundColor:[UIColor clearColor]];
            [self.phoneNumberField setKeyboardType:UIKeyboardTypePhonePad];
            [self.phoneNumberField setClearButtonMode:UITextFieldViewModeWhileEditing];
            [self.phoneNumberField setLeftView:self.padding];
            [self.phoneNumberField setLeftViewMode:UITextFieldViewModeAlways];
            [self.phoneNumberField setBorderStyle:UITextBorderStyleNone];
            [self.phoneNumberField setDelegate:self];
            UIImage *stretch = [[UIImage imageNamed:@"text_field"] resizableImageWithCapInsets:UIEdgeInsetake(9, 7, 9, 7)];
            [self.phoneNumberField setBackground:stretch];
            [self.phoneNumberField setFont:[StyleManager H4Font]];
            [self.phoneNumberField setTextColor:[StyleManager darkGreyColor]];
            [self.phoneNumberField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
            
            if (self.orderSummary.deliveryAddress.phoneNumber.length > 0) {

                //Current Phone number associated with the order.  Should we
                //load this?
                NSError *error;
                [self.preferences updateSPhoneNumber:self.orderSummary.deliveryAddress.phoneNumber error:&error];
                if (error != nil) {
                    
                    //Phone number contained invalid characters, default to the
                    //Alpha place holder text.
                    //There was an error with the phone number associated with
                    //the order, in that
                    // it contains illegal characters ie: ### ### #### ext. 21
                    [self.phoneNumberField setText:@""];
                }
                else {
                    [self.phoneNumberField setText:self.orderSummary.deliveryAddress.phoneNumber];
                    [self.phoneNumberField setTextColor:PLACEHOLDER_TEXT_COLOR];
                }
            }
        }
    }
    else {
        
        if (self.submitButton) {
            [self.submitButton removeFromSuperview];
            self.submitButton = nil;
        }
        
        _submitButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.submitButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;

        [self.submitButton setTitle:@"Submit" forState:UIControlStateNormal];
        
        // Targe / Actions for the Submit Button--------------------------------
        [_submitButton addTarget:self action:@selector(submitButtonStateHighlighted) forControlEvents:UIControlEventTouchDown];
        [_submitButton addTarget:self action:@selector(submitButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [_submitButton addTarget:self action:@selector(submitButtonTouchUpOutside) forControlEvents:UIControlEventTouchUpOutside];
        //----------------------------------------------------------------------
        
        
        
        if (self.selectedLayoutType == TrackerLayoutTypeIphone) {
            
            //Frame
            CGRect buttonRect = CGRectMake(10, 0, (CGRectGetMaxX(cell.contentView.frame) - 20), 37);
            [self.submitButton setFrame:buttonRect];
            
            [self.submitButton.titleLabel setFont:[StyleManager H12Font]];
            [self.submitButton setTitleColor:[StyleManager darkGreyColor] forState:UIControlStateNormal];
            [self.submitButton setBackgroundImage:[[UIImage imageNamed:kIPHONE_BUTTON_IMAGE_OFF] resizableImageWithCapInsets:UIEdgeInsetake(18, 7, 18, 7)] forState:UIControlStateNormal];
            [self.submitButton setBackgroundImage:[[UIImage imageNamed:kIPHONE_BUTTON_IMAGE_ON] resizableImageWithCapInsets:UIEdgeInsetake(18, 7, 18, 7)] forState:UIControlStateHighlighted];
        }
        else {
            
            CGRect buttonRect = CGRectMake(10, 0, (CGRectGetMaxX(cell.contentView.frame) - 20), 50);
            [self.submitButton setFrame:buttonRect];
            
            [self.submitButton.titleLabel setFont:[UIFont boldSystemFontOfSize:17]];
            [self.submitButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            
            //Using stretchableImage... method because the newer method does not seem to work because of the way
            // the asset was created.  Stretchable buttons will probably need to be revisted at some point.
            [self.submitButton setBackgroundImage:[[UIImage imageNamed:kIPAD_BUTTON_IMAGE]stretchableImageWithLeftCapWidth:10 topCapHeight:0] forState:UIControlStateNormal];
            [self.submitButton setBackgroundImage:nil forState:UIControlStateHighlighted];
        }
        [cell.contentView addSubview:self.submitButton];
    }
}



#pragma mark - UISwitch Methods

/*
 PLEASE READ: Knowing is half the battle.  GI-Joe
 ------------------------------------------------------------------------------
 Per Apple Documentation for UISwitch:
 
 setOn:animated:
 Set the state of the switch to On or Off, optionally animating the transition.
 
 Discussion
 Setting the switch to either position does not result in an action message being sent.
 
 For Developer:
 Make sure you call the preferences update methods for the Push and S when
 programmatically calling setOn:animated: to keep the data and UI in sync.

 */

- (void)animateOnSwitchS{
    
    [self toggleSwitch:_sSwitch setOn:YES animated:YES];
    [self animateSubmitButtonOnTrackingPreferences];
    [self.phoneNumberField setTextColor:TEXTFIELD_DEFAULT_TEXT_COLOR];
    
}

- (void)toggleSwitch:(UISwitch *)toggle setOn:(BOOL)val animated:(BOOL)animate {
    
    [toggle setOn:val animated:animate];
    
    if ([toggle tag] == kSwitchPushTag) {
        
        [[self preferences] updateSendMobilePushPreference:val];
    }
    else {
        
        [[self preferences] updateSPhonePreference:val];
    }
}

- (void)valueChanged:(UISwitch *)sender {
    
    //User hit the submit button and is trying to interact with the widget.
    //we don't want to allow the user to mess around while we are in the
    //process of submission.

    //Enable Switches and TextField
    if (![_sSwitch isUserInteractionEnabled]) {
        [_sSwitch setUserInteractionEnabled:YES];
    }

    if (![_pushSwitch isUserInteractionEnabled]) {
        [_pushSwitch setUserInteractionEnabled:YES];
    }

    if (![_phoneNumberField isUserInteractionEnabled]) {
        [_phoneNumberField setUserInteractionEnabled:YES];
    }

    
    if ([self isSubmissionInProcess]) {
        return;
    }
    
    
    if ([self.phoneNumberField isFirstResponder] == YES)
        [self.phoneNumberField resignFirstResponder];
        
    if (sender.tag == kSwitchPushTag) {
        [self.preferences updateSendMobilePushPreference:sender.isOn];
    }
    else if (sender.tag == kSwitchSTag) {
        [self.preferences updateSPhonePreference:sender.isOn];
        if (sender.isOn == YES) {
            [self.phoneNumberField becomeFirstResponder];
            [self.phoneNumberField setTextColor:TEXTFIELD_DEFAULT_TEXT_COLOR];
        }
        else {
            
            //Give textField text color placeHolder effect
            [self.phoneNumberField setTextColor:PLACEHOLDER_TEXT_COLOR];
        }
    }
    
    [self animateSubmitButtonOnTrackingPreferences];
}

#pragma mark - Submit Button

- (void)animateSubmitButtonOnTrackingPreferences {
    
    if (self.sSwitch.isOn == YES || self.pushSwitch.isOn == YES) {
        if (self.submitButtonHidden == YES)
            [self showSubmitButton];
    }
    else {
        if (self.submitButtonHidden == NO)
            [self hideSubmitButton];
    }
}

- (void)showSubmitButton {
    
    CGRect viewFrame = self.view.frame;
    viewFrame.size.height = (self.selectedLayoutType == TrackerLayoutTypeIphone? kTABLE_MAX_HEIGHT_SUBMIT_BUTTON_iPhone : kTABLE_MAX_HEIGHT_SUBMIT_BUTTON_iPad);
    
    if ([self.delegate conformsToProtocol:@protocol(TrackerOptInDelegate)]) {
        if ([self.delegate respondsToSelector:@selector(trackerOptIn:willChangeFrameSize:)]) {
            [self.delegate trackerOptIn:self willChangeFrameSize:viewFrame.size];
        }
    }
    
    TrackerOptInViewController * __weak weakSelf = self;
    
    //Show Submit button
    NSIndexPath *submitButtonIndexPath = [NSIndexPath indexPathForRow:self.rowCount inSection:0];
    self.rowCount++;
    
    [self.tableView beginUpdates];
    if (self.selectedLayoutType == TrackerLayoutTypeIphone) {
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:submitButtonIndexPath] withRowAnimation:UITableViewRowAnimationTop];
    }
    else {
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:submitButtonIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
    
    [self.tableView endUpdates];

    viewFrame = self.view.frame;
    viewFrame.size.height = self.selectedLayoutType == TrackerLayoutTypeIphone? kTABLE_MAX_HEIGHT_SUBMIT_BUTTON_iPhone : kTABLE_MAX_HEIGHT_SUBMIT_BUTTON_iPad;
    
    //Animate the frame so it fits.
    [UIView animateWithDuration:0.4 delay:0.1 options:UIViewAnimationOptionTransitionNone animations:^{
        
        TrackerOptInViewController * __strong strongSelf = weakSelf;
        [strongSelf.view setFrame:viewFrame];
        [strongSelf setSubmitButtonHidden:NO];
        [[strongSelf legalLabel] setAlpha:1.0f];
        
    }  completion:^(BOOL finished) {
        if (finished == YES) {
            
            TrackerOptInViewController * __strong strongSelf = weakSelf;
            if ([strongSelf.delegate conformsToProtocol:@protocol(TrackerOptInDelegate)]) {
                if ([strongSelf.delegate respondsToSelector:@selector(trackerOptIn:didChangeFrameSize:)]) {
                    [strongSelf.delegate trackerOptIn:strongSelf didChangeFrameSize:viewFrame.size];
                }
            }
        }
    }];
     
}

- (void)hideSubmitButton {
    
    CGRect viewFrame = self.view.frame;
    viewFrame.size.height = (self.selectedLayoutType == TrackerLayoutTypeIphone ? kTABLE_MAX_HEIGHT_NO_SUBMIT_BUTTON_iPHONE :kTABLE_MAX_HEIGHT_NO_SUBMIT_BUTTON_iPAD);
    
    if ([self.delegate conformsToProtocol:@protocol(TrackerOptInDelegate)]) {
        if ([self.delegate respondsToSelector:@selector(trackerOptIn:willChangeFrameSize:)]) {
            [self.delegate trackerOptIn:self willChangeFrameSize:viewFrame.size];
        }
    }
    
    TrackerOptInViewController * __weak weakSelf = self;
    
    //hide submit button
    self.rowCount--;
    NSIndexPath *submitButtonIndexPath = [NSIndexPath indexPathForRow:self.rowCount inSection:0];
    
    [self.tableView beginUpdates];
    if (self.selectedLayoutType == TrackerLayoutTypeIphone) {
        [self.tableView deleteRowsAtIndexPaths:@[submitButtonIndexPath] withRowAnimation:UITableViewRowAnimationBottom];
    }
    else {
        [self.tableView deleteRowsAtIndexPaths:@[submitButtonIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
    [self.tableView endUpdates];

    viewFrame = self.view.frame;
    viewFrame.size.height = (self.selectedLayoutType == TrackerLayoutTypeIphone ? kTABLE_MAX_HEIGHT_NO_SUBMIT_BUTTON_iPHONE :kTABLE_MAX_HEIGHT_NO_SUBMIT_BUTTON_iPAD);
    
    //Animate the frame so it fits.
    [UIView animateWithDuration:0.4 delay:0.1 options:UIViewAnimationOptionTransitionNone animations:^{
        
        TrackerOptInViewController * __strong strongSelf = weakSelf;
        [strongSelf.view setFrame:viewFrame];
        [strongSelf setSubmitButtonHidden:YES];
        [[strongSelf legalLabel] setAlpha:0.0f];
        
    } completion:^(BOOL finished){
    
        if (finished == YES) {
            
            TrackerOptInViewController * __strong strongSelf = weakSelf;
            if ([strongSelf.delegate conformsToProtocol:@protocol(TrackerOptInDelegate)]) {
                if ([strongSelf.delegate respondsToSelector:@selector(trackerOptIn:didChangeFrameSize:)]) {
                    [strongSelf.delegate trackerOptIn:strongSelf didChangeFrameSize:viewFrame.size];
                }
            }
        }
    }];
}

- (void)animateSuccessfulSubmit {
   
    CGRect viewFrame = self.view.frame;
    viewFrame.size.height = KTABLE_MAX_HEIGHT_SUBMISSION;
    
    if ([self.delegate conformsToProtocol:@protocol(TrackerOptInDelegate)]) {
        if ([self.delegate respondsToSelector:@selector(trackerOptIn:willChangeFrameSize:)]) {
            [self.delegate trackerOptIn:self willChangeFrameSize:viewFrame.size];
        }
    }
    
    TrackerOptInViewController * __weak weakSelf = self;
    
    //Animate the frame so it fits.
    [UIView animateWithDuration:0.2 delay:0.1 options:UIViewAnimationOptionTransitionNone animations:^{
        
        TrackerOptInViewController * __strong strongSelf = weakSelf;
        [strongSelf.view setFrame:viewFrame];
        [strongSelf setSuccessfulSubmission:YES];
        [[strongSelf tableView]reloadData];
        
    } completion:^(BOOL finished) {
        if (finished == YES) {
            
            TrackerOptInViewController * __strong strongSelf = weakSelf;
           if ([strongSelf.delegate conformsToProtocol:@protocol(TrackerOptInDelegate)]) {
                if ([strongSelf.delegate respondsToSelector:@selector(trackerOptIn:didChangeFrameSize:)]) {
                    [strongSelf.delegate trackerOptIn:strongSelf didChangeFrameSize:viewFrame.size];
                }
            }
        }
    }];
}

/*
  Requirements for Phone number validation.
    
    North American Numbering Plan (NANP) numbers:
•	Area code: start with a number from [2-9], followed by [0-8], and then any third digit.
	[2-9][0-8][0-9]
•	Central office or exchange code: start with a number from [2-9], followed by any two digits.
	[2-9][0-9][0-9]
•	Subscriber Number: have no restrictions, [0-9] for each of the four digits.
	[0-9][0-9][0-9][0-9]
 */
- (BOOL)validatePhoneNumber:(NSString *)phoneNumber
{
    NSString *regexString = @"[2-9][0-8][0-9][2-9][0-9][0-9][0-9][0-9][0-9][0-9]";
    NSPredicate *test = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regexString];
    return [test evaluateWithObject:phoneNumber];
}

- (void)submitButtonTapped:(UIButton *)sender {
    
    //Enable Switches and TextField
    if (![_sSwitch isUserInteractionEnabled]) {
        [_sSwitch setUserInteractionEnabled:YES];
    }
    
    if (![_pushSwitch isUserInteractionEnabled]) {
        [_pushSwitch setUserInteractionEnabled:YES];
    }
    
    if (![_phoneNumberField isUserInteractionEnabled]) {
        [_phoneNumberField setUserInteractionEnabled:YES];
    }
    
    //Check if submission is in process, also check to make sure that user is
    //not currently touched down on a switch while trying to tap the submit
    //button.
    if ([self isSubmissionInProcess]) {
        
        return;
    }
    else {
     
         _submissionStarted = YES;
    }
    
    //If both switches are off, do not do anything, as this is not a valid
    //use case for the Opt-In.
    if ([self.sSwitch isOn] == NO && [self.pushSwitch isOn] == NO) {
        
        _submissionStarted = NO; //reset this.
        return;
    }
    
    
    //DELEGATE METHOD:
    //User "will SubmitNotification Preferences"
    //This should fire before any type of parsing/api call.
    if ([self.delegate conformsToProtocol:@protocol(TrackerOptInDelegate)]) {
        if ([self.delegate respondsToSelector:@selector(trackerOptInWillSubmitNotificationPreferences:)]) {
            [self.delegate trackerOptInWillSubmitNotificationPreferences:self];
        }
    }
    
    if (self.sSwitch.isOn || self.pushSwitch.isOn)
    {
        
        // need to check for PhoneNumber validation only if s/Text notifications is enabled
        if (self.sSwitch.isOn ){
            
            // Remove the special character from phoneNumber text and upadte the phone number to self.preferences.
            NSString *phoneNumber = self.phoneNumberField.text;
            NSCharacterSet *doNotWant = [NSCharacterSet characterSetWithCharactersInString:@"()-."];
            phoneNumber = [[[phoneNumber componentsSeparatedByCharactersInSet:doNotWant] componentsJoinedByString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];
            Error *errorCheck;
            [self.preferences updateSPhoneNumber:phoneNumber error:&errorCheck];
            
            //Failed the phone number requirement for Length
            //Create the error and notify the delgate.
            if (phoneNumber.length < 10) {
                NSString *message = phoneNumber.length == 0 ? @"S Phone number is required." : @"Invalid Phone number.";
                Error *error = [[Error alloc]initWithError:nil title:@"" message:message];
                
                if ([self.delegate conformsToProtocol:@protocol(TrackerOptInDelegate)]) {
                    if ([self.delegate respondsToSelector:@selector(trackerOptIn:didSubmitNotificationPreferences:)]) {
                        [self.delegate trackerOptIn:self didSubmitNotificationPreferences:error];
                    }
                }
                
                _submissionStarted = NO; //reset this.
                return;
            }
            
            //Failed Phone Validation
            //Create the error and notify the delegate.
            if ([self validatePhoneNumber:phoneNumber] == NO)
            {
                Error *error = [[Error alloc]initWithError:nil title:@"" message:NSLocalizedString(@"Alert.InvalidPhoneNumber", nil)];
                
                if ([self.delegate conformsToProtocol:@protocol(TrackerOptInDelegate)]) {
                    if ([self.delegate respondsToSelector:@selector(trackerOptIn:didSubmitNotificationPreferences:)]) {
                        [self.delegate trackerOptIn:self didSubmitNotificationPreferences:error];
                    }
                }
                
                _submissionStarted = NO; //reset this.
                return;
            }
        }
        
        
        //This code will run if:
        //a. S Validation passed
        // or: b. Push Notification switch was on
        // or: both a & b.
        TrackerOptInViewController * __weak weakSelf = self;
        [TrackingPreferences sendNotificationPreferences:self.preferences forOrder:self.orderSummary.orderId onCompletion:^(Error *error) {
            
            TrackerOptInViewController * __strong strongSelf = weakSelf;
            
            [strongSelf setSubmissionStarted:NO]; //reset this.
            
            //Notify any delegates that the user has finished submitting their notification preferences.
            if ([strongSelf.delegate conformsToProtocol:@protocol(TrackerOptInDelegate)]) {
                if ([strongSelf.delegate respondsToSelector:@selector(trackerOptIn:didSubmitNotificationPreferences:)]) {
                    [strongSelf.delegate trackerOptIn:strongSelf didSubmitNotificationPreferences:error];
                }
            }
            
            //Resign first responder here because we will have already
            //Notified the delegate.
            if ([strongSelf.phoneNumberField isFirstResponder] == YES) {
                [strongSelf.phoneNumberField resignFirstResponder];
            }
            
            if (error == nil) {
                [strongSelf animateSuccessfulSubmit];
                [strongSelf setSuccessfulSubmission:YES];
                [strongSelf.tableView reloadData];
            }
        }];
    }
    else {
        
        _submissionStarted = NO; //reset this.
        
        if ([self.delegate respondsToSelector:@selector(trackerOptIn:didSubmitNotificationPreferences:)]) {
            NSString *message = @"S Phone number is required.";
            Error *error = [[Error alloc]initWithError:nil title:@"" message:message];
            [self.delegate trackerOptIn:self didSubmitNotificationPreferences:error];
        }
    }
}

#pragma mark - Tracking Preferences Delegate

- (void)trackingPreferences:(TrackingPreferences *)prefs didChangeAuthorizationStatus:(BOOL)pushEnabled {
    
    LOG_GENERAL(0,@"Push authorization status changed.");
    
    // Check the status of the toggle.
    // We only care if the user has toggled on the Push switch on,
    // and Push Notifications is disabled.  In this instance, we will
    // update the Push switch and show the message.
    
    if ([[self pushSwitch] isOn] && !pushEnabled) {
    
        [self toggleSwitch:_pushSwitch setOn:NO animated:YES];
        [self showPushAlert];
    }
}

#pragma mark - TextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    
    //User hit the submit button and is trying to interact with the widget.
    //we don't want to allow the user to mess around while we are in the
    //process of submission.
    if ([self isSubmissionInProcess]) {
    
        return NO;
    }
    
    [self animateOnSwitchS];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
    [textField setTextColor:TEXTFIELD_DEFAULT_TEXT_COLOR];
    
    //Set the correct left view
    [textField setLeftView:self.textFieldImageView];
    
    //Set the Text Notifications Switch On
    [self toggleSwitch:_sSwitch setOn:YES animated:YES];
    [self animateSubmitButtonOnTrackingPreferences];
    
    Error *error;
    [self.preferences updateSPhoneNumber:textField.text error:&error];
    if (error || textField.text.length == 0) {
        [self.textFieldImageView setImage:[UIImage imageNamed:(self.selectedLayoutType == TrackerLayoutTypeIphone ? kCrossImageName : kCrossImageName_IPAD)]];
    }
    else {
        [self.textFieldImageView setImage:[UIImage imageNamed:(self.selectedLayoutType == TrackerLayoutTypeIphone ? kTickImageName : kTickImageName_IPAD)]];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    [textField setTextColor:TEXTFIELD_DEFAULT_TEXT_COLOR];
    
    [textField setLeftView:self.padding];
    
    //Set the switch to off if the text field length is zero.
    if (textField.text.length == 0) {
        
        [self toggleSwitch:_sSwitch setOn:NO animated:YES];
    }
    
    [self animateSubmitButtonOnTrackingPreferences];
    
    if ([self.delegate conformsToProtocol:@protocol(TrackerOptInDelegate)]) {
        if ([self.delegate respondsToSelector:@selector(userDidFinishEditingSPhone:)]) {
            [self.delegate userDidFinishEditingSPhone:self.preferences.sPhoneNumber];
        }
    }

}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSCharacterSet *numSet = [NSCharacterSet decimalDigitCharacterSet];
    
    if ([string isEqualToString:@""] || [string isEqualToString:@" "] || [string isEqualToString:@")"] || [string isEqualToString:@"("] || [string isEqualToString:@"-"] || [string isEqualToString:@"."] || [string rangeOfCharacterFromSet:numSet].location != NSNotFound) {
        
        NutableString *text = [NutableString stringWithString:textField.text];
        [text replaceCharactersInRange:range withString:string];
        Error *error;
        [self.preferences updateSPhoneNumber:text error:&error];
        if (text.length != 0) {
            [self.textFieldImageView setImage:[UIImage imageNamed:(self.selectedLayoutType == TrackerLayoutTypeIphone ? kTickImageName : kTickImageName_IPAD)]];
        }
        else {
            [self.textFieldImageView setImage:[UIImage imageNamed:(self.selectedLayoutType == TrackerLayoutTypeIphone ? kCrossImageName : kCrossImageName_IPAD)]];
        }
        LOG_GENERAL(0,@"S Phone Number Entered: %@",self.preferences.sPhoneNumber);
        NSCharacterSet *doNotWant = [NSCharacterSet characterSetWithCharactersInString:@"()-."];
        NSString *phoneNumber = [[[textField.text componentsSeparatedByCharactersInSet:doNotWant] componentsJoinedByString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];

        return !([phoneNumber length] >= 10 && [string length] >= range.length);
    }
    
    return NO;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    
    //Change to the Cross Image
    [self.textFieldImageView setImage:[UIImage imageNamed:(self.selectedLayoutType == TrackerLayoutTypeIphone ? kCrossImageName : kCrossImageName_IPAD)]];
    Error* error;
    [self.preferences updateSPhoneNumber:@"" error:&error];
    return YES;
}

#pragma mark -
#pragma mark TextField Placeholder Methods

- (void)textFieldSetPlaceholderText:(UITextField *)tf {
    
    //Set the correct place holder.
    NSCharacterSet *characterSet = [NSCharacterSet decimalDigitCharacterSet];
    if ([tf.text rangeOfCharacterFromSet:characterSet].location == NSNotFound) {
        //Text contains no numbers, set the place holder as the default text
        [tf setPlaceholder:PLACEHOLDER_DEFAULT_TEXT];
    }
    else {
        [tf setPlaceholder:tf.text];
    }
    
    //Clear the text in the field so the place holder shows.
    [tf setText:@""];
}



#pragma mark - Alert View

- (void)showPushAlert {
    
    //Show the Alert
    NSString *alertMessage;
    if (self.selectedLayoutType == TrackerLayoutTypeIphone)
        alertMessage = NSLocalizedString(@"FoodTracker.PushNotificationAlertiPhone", nil);
    else
        alertMessage = NSLocalizedString(@"FoodTracker.PushNotificationAlertiPad", nil);
    
    TrackerOptInViewController * __weak weakSelf = self;
    [AlertView showAlertViewWithTitle:NSLocalizedString(@"FoodTracker.PushNotificationAlertTitle", nil) message:alertMessage buttonText:@"Close" cancelBlock:^{} otherButtonText:@"Show Me How" otherBlock:^{
        TrackerOptInViewController * __strong strongSelf = weakSelf;
        if ([strongSelf.delegate conformsToProtocol:@protocol(TrackerOptInDelegate)]) {
            if ([strongSelf.delegate respondsToSelector:@selector(userDidTapToShowPushNotificationTutorial)]) {
                [strongSelf.delegate userDidTapToShowPushNotificationTutorial];
            }
        }
    }];
}


#pragma mark - Let's Play Nice with each other
/*
 NOTE:
 The ability to highlight multiple elements needs to be disabled so that
 things do not clobber, when an element is highlighted, the intention is
 to disable the user interaction of the other elements.
 */



//Called on TouchDown of the Submit button.
- (void)submitButtonStateHighlighted {
    
    [_sSwitch setUserInteractionEnabled:NO];
    [_pushSwitch setUserInteractionEnabled:NO];
    [_phoneNumberField setUserInteractionEnabled:NO];
}

- (void)submitButtonTouchUpOutside {
    
    [_sSwitch setUserInteractionEnabled:YES];
    [_pushSwitch setUserInteractionEnabled:YES];
    [_phoneNumberField setUserInteractionEnabled:YES];
}


@end
