//
//  TLFilePhotoSource.m
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 6/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TLFilePhotoSource.h"

#import "TLFileSourceItem.h"

#import "TLMainThreadPerformer.h"
#import "NSFileManager+TLExtensions.h"
#import "TLRandom.h"


#ifdef __LP64__
static const NSUInteger TLFilePhotoSourceItemLimit = 2500;
#else
static const NSUInteger TLFilePhotoSourceItemLimit = 1000;
#endif


extern NSArray* TLNSArrayShuffle(NSArray* array);

@interface TLFilePhotoSource ()
@property (nonatomic, copy) NSString* name;
@property (nonatomic, retain) NSImage* icon;
@property (nonatomic, retain) NSError* error;
@property (nonatomic, assign, readwrite) BOOL isCurrent;
@property (nonatomic, assign, readwrite) BOOL isWorking;
@property (retain) NSOperationQueue* workQueue;
@property (nonatomic, retain) NSOperation* finalOperation;
@property (nonatomic, retain) NSMutableSet* directlyAddedPaths;
@property (nonatomic, retain) NSMutableSet* allPaths;
- (void)updateName;
- (void)enqueuePaths:(NSSet*)filePaths;
@end

static NSString* const TLFPSObservationContext = @"TLFilePhotoSource_ObservationContext";


@interface TLFPSCreateItemOperation : NSOperation {
@private
	TLFilePhotoSource* source;
	NSString* path;
}
@property (nonatomic, retain) TLFilePhotoSource* source;
@property (nonatomic, copy) NSString* path;
@end


@implementation TLFilePhotoSource

@synthesize name;
@synthesize icon;
@synthesize error;
@synthesize isCurrent;
@synthesize isWorking;
@synthesize items = mutableItems;
@synthesize workQueue;
@synthesize finalOperation;
@synthesize directlyAddedPaths;
@synthesize allPaths;


- (id)init {
	self = [super init];
	if (self) {
		mutableItems = [NSMutableSet new];
		[self setWorkQueue:[[NSOperationQueue new] autorelease]];
		[self setDirectlyAddedPaths:[NSMutableSet set]];
		[self setAllPaths:[NSMutableSet set]];
		[self updateName];
		
		[self addObserver:self
			   forKeyPath:@"finalOperation.isFinished"
				  options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial)
				  context:TLFPSObservationContext];
	}
	return self;
}

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"finalOperation.isFinished"];
	[self setName:nil];
	[self setIcon:nil];
	[mutableItems release];
	[self setWorkQueue:nil];
	[self setFinalOperation:nil];
	[self setDirectlyAddedPaths:nil];
	[self setAllPaths:nil];
	[super dealloc];
}


- (void)observeValueForKeyPath:(NSString*)keyPath
					  ofObject:(id)object
						change:(NSDictionary*)change
					   context:(void*)context
{
	//NSLog(@"observed %@: %@", keyPath, change);
    if (context == TLFPSObservationContext) {
		if ([keyPath isEqualToString:@"finalOperation.isFinished"]) {
			id newValue = [change objectForKey:NSKeyValueChangeNewKey];
			BOOL isFinished = (newValue == [NSNull null]) ? YES : [newValue boolValue];
			[[self tlMainThreadProxy] setIsCurrent:isFinished];
			[[self tlMainThreadProxy] setIsWorking:!isFinished];
		}
	}
	else {
		[super observeValueForKeyPath:keyPath
							 ofObject:object
							   change:change
							  context:context];
	}
}


- (void)engage {
	[super engage];
	[self enqueuePaths:[self directlyAddedPaths]];
}

- (void)disengage {
	[mutableItems removeAllObjects];
	[[self allPaths] removeAllObjects];
	[[self workQueue] cancelAllOperations];
	[self setError:nil];
	[super disengage];
}

- (void)addPaths:(NSSet*)newFilePaths {
	[[self directlyAddedPaths] unionSet:newFilePaths];
	[self updateName];
	if ([self isEngaged]) {
		[self enqueuePaths:newFilePaths];
	}
}

- (void)addItemsObject:(TLFileSourceItem*)newItem {
	[mutableItems addObject:newItem];
}

- (void)removeItemsObject:(TLFileSourceItem*)oldItem {
	// we don't remove items, this just enables automatic KVO
	(void)oldItem;
	[self doesNotRecognizeSelector:_cmd];
}

