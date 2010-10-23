//
//  StatusMenuController.m
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 4/17/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "StatusMenuController.h"

#import "TaskMaster.h"
#import "Logger.h"
#import "AppDelegate.h"


@interface PulseAnimation : NSAnimation
@end

@interface StatusMenuController ()
+ (NSImage*)pinImageAtRatio:(CGFloat)blendAmount showError:(BOOL)problem;
- (void)tasksHeartbeat:(NSNotification*)notification;
- (void)logHeartbeat:(NSNotification*)notification;
@end


@implementation StatusMenuController

- (id)initWithMenuNibName:(NSString*)menuNibName {
	self = [super init];
	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tasksHeartbeat:)
													 name:TaskMasterDidUpdateNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(logHeartbeat:)
													 name:LoggerDidUpdateNotification object:nil];
		[NSBundle loadNibNamed:menuNibName owner:self];
	}
	return self;
}

- (void)awakeFromNib {
	menuIcon = [[NSStatusBar systemStatusBar]
				statusItemWithLength:NSVariableStatusItemLength];
	menuIcon.image = [[self class] pinImageAtRatio:0 showError:NO];
	menuIcon.attributedTitle = [[NSAttributedString alloc] initWithString:@"Geotagging" attributes:
								[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSFont systemFontOfSize:12], NSFontAttributeName, nil]];
	menuIcon.highlightMode = YES;
	
	menu.delegate = (id)self;
	menuIcon.menu = menu;
}

- (IBAction)showLog:(id)sender {
	[(AppDelegate*)[NSApp delegate] showLogWindow:sender];
}

- (IBAction)promptQuit:(id)sender {
	NSAlert* doneDialog = [NSAlert alertWithMessageText:@"Are you sure you want to quit?"
										  defaultButton:@"Quit"
										alternateButton:@"Continue tagging" otherButton:nil
							  informativeTextWithFormat:
						   @"Tasks are still in progress. "
						   @"If you quit now, your photos will not be geotagged "
						   @"until the next time this geotagging helper is launched."];
	NSInteger button = [doneDialog runModal];
	if (button ==  NSAlertDefaultReturn) {
		[NSApp terminate:sender];
	}
}

- (IBAction)quit:(id)sender {
	(void)sender;
	if (numTasks) {
		[self performSelector:@selector(promptQuit:) withObject:sender afterDelay:0];
	}
	else {
		[NSApp terminate:sender];
	}
}

+ (NSImage*)pinImageAtRatio:(CGFloat)blendAmount showError:(BOOL)problem {
	NSImage* pinA = [NSImage imageNamed:(!problem) ? @"pin-dark_green" : @"pin-yellow"];
	NSImage* pinB = [NSImage imageNamed:@"pin-light_green"];
	//NSAssert(pinA && pinB, @"Need images");
	
	NSImage* pinImage = [[NSImage alloc] initWithSize:NSMakeSize(16, 16)];
	[pinImage lockFocus];
	[pinA drawAtPoint:NSZeroPoint fromRect:NSZeroRect
			operation:NSCompositePlusLighter fraction:(1-blendAmount)];
	[pinB drawAtPoint:NSZeroPoint fromRect:NSZeroRect
			operation:NSCompositePlusLighter fraction:blendAmount];
	[pinImage unlockFocus];
	
	return [pinImage autorelease];
}

- (void)tasksHeartbeat:(NSNotification*)notification {
	NSArray* tasks = [[notification userInfo] objectForKey:TaskMasterCurrentTasks];
	numTasks = [tasks count];
	[[menu itemWithTag:2] setTitle:(numTasks) ? @"Quit..." : @"Quit"];
	
	if (!hadPreviousTaskUpdate) {
		hadPreviousTaskUpdate = YES;
	}
	else if (!numTasks) {
		NSString* errorInfo = (numErrors) ? @"There was one error" : @"";
		if (numErrors > 1) {
			errorInfo = [NSString stringWithFormat:@"There were %lu errors.", (size_t)numErrors];
		}
		NSAlert* doneDialog = [NSAlert alertWithMessageText:@"Done geotagging" defaultButton:@"Quit"
											alternateButton:@"View log" otherButton:nil
								  informativeTextWithFormat:
							   @"All geotagging tasks have finished. %@", errorInfo];
		NSInteger button = [doneDialog runModal];
		if (button ==  NSAlertDefaultReturn) {
			[NSApp terminate:self];
		}
		else {
			[self showLog:self];
		}
	}
}

- (void)updateImage:(CGFloat)ratio {
	menuIcon.image = [[self class] pinImageAtRatio:ratio
										 showError:(numErrors) ? YES : NO];
}

- (void)pulseIcon {
	if ([pulse isAnimating]) return;
	pulse = [[PulseAnimation alloc] initWithDuration:2
									  animationCurve:NSAnimationLinear];
	pulse.delegate = (id)self;
	pulse.animationBlockingMode = NSAnimationNonblocking;
	pulse.frameRate = 20;
	[pulse startAnimation];
}

- (void)logHeartbeat:(NSNotification*)notification {
	NSArray* messages = [[notification userInfo] objectForKey:LoggerMessageErrors];
	NSUInteger numErrorMessages = 0;
	NSUInteger numLogMessages = 0;
	for (NSError* error in messages) {
		if ([error code] > LoggerDebugging) {
			++numLogMessages;
		}
		if ([error code] > LoggerInformative) {
			++numErrorMessages;
		}
	}
	numErrors = numErrorMessages;
	numMessages = numLogMessages;
	
	if (numErrorMessages) {
		NSString* errorStatus = @"One error. View complete log...";
		if (numErrorMessages > 1) {
			errorStatus = [NSString stringWithFormat:@"%lu errors. View complete log...",
						   (size_t)numErrorMessages];
		}
		[[menu itemWithTag:1] setTitle:errorStatus];
	}
	else {
		NSString* logStatus = @"View log...";
		if (numLogMessages > 1) {
			logStatus = [NSString stringWithFormat:@"View %lu log messages...",
						 (size_t)numMessages];
		}
		if (!numTasks) {
			logStatus = [@"Done. " stringByAppendingString:logStatus];
		}
		[[menu itemWithTag:1] setTitle:logStatus];
	}
	
	[self pulseIcon];
}

@end


@implementation PulseAnimation

- (void)setCurrentProgress:(NSAnimationProgress)progress {
	[super setCurrentProgress:progress];
	
	// 0 to 1 to 0: 1 - |-1 to 1|
	// -1 to 1: (2 * progress) - 1
	CGFloat ratio = 1 - (CGFloat)fabs((2 * progress) - 1);
	[(StatusMenuController*)self.delegate updateImage:ratio];
}

@end
