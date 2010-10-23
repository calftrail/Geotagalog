//
//  SendController.m
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/26/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import "SendController.h"

NSString* const SendControllerDidSendLogNotification = @"SendControllerDidSendLog";

static NSString* const PostLocation = @"http://example.com/cgi-bin/TLCrashReporter";
static NSString* KVOContext = @"SendController KVO context";

@interface NSString (TLURLEncoding)
- (NSString*)tl_urlEncodeFormValue;
@end

@implementation NSString (TLURLEncoding)
- (NSString*)tl_urlEncodeFormValue {
	CFStringRef v = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self,
															NULL, CFSTR("?=&+"), kCFStringEncodingUTF8);
	return [(id)CFMakeCollectable(v) autorelease];
}
@end


@implementation SendController

@synthesize readyToSend;
@synthesize userMessage;
@synthesize logMessage;


- (id)initWithWindow:(NSWindow*)window {
	self = [super initWithWindow:window];
	if (self) {
		[self addObserver:self forKeyPath:@"userMessage"
				  options:NSKeyValueObservingOptionNew context:&KVOContext];
		
		id defaults = [NSUserDefaultsController sharedUserDefaultsController];
		NSKeyValueObservingOptions opts = NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial;
		[defaults addObserver:self forKeyPath:@"values.ResponseDesired"
					  options:opts context:&KVOContext];
		[defaults addObserver:self forKeyPath:@"values.RespondToEmail"
					  options:opts context:&KVOContext];
	}
	return self;
}

- (void)finalize {
	id defaults = [NSUserDefaultsController sharedUserDefaultsController];
	[defaults removeObserver:self forKeyPath:@"ResponseDesired"];
	[defaults removeObserver:self forKeyPath:@"RespondToEmail"];
	[super finalize];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object
						change:(NSDictionary*)change context:(void*)context
{
	if (context == &KVOContext) {
		id defaults = [NSUserDefaults standardUserDefaults];
		if (![self.userMessage length]) {
			self.readyToSend = NO;
		}
		else if ([defaults boolForKey:@"ResponseDesired"] &&
				 ![[defaults stringForKey:@"RespondToEmail"] length])
		{
			self.readyToSend = NO;
		}
		else {
			self.readyToSend = YES;
		}
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}


- (IBAction)sendLog:(id)sender {
	[[self window] orderOut:sender];
	
	NSString* description = self.userMessage;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ResponseDesired"]) {
		NSString* email = [[NSUserDefaults standardUserDefaults] stringForKey:@"RespondToEmail"];
		description = [description stringByAppendingFormat:@"\n\nNOTE: Please respond to %@", email];
	}
	NSString* details = self.logMessage;
	[[self class] submitReport:description details:details];
	[[NSNotificationCenter defaultCenter] postNotificationName:SendControllerDidSendLogNotification
														object:self];
}

- (IBAction)cancel:(id)sender {
	[[self window] orderOut:sender];
}


#pragma mark Posting

+ (void)postInformation:(NSDictionary*)postInfo toURL:(NSURL*)postURL {
	NSMutableString* post = [NSMutableString string];
	for (NSString* key in postInfo) {
		id val = [postInfo objectForKey:key];
		NSString* value = [[val description] tl_urlEncodeFormValue];
		if ([post length]) [post appendString:@"&"];
		[post appendFormat:@"%@=%@", key, value];
	}
	NSData* postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
	NSString* postLength = [NSString stringWithFormat:@"%lu", (size_t)[postData length]];
	
    NSMutableURLRequest* req = [[NSMutableURLRequest new] autorelease];
	[req setHTTPMethod:@"POST"];
	[req setURL:postURL];
    [req setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	[req setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [req setHTTPBody:postData];
	
	NSURLConnection* connection = [NSURLConnection connectionWithRequest:req delegate:self];
    CFRetain(connection);
}

+ (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
	NSLog(@"Could not post information: %@\n", error);
    CFRelease(connection);
}

+ (void)connectionDidFinishLoading:(NSURLConnection*)connection {
    CFRelease(connection);
}

+ (void)submitReport:(NSString*)description details:(NSString*)details {
	NSParameterAssert(description != nil);
	NSParameterAssert(details != nil);
	NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
						  description, @"description", details, @"log", nil];
	[self postInformation:info toURL:[NSURL URLWithString:PostLocation]];
}

@end
