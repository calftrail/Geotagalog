//
//  TLImageCaptureManager.m
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 1/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TLImageCaptureManager.h"

#import "TLImageCapture.h"

#import "TLImageCapturePhotoSource.h"

NSString* const TLImageCaptureManagerSourcesDidUpdateNotification = @"TLImageCaptureManager_SourcesDidUpdate";

static NSString* const TLGeotagalogLaunchPathKey = @"LastLaunchPath";
static NSString* const TLGeotagalogPreviousLaunchApp = @"FormerLaunchedApp";

static CFStringRef const TLICAPreferencesSuiteName = CFSTR("com.apple.ImageCapture2");
static CFStringRef const TLICALaunchPath = CFSTR("HotPlugActionPath");
static CFStringRef const TLICALaunchOptions = CFSTR("HotPlugActionArray");


@interface TLImageCaptureManager ()
- (void)begin;
- (void)registerSource:(ICAObject)icao;
- (void)removeSource:(ICAObject)icao;
@end

static void TLICM_DeviceListCallback(ICAHeader* pb);


static TLImageCaptureManager* gTLImageCaptureManager_sharedInstance = nil;

@implementation TLImageCaptureManager

@synthesize sources = mutableSources;

#pragma mark Lifecycle

+ (void)initialize {
	if (self != [TLImageCaptureManager class]) return;
	gTLImageCaptureManager_sharedInstance = [TLImageCaptureManager new];
}

+ (id)sharedImageCaptureManager {
	NSAssert([NSThread isMainThread], @"Image Capture Manager must be used from main thread");
	[gTLImageCaptureManager_sharedInstance begin];
	return gTLImageCaptureManager_sharedInstance;
}

- (id)init {
	NSAssert(!gTLImageCaptureManager_sharedInstance, @"Singleton only!");
	self = [super init];
	if (self) {
		mutableSources = [NSMutableSet new];
	}
	return self;
}

- (void)dealloc {
	[mutableSources release];
	[super dealloc];
}

- (void)addSourcesObject:(TLImageCapturePhotoSource*)newSource {
	[mutableSources addObject:newSource];
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:TLImageCaptureManagerSourcesDidUpdateNotification object:self];
}

- (void)removeSourcesObject:(TLImageCapturePhotoSource*)oldSource {
	[mutableSources removeObject:oldSource];
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:TLImageCaptureManagerSourcesDidUpdateNotification object:self];
}


- (void)begin {
	if (begun) return;
	begun = YES;
	
	ICAGetDeviceListPB pb = {};
	pb.header.refcon = (intptr_t)self;
	ICAError err = ICAGetDeviceList(&pb, TLICM_DeviceListCallback);
	if (err) {
		NSLog(@"Could not load Image Capture photo sources."
			  @" Error %i calling ICAGetDeviceList.", (int)err);
	}
}

- (void)backgroundRegisterSource:(NSDictionary*)info {
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	
	ICAObject icao = [[info valueForKey:(id)kTLICAObjectKey] intValue];
	TLImageCapturePhotoSource* source = [[TLImageCapturePhotoSource alloc] initWithICAO:icao];
	[self performSelectorOnMainThread:@selector(addSourcesObject:)
						   withObject:source
						waitUntilDone:YES];
	[source release];
	
	[pool drain];
}

- (void)registerSource:(ICAObject)icao {
	NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
						  [NSNumber numberWithInt:icao], (id)kTLICAObjectKey, nil];
	// add source in background, since ICA source initialization is synchronous
	[self performSelectorInBackground:@selector(backgroundRegisterSource:) withObject:info];
}

- (void)removeSource:(ICAObject)icao {
	TLImageCapturePhotoSource* oldSource = nil;
	for (TLImageCapturePhotoSource* source in [self sources]) {
		if ([source icao] == icao) {
			oldSource = source;
			break;
		}
	}
	[self removeSourcesObject:oldSource];
}


#pragma mark Image Capture preferences handling

