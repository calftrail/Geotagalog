/*
 *  TLImageCapture.h
 *  Geotagalog
 *
 *  Created by Nathan Vander Wilt on 5/25/09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#ifndef TLIMAGECAPTURE_H
#define TLIMAGECAPTURE_H

#include <Carbon/Carbon.h>

ICAError TLICAOpenSession(ICAOpenSessionPB* pb, ICACompletion cb);
ICAError TLICACloseSession(ICACloseSessionPB* pb, ICACompletion cb);
ICAError TLICACopyObjectThumbnail(ICACopyObjectThumbnailPB* pb, ICACompletion cb);
ICAError TLICACopyObjectPropertyDictionary(ICACopyObjectPropertyDictionaryPB* pb, ICACompletion cb);
ICAError TLICADownloadFile(ICADownloadFilePB* pb, ICACompletion cb);

extern const CFStringRef kTLICAObjectNameKey;
extern const CFStringRef kTLICADeviceTypeKey;
extern const CFStringRef kTLICAObjectKey;

extern const CFStringRef kTLICAMediaFilesKey;
extern const CFStringRef kTLICAFileTreeKey;
extern const CFStringRef kTLICAImageDateOriginalKey;
extern const CFStringRef kTLICAImageDateDigitizedKey;
extern const CFStringRef kTLICAImageOrientationKey;
extern const CFStringRef kTLICAFileTypeKey;

#endif /* TLIMAGECAPTURE_H */
