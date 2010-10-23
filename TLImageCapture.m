/*
 *  TLImageCapture.m
 *  Geotagalog
 *
 *  Created by Nathan Vander Wilt on 5/25/09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#include "TLImageCapture.h"

#import <Cocoa/Cocoa.h>


/* See rdar://problem/6939470 for issues concerning these keys' namesakes */
const CFStringRef kTLICAObjectNameKey = CFSTR("ifil");
const CFStringRef kTLICADeviceTypeKey = CFSTR("device type");
const CFStringRef kTLICAObjectKey = CFSTR("icao");

/* These keys are extensions, it would seem */
const CFStringRef kTLICAMediaFilesKey = CFSTR("data");
const CFStringRef kTLICAFileTreeKey = CFSTR("tree");
const CFStringRef kTLICAImageDateOriginalKey = CFSTR("9003");
const CFStringRef kTLICAImageDateDigitizedKey = CFSTR("9004");
const CFStringRef kTLICAImageOrientationKey = CFSTR("0112");
const CFStringRef kTLICAFileTypeKey = CFSTR("file");

/*
 According to http://developer.apple.com/documentation/Carbon/Conceptual/ImageCaptureServicesProgrammingGuide/03HowtoWriteanImageCaptureApplication/03HowtoWriteanImageCaptureApplication.html
 these six function calls will be all we usually need:
 
 ICAGetDeviceList
 ICARegisterForEventNotification
 ICACopyObjectPropertyDictionary
 ICAOpenSession
 ICADownloadFile
 ICACloseSession
 
 Conveniently, all these functions (and several others)
 follow the same basic pattern:
 */
typedef ICAError (*TLICAEntry)(ICAHeader* pb, ICACompletion cb);


@interface TLICAHelper : NSObject {
@private
	ICAHeader* pbPtr;
	size_t pbSize;
	TLICAEntry icaFunction;
	unsigned long originalRefcon;
	NSCondition* workingLock;
	BOOL done;
	ICAError error;
}
+ (id)helper;
// turns a synchronous call into an asynchronous main thread operation
- (ICAError)callFunction:(TLICAEntry)theICAFunction
		   withParameter:(ICAHeader*)thePB
				  ofSize:(size_t)thePBSize
			 andCallback:(ICACompletion)theCB;
@end

// private properties
@interface TLICAHelper ()
@property (nonatomic, assign) ICAHeader* pbPtr;
@property (nonatomic, assign) size_t pbSize;
@property (nonatomic, assign) TLICAEntry icaFunction;
@property (nonatomic, assign) unsigned long originalRefcon;
@property (nonatomic, retain) NSCondition* workingLock;
@property (nonatomic, assign) BOOL done;
@property (nonatomic, assign) ICAError error;
@end


static void TLICACompletion(ICAHeader* newPB) {
	//NSCAssert([NSThread isMainThread], @"Completion callback not on main thread");
	TLICAHelper* helper = [(id)newPB->refcon autorelease];
	[[helper workingLock] lock];
	ICAHeader* helperPB = [helper pbPtr];
	if (newPB->err) {
		ICAError err = newPB->err;
		[helper setError:err];
		helperPB->err = err;
	}
	else {
		// TODO: this does not keep indirect pointers alive. this is a problem!
		memmove(helperPB, newPB, [helper pbSize]);
	}
	helperPB->refcon = [helper originalRefcon];
	[helper setDone:YES];
	[[helper workingLock] broadcast];
	[[helper workingLock] unlock];
}


@implementation TLICAHelper

@synthesize pbPtr;
@synthesize pbSize;
@synthesize icaFunction;
@synthesize originalRefcon;
@synthesize workingLock;
@synthesize done;
@synthesize error;

- (void)dealloc {
	[self setWorkingLock:nil];
	[super dealloc];
}

+ (id)helper {
	return [[[self class] new] autorelease];
}

- (void)doFunctionCall {
	ICAHeader* pb = [self pbPtr];
	pb->refcon = (intptr_t)[self retain];
	ICAError err = [self icaFunction](pb, TLICACompletion);
	if (err) {
		[[self workingLock] lock];
		[self setError:err];
		[self setDone:YES];
		[[self workingLock] broadcast];
		[[self workingLock] unlock];
	}
}

/* This function may be called on a background thread and should not return
 until it is completed. We assume that ICA is not background thread safe,
 but we do not want to block the main thread with the synchronous API.
 
 So, we must call the asynchronous API on the main thread, and block this
 background thread until the main thread gets all necessary callbacks. */
- (ICAError)callFunction:(TLICAEntry)theICAFunction
		   withParameter:(ICAHeader*)thePB
				  ofSize:(size_t)thePBSize
			 andCallback:(ICACompletion)theCB
{
	if ([NSThread isMainThread]) {
		return theICAFunction(thePB, theCB);
	}
	NSParameterAssert(theCB == NULL);
	
	[self setPbPtr:thePB];
	[self setPbSize:thePBSize];
	[self setIcaFunction:theICAFunction];
	[self setOriginalRefcon:thePB->refcon];
	[self setWorkingLock:[[NSCondition new] autorelease]];
	
	[[self workingLock] lock];
	[self performSelectorOnMainThread:@selector(doFunctionCall)
						   withObject:nil
						waitUntilDone:NO];
	while (![self done]) {
		[[self workingLock] wait];
	}
	[[self workingLock] unlock];
	
	thePB->err = [self error];
	return [self error];
}

@end


ICAError TLICADownloadFile(ICADownloadFilePB* pb, ICACompletion cb) {
	return [[TLICAHelper helper] callFunction:(TLICAEntry)ICADownloadFile
								withParameter:(ICAHeader*)pb
									   ofSize:sizeof(ICADownloadFilePB)
								  andCallback:cb];
}

ICAError TLICACopyObjectPropertyDictionary(ICACopyObjectPropertyDictionaryPB* pb, ICACompletion cb) {
	NSCAssert(cb || pb->theDict,
			  @"ImageCapture client must provide theDict reference storage "
			  @"when calling TLICACopyObjectPropertyDictionary synchronously");
	return [[TLICAHelper helper] callFunction:(TLICAEntry)ICACopyObjectPropertyDictionary
								withParameter:(ICAHeader*)pb
									   ofSize:sizeof(ICACopyObjectPropertyDictionaryPB)
								  andCallback:cb];
}

ICAError TLICACopyObjectThumbnail(ICACopyObjectThumbnailPB* pb, ICACompletion cb) {
	NSCAssert(cb || pb->thumbnailData,
			  @"ImageCapture client must provide thumbnailData reference storage "
			  @"when calling TLICACopyObjectThumbnail synchronously");
	return [[TLICAHelper helper] callFunction:(TLICAEntry)ICACopyObjectThumbnail
								withParameter:(ICAHeader*)pb
									   ofSize:sizeof(ICACopyObjectThumbnailPB)
								  andCallback:cb];
}

ICAError TLICAOpenSession(ICAOpenSessionPB* pb, ICACompletion cb) {
	return [[TLICAHelper helper] callFunction:(TLICAEntry)ICAOpenSession
								withParameter:(ICAHeader*)pb
									   ofSize:sizeof(ICAOpenSessionPB)
								  andCallback:cb];
}

ICAError TLICACloseSession(ICACloseSessionPB* pb, ICACompletion cb) {
	return [[TLICAHelper helper] callFunction:(TLICAEntry)ICACloseSession
								withParameter:(ICAHeader*)pb
									   ofSize:sizeof(ICACloseSessionPB)
								  andCallback:cb];
}