- (void)updateImageCaptureEntry {
	// verify most recently launched Geotagalog is an Image Capture option
	NSUserDefaults* ourDefaults = [NSUserDefaults standardUserDefaults];
	NSString* formerLaunchPath = [ourDefaults stringForKey:TLGeotagalogLaunchPathKey];
	NSString* currentLaunchPath = [[NSBundle mainBundle] bundlePath];
	
	CFArrayRef cameraActions = CFPreferencesCopyValue(TLICALaunchOptions, TLICAPreferencesSuiteName,
													  kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
	NSMutableArray* newCameraActions = nil;
	if (cameraActions) {
		newCameraActions = [[(NSArray*)cameraActions mutableCopy] autorelease];
		CFRelease(cameraActions);
	}
	else {
		newCameraActions = [NSMutableArray array];
	}
	[newCameraActions removeObject:formerLaunchPath];
	[newCameraActions removeObject:currentLaunchPath]; // avoid duplicates
	[newCameraActions addObject:currentLaunchPath];
	//NSLog(@"Setting launch options: %@", newCameraActions);
	CFPreferencesSetValue(TLICALaunchOptions, (CFArrayRef)newCameraActions, TLICAPreferencesSuiteName,
						  kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
	[ourDefaults setObject:currentLaunchPath forKey:TLGeotagalogLaunchPathKey];
	
	CFPreferencesSynchronize(TLICAPreferencesSuiteName,
							 kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
	[ourDefaults synchronize];
}

- (BOOL)shouldAutoLaunch {
	BOOL requestedExternally = NO;
	CFStringRef currentApp = CFPreferencesCopyValue(TLICALaunchPath, TLICAPreferencesSuiteName,
													kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
	if (currentApp) {
		NSString* ourLaunchPath = [[NSBundle mainBundle] bundlePath];
		if ([ourLaunchPath isEqual:(id)currentApp]) {
			requestedExternally = YES;
		}
		CFRelease(currentApp);
	}
	return requestedExternally;
}

- (void)setShouldAutoLaunch:(BOOL)newShouldAutoLaunch {
	BOOL wasAutoLaunching = [self shouldAutoLaunch];
	
	NSUserDefaults* ourDefaults = [NSUserDefaults standardUserDefaults];
	if (!wasAutoLaunching) {
		NSString* ourLaunchPath = [[NSBundle mainBundle] bundlePath];
		// remember previous setting
		CFStringRef formerApp = CFPreferencesCopyValue(TLICALaunchPath, TLICAPreferencesSuiteName,
													   kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
		if (!formerApp || [ourLaunchPath isEqual:(id)formerApp]) {
			if (formerApp) CFRelease(formerApp);
			formerApp = CFSTR("");
		}
		//NSLog(@"Saving formerApp '%@'", (NSString*)formerApp);
		[ourDefaults setObject:(NSString*)formerApp forKey:TLGeotagalogPreviousLaunchApp];
		CFRelease(formerApp);
		[ourDefaults synchronize];
		
		// set ourself to launch
		if (newShouldAutoLaunch) {
			CFPreferencesSetValue(TLICALaunchPath, (CFStringRef)ourLaunchPath, TLICAPreferencesSuiteName,
								  kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
		}
	}
	else if (wasAutoLaunching && !newShouldAutoLaunch) {
		// restore previous setting
		NSString* formerApp = [ourDefaults stringForKey:TLGeotagalogPreviousLaunchApp];
		if (!formerApp) formerApp = @"";
		CFPreferencesSetValue(TLICALaunchPath, (CFStringRef)formerApp, TLICAPreferencesSuiteName,
							  kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
		//NSLog(@"Restoring formerApp '%@'", formerApp);
	}
	
	CFPreferencesSynchronize(TLICAPreferencesSuiteName,
							 kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
}

@end


static void TLICM_NotificationRegisteredCallback(ICAHeader* pb) {
	if (pb->err) {
		NSLog(@"Could not register for Image Capture notifications. Got back %i error.", (int)pb->err);
		return;
	}
	// nothing more to do here
}

static void TLICM_NotificationCallback(CFStringRef type, CFDictionaryRef dict) {
	//NSLog(@"%@ - %@\n", (id)type, (id)dict);
	
	/* NOTE: until rdar://problem/6744557 is fixed, the kICARefconKey is invalid
	 on 64-bit: ICA truncates it to 32-bits. As a workaround, we take advantage of
	 the fact that the refcon points to a singleton stored as a global we can access. */
#ifdef __LP64__
	intptr_t refcon = (intptr_t)gTLImageCaptureManager_sharedInstance;
#else
	intptr_t refcon = [(id)CFDictionaryGetValue(dict, kICARefconKey) longValue];
#endif
	NSCAssert([NSThread isMainThread], @"Image Capture notifications must happen on main thread.");
	//NSLog(@"%@", (id)dict);
	ICAObject icao = [(id)CFDictionaryGetValue(dict, kICANotificationDeviceICAObjectKey) intValue];
	TLImageCaptureManager* manager = (TLImageCaptureManager*)refcon;
	if ([(id)type isEqualToString:(id)kICANotificationTypeDeviceAdded]) {
		[manager registerSource:icao];
	}
	else if ([(id)type isEqualToString:(id)kICANotificationTypeDeviceRemoved]) {
		[manager removeSource:icao];
	}
}

static void TLICM_DeviceListDictionaryCallback(ICAHeader* pb) {
	if (pb->err) {
		NSLog(@"Failed to get Image Capture device list dictionary. (Error %i)", (int)pb->err);
		return;
	}
	TLImageCaptureManager* manager = (TLImageCaptureManager*)pb->refcon;
	
	ICACopyObjectPropertyDictionaryPB* pb2 = (void*)pb;
	CFDictionaryRef dict = *(pb2->theDict);
	//NSLog(@"%@\n", (id)dict);
	NSArray* devices = (NSArray*)CFDictionaryGetValue(dict, kICADevicesArrayKey);
	for (NSDictionary* device in devices) {
		// only add device if it is a camera
		if ([[device objectForKey:(id)kTLICADeviceTypeKey]
			 isEqualToString:(NSString*)kICADeviceTypeCamera]) {
			ICAObject object = [[device objectForKey:(id)kTLICAObjectKey] intValue];
			[manager registerSource:object];
		}
	}
	CFRelease(dict);
}

void TLICM_DeviceListCallback(ICAHeader* pb) {
	if (pb->err) {
		NSLog(@"Failed to get Image Capture device object. (Error %i)", (int)pb->err);
		return;
	}
	
	// all we've gotten back is an object id, so we need to fetch its dictionary.
	ICACopyObjectPropertyDictionaryPB pb2 = {};
	pb2.header.refcon = pb->refcon;
	ICAObject listObject = ((ICAGetDeviceListPB*)pb)->object;
	pb2.object = listObject;
	ICAError err = ICACopyObjectPropertyDictionary(&pb2, TLICM_DeviceListDictionaryCallback);
	if (err) {
		NSLog(@"Couldn't get Image Capture device list dictionary. "
			  @"Error %i calling ICACopyObjectPropertyDictionary.", (int)err);
	}
	
	// we can register for notifications with just the object id
	ICARegisterForEventNotificationPB pb3 = {};
	pb3.header.refcon = pb->refcon;
	pb3.objectOfInterest = listObject;
	pb3.eventsOfInterest = (CFArrayRef)[NSArray arrayWithObjects:
										(id)kICANotificationTypeDeviceRemoved,
										(id)kICANotificationTypeDeviceAdded, nil];
	pb3.notificationProc = TLICM_NotificationCallback;
	err = ICARegisterForEventNotification(&pb3, TLICM_NotificationRegisteredCallback);
	if (err) {
		NSLog(@"Couldn't register for Image Capture notifications. "
			  @"Error %i calling ICARegisterForEventNotification.", (int)err);
	}
}

