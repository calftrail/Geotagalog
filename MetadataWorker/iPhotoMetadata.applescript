-- Copyright � 2010 Calf Trail Software, LLC. All rights reserved.

on run theArguments
	--set theArguments to {"photo", 42, "photo", 43, "date", "1266647640", "latitude", 45, "longitude", -120, "rating", "4", "name", "Photo title goes here"}
	
	local arg, argName, photoIDs, metadata, albumName
	set photoIDs to {}
	set metadata to {}
	set argName to missing value
	set albumName to missing value
	repeat with arg in theArguments
		if argName is "photo" then
			copy (arg as number) to the end of photoIDs
		else if argName is "date" then
			set metadata to {date:(date (arg as text))} & metadata
		else if argName is "timestamp" then
			-- accept timestamp as a date alias
			set metadata to {date:(date (arg as text))} & metadata
		else if argName is "latitude" then
			set metadata to {latitude:(arg as number)} & metadata
		else if argName is "longitude" then
			set metadata to {longitude:(arg as number)} & metadata
		else if argName is "altitude" then
			set metadata to {altitude:(arg as number)} & metadata
		else if argName is "comment" then
			set metadata to {comment:(arg as text)} & metadata
		else if argName is "title" then
			set metadata to {title:(arg as text)} & metadata
		else if argName is "name" then
			-- name and title are the same; just map to one
			set metadata to {title:(arg as text)} & metadata
		else if argName is "rating" then
			set metadata to {rating:(arg as number)} & metadata
		else if argName is "album" then
			set albumName to (arg as text)
		else if argName is not missing value then
			log "Unknown argument " & argName
		end if
		
		if argName is missing value then
			set argName to (arg as text)
		else
			set argName to missing value
		end if
	end repeat
	
	local photoID, thePhoto, mustReverseGeocode, theAlbum
	if albumName is not missing value then tell application "iPhoto"
		try
			set theAlbum to first album whose name is albumName
		on error
			new album name albumName
			-- result of previous is invalid, so re-reference
			set theAlbum to first album whose name is albumName
		end try
	end tell
	
	repeat with photoID in photoIDs
		set mustReverseGeocode to false
		tell application "iPhoto" to set thePhoto to photo id (photoID + 2 ^ 32)
		try
			get date of metadata
			tell application "iPhoto" to set date of thePhoto to result
		end try
		try
			get latitude of metadata
			tell application "iPhoto" to set latitude of thePhoto to result
			set mustReverseGeocode to true
		end try
		try
			get longitude of metadata
			tell application "iPhoto" to set longitude of thePhoto to result
			set mustReverseGeocode to true
		end try
		try
			get altitude of metadata
			tell application "iPhoto" to set altitude of thePhoto to result
		end try
		try
			get comment of metadata
			tell application "iPhoto" to set comment of thePhoto to result
		end try
		try
			get title of metadata
			tell application "iPhoto" to set title of thePhoto to result
		end try
		try
			get rating of metadata
			tell application "iPhoto" to set rating of thePhoto to result
		end try
		
		try
			tell application "iPhoto" to add thePhoto to theAlbum
		end try
		
		if mustReverseGeocode then
			tell application "iPhoto" to reverse geocode thePhoto
		end if
	end repeat
end run