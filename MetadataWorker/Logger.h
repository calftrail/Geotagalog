//
//  Logger.h
//  MetadataWorker
//
//  Created by Nathan Vander Wilt on 2/22/10.
//  Copyright 2010 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


extern NSString* const LoggerDomain;

extern NSString* const LoggerDidUpdateNotification;
extern NSString* const LoggerMessageErrors;

enum {
	LoggerDebugging = -1,
	LoggerInformative = 0,
	LoggerWarning = 1,
	LoggerError = 2,
	LoggerInternalError = 3
};
typedef NSInteger LoggerSeverity;

@interface Logger : NSObject {
@private
	NSManagedObjectContext* logContext;
}

+ (Logger*)sharedLogger;

// conveniences on sharedLogger
+ (void)logInfo:(NSDictionary*)errInfo severity:(LoggerSeverity)severity;
+ (void)debugLog:(NSString*)format, ... NS_FORMAT_FUNCTION(1,2);
+ (void)informativeLog:(NSString*)format, ... NS_FORMAT_FUNCTION(1,2);

- (void)beginLoggingToURL:(NSURL*)storeURL;

/* NOTE: this error must be in the ErrorLoggerDomain, with code set to severity.
 The following keys must be set:
 NSLocalizedDescriptionKey - shown to user
 NSLocalizedRecoverySuggestionErrorKey - shown as more info to user (not required for informative)
 NSLocalizedFailureReasonErrorKey - may be sent for debugging (not required for informative)
 */
- (void)logError:(NSError*)error;
- (NSArray*)errors;
- (void)clearAll;
- (void)clearOld;

@end
