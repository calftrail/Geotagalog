//
//  ProjectController.h
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 1/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TLMapView;

@class PhotoSourceController;
@class TimeOffsetController;
@class MetadataController;
@class ExportController;

@interface ProjectController : NSObject {
	IBOutlet NSWindow* window;
	__weak IBOutlet TLMapView* mapView;
	__weak IBOutlet NSButton* exportButton;
	
	IBOutlet PhotoSourceController* sourceController;
	IBOutlet TimeOffsetController* offsetController;
	IBOutlet MetadataController* metadataController;
@private
	NSMutableSet* tracks;
	NSMutableSet* waypoints;
	ExportController* exportController;
}

@property (nonatomic, readonly) PhotoSourceController* sourceController;

@property (nonatomic, readonly) NSWindow* window;

- (id)initWithTracks:(NSArray*)theTracks;
- (void)addTracks:(NSSet*)newTracks;

- (void)addWaypoints:(NSSet*)newWaypoints;

@property (nonatomic, readonly) NSSet* tracks;
@property (nonatomic, readonly) NSSet* waypoints;



- (BOOL)isExporting;
- (IBAction)beginExport:(id)sender;

@end
