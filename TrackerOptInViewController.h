//
//  TrackerOptInViewController.h
//  Monocept
//
//  Created by JayaGanesh on 5/14/13.
//  Copyright (c) 2013 Monocept. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TrackingPreferences.h"

@class TrackerOptInViewController;
@class OrderSummary;

typedef NSInteger TrackerLayoutType;
enum TrackerLayoutType {
    TrackerLayoutTypeIphone = 0,
    TrackerLayoutTypeIpad
};

@protocol TrackerOptInDelegate;

@interface TrackerOptInViewController : UITableViewController <TrackingPreferencesDelegate,UITextFieldDelegate>

@property (nonatomic, weak) id<TrackerOptInDelegate> delegate;


/**-----------------------------------------------------------------------------
 * @name Initializing the TrackerOptInViewController
 *-------------------------------------------------------------------------------
 */

/**
 Notifies the delegate that the view's frame size changed.
 
 @param tracker summary instance of OrderSummary to associate the
 tracker with.
 
 @param type the TrackerLayoutType.  Can be TrackerLayoutTypeIPhone
 or TrackerLayoutTypeIPad.  This will configure the style of the
 view to the specific layout type.
 
 @return an initialized TrackerOptInViewController instance.
 
 @available Available in Monocept 3.3 and later.
 */
- (id)initWithOrder:(OrderSummary *)summary layoutType:(TrackerLayoutType)type;


/**-----------------------------------------------------------------------------
 * @name Reading TrackingPreferences
 *-------------------------------------------------------------------------------
 */

/**
 Grants public read-only access to TrackingPreferences instance
 */
- (TrackingPreferences*)getTrackingPreferences;



/**-----------------------------------------------------------------------------
 * @name Tapping done button
 *-------------------------------------------------------------------------------
 */

/**
 Resigns firstresponder from phone text label on tap of done button in done button bar
 */
- (void)doneButtonTappedFromReceipt;


@property (nonatomic, strong) UISwitch *pushSwitch;
@property (nonatomic, strong) UISwitch *sSwitch;


@end

@protocol TrackerOptInDelegate <NSObject>

@optional

/**-----------------------------------------------------------------------------
 * @name Getting notified that the tracker view will change.
 *-------------------------------------------------------------------------------
 */

/**
 Notifies the delegate that the view's frame size changed.  This delegate
 method is called before any animations have completed.
 
 @param tracker TrackerOptInViewController instance.
 @param size the new size of the view frame.
 
 @available Available in Monocept 3.3 and later.
 */
- (void)trackerOptIn:(TrackerOptInViewController *)tracker willChangeFrameSize:(CGSize)size;

/**-----------------------------------------------------------------------------
 * @name Getting notified that the tracker view did change
 *-------------------------------------------------------------------------------
 */

/**
 Notifies the delegate that the view's frame size changed.  This delegate
 method is called after animations have completed.
 
 @param tracker TrackerOptInViewController instance.
 @param size the new size of the view frame.
 
 @available Available in Monocept 3.3 and later.
 */
- (void)trackerOptIn:(TrackerOptInViewController *)tracker didChangeFrameSize:(CGSize)size;
/**-----------------------------------------------------------------------------
 * @name Getting notified that the user will submit preferences
 *-------------------------------------------------------------------------------
 */

/**
 Notifies the delegate that the user will submit their
 notification preferences to the API.
 
 @param tracker TrackerOptInViewController instance.
 
 @available Available in Monocept 3.3 and later.
 */
- (void)trackerOptInWillSubmitNotificationPreferences:(TrackerOptInViewController *)tracker;
/**-----------------------------------------------------------------------------
 * @name Getting notified that the user did submit preferences
 *-------------------------------------------------------------------------------
 */

/**
 Notifies the delegate that the user did submit their
 notification preferences to the API.
 
 @param tracker TrackerOptInViewController instance.
 @param error If there was an error, an Error object
 describing the error.
 
 @available Available in Monocept 3.3 and later.
 */
- (void)trackerOptIn:(TrackerOptInViewController *)tracker didSubmitNotificationPreferences:(Error *)error;
/**-----------------------------------------------------------------------------
 * @name Getting notified to show the push notification tutorial.
 *-------------------------------------------------------------------------------
 */

/**
 Notifies the delegate that the user tapped to show the
 Push Notification settings tutorial.
 
 @available Available in Monocept 3.3 and later.
 */
- (void)userDidTapToShowPushNotificationTutorial;
/**-----------------------------------------------------------------------------
 * @name Getting notified when the user finishes editing the phone number.
 *-------------------------------------------------------------------------------
 */

/**
 Notifies the delegate that the user finished editing the S Phone number.
 
 @param phone The updated phone number.
 
 @available Available in Monocept 3.3 and later.
 */
- (void)userDidFinishEditingSPhone:(NSString *)phone;

@end
