//
//  TimeOffsetController.h
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 6/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TimeOffsetController : NSObject {
	__weak IBOutlet NSView* groupHome;
	
	IBOutlet NSView* cameraErrorGroup;
	__weak IBOutlet NSSlider* errorSlider;
	__weak IBOutlet NSTextField* errorOffsetDisplay;
	
	IBOutlet NSView* timeZoneGroup;
	__weak IBOutlet NSMatrix* timeZoneOptionRadios;
	__weak IBOutlet NSTextField* computerTimeZoneDisplay;
	__weak IBOutlet NSSlider* timeZoneSlider;
	__weak IBOutlet NSTextField* timeZoneOffsetDisplay;
@private
	NSTimeInterval cameraError;
	NSTimeZone* cameraTimeZone;
	BOOL manualTimeZone;
	NSInteger manualTimeZoneSecondsOffset;
}

@property (nonatomic, assign) NSTimeInterval cameraError;
@property (nonatomic, readonly) NSTimeZone* cameraTimeZone;

- (IBAction)errorSliderMoved:(id)sender;
- (IBAction)showTimeZoneInterface:(id)sender;

- (IBAction)timeZoneComputerOptionPicked:(id)sender;
- (IBAction)timeZoneManualOptionPicked:(id)sender;
- (IBAction)timeZoneSliderMoved:(id)sender;
- (IBAction)showCameraErrorInterface:(id)sender;

@end
