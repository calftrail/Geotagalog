//
//  TLNMEAErrors.h
//  Geotagalog
//
//  Created by Nathan Vander Wilt on 4/21/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString* const TLNMEAErrorDomain;

enum {
	TLNMEASentenceBadCharactersError = 1,	// field data not ASCII
	TLNMEASentenceInvalidHeaderError,		// problem parsing header (e.g. too long/short)
	TLNMEASentenceNotFoundError,			// no sentence in line
	TLNMEASentenceInvalidChecksumError,		// checksum itself is icky
	TLNMEASentenceCorruptError,				// sentence doesn't match checksum
	TLNMEASentenceTooLong,
	TLNMEAFileNoSentences
};
