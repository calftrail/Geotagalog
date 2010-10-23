//
//  TLNMEASentenceDecoding.h
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 4/21/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TLNMEASentence.h"

@interface TLNMEASentence (TLNMEASentenceDecoding)
- (NSDictionary*)decodeSentence;
@end

extern NSString* const TLNMEASentenceTypeKey;
extern NSString* const TLNMEARecommendedMinimumSentence;
extern NSString* const TLNMEASatellitesActiveSentence;
extern NSString* const TLNMEASatellitesInViewSentence;
extern NSString* const TLNMEAGroundCourseAndSpeedSentence;
extern NSString* const TLNMEAFixDataSentence;
extern NSString* const TLNMEAWaypointSentence;



#pragma mark Recommended Minimumum sentence keys

extern NSString* const TLNMEATimestampKey;
extern NSString* const TLNMEABaseDateKey;
extern NSString* const TLNMEASecondsSinceMidnightUTCKey;
extern NSString* const TLNMEALatitudeKey;
extern NSString* const TLNMEALongitudeKey;
extern NSString* const TLNMEAGroundSpeedKnotsKey;
extern NSString* const TLNMEATrackMadeGoodKey;
extern NSString* const TLNMEAMagneticVariationKey;

extern NSString* const TLNMEAReceiverStatusKey;
extern NSString* const TLNMEAReceiverStatusValid;
extern NSString* const TLNMEAReceiverStatusInvalid;

extern NSString* const TLNMEAModeIndicatorKey;
extern NSString* const TLNMEAModeIndicatorAutonomous;
extern NSString* const TLNMEAModeIndicatorDifferential;
extern NSString* const TLNMEAModeIndicatorEstimated;
extern NSString* const TLNMEAModeIndicatorManualInput;
extern NSString* const TLNMEAModeIndicatorSimulated;
extern NSString* const TLNMEAModeIndicatorInvalid;


#pragma mark Satellites Active sentence keys

extern NSString* const TLNMEAPositionDOPKey;
extern NSString* const TLNMEAHorizontalDOPKey;
extern NSString* const TLNMEAVerticalDOPKey;
extern NSString* const TLNMEASatellitesUsedArrayKey;

extern NSString* const TLNMEASelectionModeKey;
extern NSString* const TLNMEASelectionModeManual;
extern NSString* const TLNMEASelectionModeAutomatic;

extern NSString* const TLNMEAFixModeKey;
extern NSString* const TLNMEAFixModeFixNotAvailable;
extern NSString* const TLNMEAFixMode2D;
extern NSString* const TLNMEAFixMode3D;


#pragma mark Satellites In View sentence keys

extern NSString* const TLNMEAGroupedMessagesTotalKey;
extern NSString* const TLNMEAGroupedMessageNumberKey;
extern NSString* const TLNMEATotalSatellitesInViewKey;

extern NSString* const TLNMEASatelliteInformationArrayKey;
extern NSString* const TLNMEASatelliteIDKey;
extern NSString* const TLNMEASatelliteElevationKey;
extern NSString* const TLNMEASatelliteAzimuthKey;
extern NSString* const TLNMEASatelliteSignalToNoiseKey;


#pragma mark Geographic Position sentence keys

// TLNMEALatitudeKey
// TLNMEALongitudeKey
// TLNMEAReceiverStatusKey
// TLNMEAModeIndicatorKey
// TLNMEASecondsSinceMidnightUTCKey


#pragma mark Ground Course and Speed sentence keys

// TLNMEATrackMadeGoodKey
// TLNMEAGroundSpeedKnotsKey
// TLNMEAModeIndicatorKey
extern NSString* const TLNMEATrackMadeGoodMagneticKey;
extern NSString* const TLNMEAGroundSpeedKilometersKey;


#pragma mark Fix Data sentence keys

// TLNMEASecondsSinceMidnightUTCKey
// TLNMEALatitudeKey
// TLNMEALongitudeKey
// TLNMEAModeIndicatorKey
// TLNMEAHorizontalDOPKey
extern NSString* const TLNMEANumericModeKey;
extern NSString* const TLNMEASatellitesUsedCountKey;
extern NSString* const TLNMEAMeanSeaLevelAltitudeKey;
extern NSString* const TLNMEAGeoidSeparationKey;
extern NSString* const TLNMEADifferentialCorrectionAge;
extern NSString* const TLNMEADifferentialReferenceID;


#pragma mark Waypoint

// TLNMEALatitudeKey
// TLNMEALongitudeKey
extern NSString* const TLNMEANameKey;
