on run theArguments
	if the (count of theArguments) is 0 then return
	if application id "com.calftrail.geotagalog-mw" is not running then
		try
			-- MetadataWorker is not scriptable, so this will fail
			-- But! it launches the app, which is what we want.
			set metadataWorker to first item of theArguments as text
			get windows of application metadataWorker
		end try
	end if
end run