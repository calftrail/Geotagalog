-- Copyright © 2010 Calf Trail Software, LLC. All rights reserved.

to logUsage()
	log "Usage: iPhotoImport infoPath import|copy path [path ...]"
end logUsage

on run theArguments
	if the (count of theArguments) is 0 then
		set theArguments to {"/Users/nathan/Desktop/importRecord.plist", "copy", "/Users/nathan/Desktop/Sample images/niagara-on-the-lake_post-box_824.jpg", "/Users/nathan/Desktop/Sample images/IMG_3930.CR2"}
	end if
	if (count of theArguments) is less than 3 then
		logUsage()
		return
	end if
	
	local plistPath, method, paths, thePhotos
	set plistPath to the first item of theArguments as text
	set method to the second item of theArguments as text
	set paths to the rest of theArguments
	if method is "import" then
		import_into_iPhoto from paths without forceCopy
		set thePhotos to the result
	else if method is "copy" then
		import_into_iPhoto from paths with forceCopy
		set thePhotos to the result
	else
		logUsage()
		return
	end if
	
	local thePhoto, photoID, originalPath, timestamp, photoInfo, output
	set output to {}
	repeat with thePhoto in thePhotos
		tell application "iPhoto"
			set photoID to (thePhoto's id) - 2 ^ 32
			set timestamp to thePhoto's date
			set originalPath to thePhoto's original path
		end tell
		set photoInfo to {photoID:photoID, timestamp:timestamp, originalPath:originalPath}
		copy photoInfo to end of output
	end repeat
	
	writePlistData from output into plistPath under "importResults"
end run



to import_into_iPhoto from itemPaths given forceCopy:shouldForceCopy
	local albumName, targetAlbum, successfullyImported, previouslyImporting, importedPhotos
	set albumName to "Geotagalog-temporary-" & (unique_identifier() as text)
	tell application "iPhoto"
		new album name albumName
		set targetAlbum to album named albumName
		import from itemPaths to targetAlbum force copy shouldForceCopy
		
		set successfullyImported to false
		set previouslyImporting to true
		repeat while (not successfullyImported)
			set successfullyImported to (first photo in targetAlbum exists)
			-- check import one more time after import completes
			if (not previouslyImporting) then exit repeat
			set previouslyImporting to its importing
			
			-- avoid excessive polling during import
			delay 0.5
		end repeat
		
		set importedPhotos to every photo in targetAlbum
		remove targetAlbum
	end tell
	
	importedPhotos
end import_into_iPhoto

on unique_identifier()
	do shell script "uuidgen"
end unique_identifier


to writePlistData from theValue into thePath under theKey
	tell application "System Events"
		local thePlist
		set thePlist to missing value
		try
			set thePlist to property list file thePath
		end try
		if thePlist is missing value then
			-- path in name property via http://www.macosxautomation.com/applescript/features/propertylists.html
			make new property list file with properties {name:thePath}
			set thePlist to the result
		end if
		make new property list item at end of thePlist with properties {name:theKey, value:theValue}
		log the result
	end tell
end writePlistData