- (void)acceptItem:(TLFileSourceItem*)newItem {
	NSAssert([NSThread isMainThread], @"Items must be added from main thread");
	
	if (![self isEngaged]) {
		// we are disengaged, silently drop item
		(void)newItem;
	}
	else if ([[self items] count] < TLFilePhotoSourceItemLimit) {
		[self addItemsObject:newItem];
		[[self allPaths] addObject:[[newItem originalURL] path]];
	}
	else {
		NSDictionary* errInfo = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"Too many items for source.", NSLocalizedDescriptionKey,
								 @"Due to resource limitations in the current version of Geotagalog, "
								 @"you should not add any more files to this session. Please split your "
								 @"work into smaller sets.", NSLocalizedRecoverySuggestionErrorKey, nil];
		NSError* fullError = [NSError errorWithDomain:@"com.calftrail.geotagalog"
												 code:1000
											 userInfo:errInfo];
		[self setError:fullError];
		[[self workQueue] cancelAllOperations];
	}
}

- (void)updateName {
	NSAssert([NSThread isMainThread], @"Name must be updated from main thread");
	
	NSUInteger numPaths = [[self directlyAddedPaths] count];
	NSString* newName = nil;
	switch (numPaths) {
		case 0:
			newName = @"File source";
			break;
		case 1:
		{
			NSString* path = [[self directlyAddedPaths] anyObject];
			newName = [path lastPathComponent];
			break;
		}
		default:
			newName = @"Multiple files/folders";
	}
	[self setName:newName];
}

- (void)enqueuePaths:(NSSet*)filePaths {
	NSAssert([NSThread isMainThread], @"Paths must be enqueued from main thread");
	if (![self isEngaged] ||
		[[self items] count] >= TLFilePhotoSourceItemLimit)
	{
		// stop enqueuing paths
		return;
	}
	
	NSOperation* markerOperation = [[NSOperation new] autorelease];
	NSArray* shuffledPaths = TLNSArrayShuffle([filePaths allObjects]);
	for (NSString* path in shuffledPaths) {
		if ([[self allPaths] containsObject:path]) {
			continue;
		}
		TLFPSCreateItemOperation* createItemOperation = [[TLFPSCreateItemOperation new] autorelease];
		[markerOperation addDependency:createItemOperation];
		[createItemOperation setSource:self];
		[createItemOperation setPath:path];
		[[self workQueue] addOperation:createItemOperation];
	}
	if ([self finalOperation]) {
		[markerOperation addDependency:[self finalOperation]];
	}
	[self setFinalOperation:markerOperation];
	[[self workQueue] addOperation:markerOperation];
}

@end


@implementation TLFPSCreateItemOperation

@synthesize source;
@synthesize path;

- (void)dealloc {
	[self setSource:nil];
	[self setPath:nil];
	[super dealloc];
}

- (void)addSuboperationsForFolder:(NSString*)folderPath {
	if ([self isCancelled]) return;
	
	//NSLog(@"Adding suboperations for %@", folderPath);
	NSArray* filenames = [[NSFileManager tl_threadManager] contentsOfDirectoryAtPath:folderPath
																			   error:NULL];
	if (!filenames || [self isCancelled]) return;
	
	NSMutableSet* fullPaths = [NSMutableSet set];
	for (NSString* filename in filenames) {
		if ([self isCancelled]) return;
		if (![filename length] || [filename characterAtIndex:0] == '.') {
			// skip hidden files
			continue;
		}
		NSString* fullItemPath = [folderPath stringByAppendingPathComponent:filename];
		[fullPaths addObject:fullItemPath];
	}
	if (![self isCancelled]) {
		[[[self source] tlMainThreadProxy] enqueuePaths:fullPaths];
	}
}

- (void)addItemForPath:(NSString*)itemPath {
	if ([self isCancelled]) return;
	
	BOOL isDirectory = NO;
	BOOL exists = [[NSFileManager tl_threadManager] fileExistsAtPath:[self path]
														isDirectory:&isDirectory];
	if (!exists || [self isCancelled]) return;
	
	if (isDirectory) {
		[self addSuboperationsForFolder:itemPath];
	}
	else {
		NSURL* originalURL = [NSURL fileURLWithPath:itemPath isDirectory:NO];
		TLFileSourceItem* item = [[[TLFileSourceItem alloc] initWithSource:[self source]
																  originalURL:originalURL
																	 error:NULL] autorelease];
		if (item && ![self isCancelled]) {
			[[[self source] tlMainThreadProxy] acceptItem:item];
		}
	}
}

-(void)main {
    if ([self isCancelled]) return;
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	[self addItemForPath:[self path]];
	[pool drain];
}

@end


NSArray* TLNSArrayShuffle(NSArray* array) {
	// http://en.wikipedia.org/wiki/Fisher-Yates_shuffle
	NSMutableArray* mutableArray = [array mutableCopy];
	TLRandomInit();
	NSUInteger itemIdx = [mutableArray count];
	while (itemIdx-- > 1) {
		NSUInteger partnerIdx = NSUIntegerMax;
		do { partnerIdx = (itemIdx + 1) * TLRandom(); } while (partnerIdx > itemIdx);
		[mutableArray exchangeObjectAtIndex:itemIdx withObjectAtIndex:partnerIdx];
	}
	return [mutableArray autorelease];
}
