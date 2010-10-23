//
//  TLIGCFileConversion.m
//  Tagalog
//
//  Created by Nathan Vander Wilt on 10/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TLIGCFileConversion.h"

#import "TLTrack.h"
#import "TLLocation.h"
#import "TLTimestamp.h"
#import "TLWaypoint.h"

@interface NSDate (TLIGCAdditions)
- (NSDate*)tl_nextDay;
@end


@implementation TLIGCFile (TLIGCFileConversion)

- (NSArray*)extractTracks:(NSError**)err {
	NSDate* baseDate = [[self header] objectForKey:TLIGCDateKey];
	if (!baseDate) {
		if (err) {
			*err = [NSError errorWithDomain:NSCocoaErrorDomain
									   code:NSFileReadCorruptFileError
								   userInfo:nil];
		}
		return nil;
	}
	
	NSMutableArray* tracks = [NSMutableArray array];
	NSMutableArray* currentWaypoints = [NSMutableArray array];
	int fixIdx = 0;
	NSDate* prevDate = nil;
	for (NSDictionary* fixInfo in [self fixes]) {
		++fixIdx;
		
		TLTimestamp* timestamp = nil;
		NSNumber* timeValue = [fixInfo objectForKey:TLIGCFixTimeKey];
		if (timeValue) {
			NSTimeInterval dayTime = [timeValue doubleValue];
			NSDate* date = [baseDate addTimeInterval:dayTime];
			if (prevDate && [date isLessThan:prevDate]) {
				//printf(" !!! REJIGGERING BASE DATE @ fix %i !!! \n", fixIdx);
				baseDate = [baseDate tl_nextDay];
				date = [baseDate addTimeInterval:dayTime];
				//NSLog(@"   \n\nprevDate: %@\n    date: %@", prevDate, date);
			}
			
			if (!prevDate || [prevDate isLessThan:date]) {
				timestamp = [TLTimestamp timestampWithTime:date
												  accuracy:TLTimestampAccuracyUnknown];
			}
			else if ([prevDate isEqual:date]) {
				/* NOTE: It is common for recorders to repeat the last fix
				 at the end of the file. Just silently ignore duplicate timestamps. */
				//NSLog(@"Identical timestamps found @ fix %i", fixIdx);
			}
			else if (prevDate) {
				NSLog(@"Out-of-order timestamp @ fix %i.", fixIdx);
			}
			
			prevDate = date;
		}
		
		BOOL validFix = NO;
		if ([[fixInfo objectForKey:TLIGCFixValidityKey] isEqual:TLIGCFixValidity3D]) {
			/* NOTE: A 2D fix validity can also represent an invalid fix,
			 and under normal circumstances (theoretically and based on sample files)
			 an aircraft's GNSS should be able to obtain a 3D fix.
			 So we only accept 3D fixes.
			 The only 2D fix example found is 567A0UP2, where they are invalid */
			validFix = YES;
		}
		
		TLLocation* location = nil;
		NSNumber* latValue = [fixInfo objectForKey:TLIGCFixLatitudeKey];
		NSNumber* lonValue = [fixInfo objectForKey:TLIGCFixLongitudeKey];
		if (validFix && latValue && lonValue) {
			TLCoordinate coord = TLCoordinateMake([latValue doubleValue],
												  [lonValue doubleValue]);
			
			NSNumber* accValue = [fixInfo objectForKey:TLIGCFixAccuracyKey];
			TLCoordinateAccuracy acc = (accValue ?
										[accValue doubleValue] : TLCoordinateAccuracyUnknown);
			NSNumber* altValue = [fixInfo objectForKey:TLIGCFixGeoidAltitudeKey];
			TLCoordinateAltitude alt = (altValue ?
										[altValue doubleValue] : TLCoordinateAltitudeUnknown);
			location = [TLLocation locationWithCoordinate:coord
									   horizontalAccuracy:acc
												 altitude:alt
										 verticalAccuracy:TLCoordinateAccuracyUnknown];
		}
		
		if (location && timestamp) {
			[currentWaypoints addObject:
			 [TLWaypoint waypointWithLocation:location
									timestamp:timestamp]];
		}
		else {
			// make track from current waypoints in (unlikely) event of a split
			if ([currentWaypoints count]) {
				TLTrack* track = [[[TLTrack alloc] initWithWaypoints:currentWaypoints] autorelease];
				[tracks addObject:track];
				currentWaypoints = [NSMutableArray array];
			}
		}
	}
	if ([currentWaypoints count]) {
		TLTrack* track = [[[TLTrack alloc] initWithWaypoints:currentWaypoints] autorelease];
		[tracks addObject:track];
	}
	//NSLog(@"Read %lu tracks\n", (long unsigned)[tracks count]);
	return tracks;
}

- (NSArray*)extractWaypoints:(NSError**)err {
	(void)err;
	return [NSArray array];
}

@end


@implementation NSDate (TLIGCAdditions)

- (NSDate*)tl_nextDay {
	NSCalendar* gregorian = [[[NSCalendar alloc]
							  initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
	NSDateComponents* comps = [[NSDateComponents new] autorelease];
	[comps setDay:1];
	return [gregorian dateByAddingComponents:comps toDate:self options:0];
}

@end
