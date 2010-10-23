//
//  TimeOffsetController.m
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 6/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TimeOffsetController.h"


static NSString* const TLGeotagalogCameraErrorDefault = @"CameraError";
static NSString* const TLGeotagalogManualTimeZoneDefault = @"UseManualTimeZone";
static NSString* const TLGeotagalogManualOffsetDefault = @"ManualTimeZoneSecondsOffset";


@interface TimeOffsetController ()
- (void)refreshComputerTimeZone;
@property (nonatomic, assign) BOOL manualTimeZone;
@property (nonatomic, assign) NSInteger manualTimeZoneSecondsOffset;
- (NSTimeInterval)errorSliderCameraError:(double)value;
- (double)errorSliderValue:(NSTimeInterval)error;
@end


@implementation TimeOffsetController

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString*)theKey {
    if ([theKey isEqualToString:@"cameraTimeZone"]) {
        return NO;
    }
	return [super automaticallyNotifiesObserversForKey:theKey];
}

@synthesize cameraError;
@synthesize cameraTimeZone;

- (void)setCameraError:(NSTimeInterval)newCameraError {
	// set display
	double minutes = newCameraError / 60.0;
	int intMinutes = (int)minutes;
	double seconds = fabs(minutes - intMinutes) * 60.0;
	NSString* offsetString = [NSString stringWithFormat:@"%i minutes, %.2f seconds %s",
							  abs(intMinutes), seconds, (minutes <= 0.0 ? "fast" : "slow")];
	[errorOffsetDisplay setStringValue:offsetString];
	
	// set ivar
	if (cameraError == newCameraError) return;
	cameraError = newCameraError;
	
	// set slider
	double value = [self errorSliderValue:newCameraError];
	[errorSlider setDoubleValue:value];
	
	// set preferences
	[[NSUserDefaults standardUserDefaults]
	 setObject:[NSNumber numberWithDouble:newCameraError] forKey:TLGeotagalogCameraErrorDefault];
}

@synthesize manualTimeZone;

- (void)setManualTimeZone:(BOOL)newManualTimeZone {
	[self willChangeValueForKey:@"cameraTimeZone"];
	manualTimeZone = newManualTimeZone;
	[self didChangeValueForKey:@"cameraTimeZone"];
	
	NSInteger optionTag = 0;
	if (newManualTimeZone) {
		optionTag = 1;
	}
	[timeZoneOptionRadios selectCellWithTag:optionTag];
	[timeZoneSlider setEnabled:newManualTimeZone];
	[timeZoneOffsetDisplay setEnabled:newManualTimeZone];
	[[NSUserDefaults standardUserDefaults]
	 setBool:newManualTimeZone forKey:TLGeotagalogManualTimeZoneDefault];
}

@synthesize manualTimeZoneSecondsOffset;

- (void)setManualTimeZoneSecondsOffset:(NSInteger)newManualTimeZoneSecondsOffset {
	[self willChangeValueForKey:@"cameraTimeZone"];
	manualTimeZoneSecondsOffset = newManualTimeZoneSecondsOffset;
	[self didChangeValueForKey:@"cameraTimeZone"];
	
	NSString* timezoneString = @"GMT";
	if (manualTimeZoneSecondsOffset) {
		int hoursOff = (int)newManualTimeZoneSecondsOffset / 3600;
		timezoneString = [NSString stringWithFormat:@"GMT%+i", hoursOff];
		[timeZoneSlider setIntegerValue:hoursOff];
	}
	else {
		[timeZoneSlider setIntegerValue:0];
	}
	[timeZoneOffsetDisplay setStringValue:timezoneString];
	[[NSUserDefaults standardUserDefaults]
	 setInteger:newManualTimeZoneSecondsOffset forKey:TLGeotagalogManualOffsetDefault];
}

- (void)refreshComputerTimeZone {
	[NSTimeZone resetSystemTimeZone];
	NSString* computerZone = [NSString stringWithFormat:@"(%@)",
							  [[NSTimeZone systemTimeZone] abbreviation]];
	[computerTimeZoneDisplay setStringValue:computerZone];
}

- (void)awakeFromNib {
	NSTimeInterval storedCameraError = 0.0;
	BOOL storedManualTimeZone = [[NSUserDefaults standardUserDefaults]
								 boolForKey:TLGeotagalogManualTimeZoneDefault];
	NSInteger storedManualSecondsOffset = [[NSUserDefaults standardUserDefaults]
										   integerForKey:TLGeotagalogManualOffsetDefault];
	
	[self setCameraError:storedCameraError];
	[self setManualTimeZone:storedManualTimeZone];
	[self setManualTimeZoneSecondsOffset:storedManualSecondsOffset];
	[self showTimeZoneInterface:self];
	[self refreshComputerTimeZone];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(timeZoneChanged:)
												 name:NSSystemTimeZoneDidChangeNotification
											   object:nil];
}

- (void)dealloc {
	[cameraErrorGroup release], cameraErrorGroup = nil;
	[timeZoneGroup release], timeZoneGroup = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)timeZoneChanged:(NSNotification*)notification {
	/* NOTE: calling +[NSTimeZone resetSystemTimeZone] causes the same notification
	 to be sent. This can be supressed by un/re-registering. rdar://problem/6345011 */
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:[notification name]
												  object:nil];
	[self refreshComputerTimeZone];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:_cmd
												 name:[notification name]
											   object:nil];
}

static const double TLGeotagalog_multiplier = 60.0 * 60.0;
static const double TLGeotagalog_exponent = 2.5;

- (NSTimeInterval)errorSliderCameraError:(double)value {
	return TLGeotagalog_multiplier * copysign(pow(fabs(value), TLGeotagalog_exponent), value);
}

- (double)errorSliderValue:(NSTimeInterval)error {
	return copysign(pow(fabs(error / TLGeotagalog_multiplier), 1.0 / TLGeotagalog_exponent), error);
}

- (NSTimeZone*)cameraTimeZone {
	NSTimeZone* timeZone = nil;
	if ([self manualTimeZone]) {
		NSInteger secondsFromGMT = [self manualTimeZoneSecondsOffset];
		timeZone = [NSTimeZone timeZoneForSecondsFromGMT:secondsFromGMT];
	}
	else {
		timeZone = [NSTimeZone systemTimeZone];
	}
	return timeZone;
}

- (IBAction)errorSliderMoved:(id)sender {
	(void)sender;
	double value = [errorSlider doubleValue];
	NSTimeInterval newError = [self errorSliderCameraError:value];
	[self setCameraError:newError];
}

- (IBAction)showTimeZoneInterface:(id)sender {
	(void)sender;
	[cameraErrorGroup removeFromSuperview];
	[timeZoneGroup setFrame:[groupHome bounds]];
	[groupHome addSubview:timeZoneGroup];
}

- (IBAction)timeZoneComputerOptionPicked:(id)sender {
	(void)sender;
	[self setManualTimeZone:NO];
}

- (IBAction)timeZoneManualOptionPicked:(id)sender {
	(void)sender;
	[self setManualTimeZone:YES];
}

- (IBAction)timeZoneSliderMoved:(id)sender {
	(void)sender;
	NSInteger secondsOffset = 3600 * [timeZoneSlider integerValue];
	[self setManualTimeZoneSecondsOffset:secondsOffset];
}

- (IBAction)showCameraErrorInterface:(id)sender {
	(void)sender;
	[timeZoneGroup removeFromSuperview];
	[cameraErrorGroup setFrame:[groupHome bounds]];
	[groupHome addSubview:cameraErrorGroup];
}

@end
