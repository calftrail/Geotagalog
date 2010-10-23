-- Copyright © 2010 Calf Trail Software, LLC. All rights reserved.

on run theArguments
	if the (count of theArguments) is 0 then
		set theArguments to {"4656"}
	end if
	
	local photoID, thePhoto, originals
	set photoID to first item of theArguments as integer
	set originals to {}
	
	tell application "iPhoto"
		set thePhoto to photo id (photoID + 2 ^ 32)
		copy original path of thePhoto to the end of originals
		copy image path of thePhoto to the end of originals
	end tell
	
	set text item delimiters to linefeed
	return originals as text
end run