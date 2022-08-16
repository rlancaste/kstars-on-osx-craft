#/bin/zsh

#This script is meant to search for issues in the Bundled KStars App that could cause issues with those trying to run it on another computer

DIR=$(dirname "$0")

#Files in these locations can be safely ignored.
	IGNORED_OTOOL_OUTPUT="/usr/lib/|/System/"

	# This fuction is meant to check for IDs that are not rpaths or full paths, since that causes linking problems later.
	function checkForBadID
	{
		target=$1
		
		itsID=$(otool -D $target | sed -n '2 p')
		if [[ "$itsID" != @rpath* ]]
		then
			echo "$target has the wrong install ID: $itsID"
		fi
		
	}
	
	#This function is intended to search for links that are not rpaths
	function checkForBadPaths
	{
		target=$1
        	
		entries=$(otool -L $target | sed '1d' | awk '{print $1}' | egrep -v "$IGNORED_OTOOL_OUTPUT")
		#echo "Processing $target"
		
		for entry in $entries
		do
		#echo "$entry"
			if [[ "$entry" != @rpath* ]] && [[ $(basename "$entry") != $(basename $target) ]]
			then
				echo "$target has a bad path: $entry"
			fi
		done
		
	}
	
	#This function is intended to search for links that go to non-existant files
	function checkForBrokenLinks
	{
		target=$1

		entries=$(otool -L $target | sed '1d' | awk '{print $1}' | egrep -v "$IGNORED_OTOOL_OUTPUT")
		#echo "Processing $target"

		for entry in $entries
		do
		#echo "$entry"
			if [[ "$entry" == @rpath* ]]
			then
				truePath=${APP}/Contents/Frameworks/"${entry:7}"
				if [[ ! -f "${truePath}" ]]
				then
					echo "$target points to a file that doesn't exist: $entry points to: $truePath"
				fi
			fi
			
			if [[ "$entry" == @executable_path* ]]
			then
				truePath=${APP}/Contents/MacOS/"${entry:17}"
				if [[ ! -f "${truePath}" ]]
				then
					echo "$target points to a file that doesn't exist: $entry points to: $truePath"
				fi
			fi
			
			if [[ "$entry" == @loader_path* ]]
			then
				truePath=$(echo $target | awk -F $entry '{print $1}')/"${entry:13}"
				if [[ ! -f "${truePath}" ]]
				then
					echo "$target points to a file that doesn't exist: $entry points to: $truePath"
				fi
			fi

			if [[ "$entry" == /* ]]
			then
				if [[ ! -f "${entry}" ]]
				then
					echo "$target points to a file that doesn't exist: $entry"
				fi
			fi
		done

	}
	
	function processDirectory
	{
		directoryName=$1
		directory=$2
		#statusBanner "Processing all of the $directoryName files in $directory"
		for file in ${directory}/*
		do
    		base=$(basename $file)
    		
    		if [[ "$file" != *".dSYM" ]] && [[ "$file" != *".framework" ]] && [[ "$file" == ${DMG_DIR}/* ]]
    		then
				if [[ -f "$file" ]]
				then
					# Note: I don't think we need to check the install ID when packaging, everything is already linked
					#statusBanner "Processing $directoryName file $base"
					#if [[ "$file" == *".dylib" ]]
					#then
					#	checkForBadID $file
					#fi
					
					checkForBadPaths $file
					checkForBrokenLinks $file
				else
					processDirectory $base $file
				fi
			fi
		done

	}
	
	
	
#########################################################################
#This is where the main part of the script starts!!
#

#This code should only run if the user is running the fix-libraries script without running build-kstars or generate-dmg
if [ -z "${ASTRO_ROOT}" ]
then
	source ${DIR}/build-env.sh
fi

#This should stop the script so that it doesn't run if these paths are blank.
#That way it doesn't try to edit /Applications instead of ${CRAFT_DIR}/Applications for example
	if [ -z "${DIR}" ]
	then
		echo "directory error! aborting Script"
		exit 9
	fi

#This sets some important variables.
	DMG_DIR="${ASTRO_ROOT}/KStarsDMG"
	APP="${DMG_DIR}/KStars.app"

#This code checks for issues in the KStars App Bundle
	if [ -e ${DMG_DIR} ] && [ -e ${APP} ]
	then
		statusBanner "Searching for issues in the KStars Bundle's MacOS Directory"

		processDirectory MacOS ${APP}/Contents/MacOS

		statusBanner "Searching for issues in the KStars Bundle's Frameworks Directory"

		processDirectory Frameworks "${APP}/Contents/Frameworks"

		statusBanner "Searching for issues in the KStars Bundle's Plugins Directory"

		processDirectory Plugins "${APP}/Contents/Plugins"

		statusBanner "Searching for issues in the KStars Bundle's Math Plugins Directory"

		processDirectory MathPlugins "${APP}/Contents/Resources/MathPlugins"
	else
		echo "KStars DMG Directory does not exist, not checking KStars.  You have to build KStars with Craft first. Use build-kstars.sh, then build a DMG"
	fi

#This sets some important variables.
	DMG_DIR="${ASTRO_ROOT}/INDIWebManagerAppDMG"
	APP="${DMG_DIR}/INDIWebManagerApp.app"

#This code checks for issues in the KStars App Bundle
	if [ -e ${DMG_DIR} ] && [ -e ${APP} ]
	then
		statusBanner "Searching for issues in the INDIWebManagerAPP Bundle's MacOS Directory"

		processDirectory MacOS ${APP}/Contents/MacOS

		statusBanner "Searching for issues in the INDIWebManagerAPP Bundle's Frameworks Directory"

		processDirectory Frameworks "${APP}/Contents/Frameworks"

		statusBanner "Searching for issues in the INDIWebManagerAPP Bundle's Plugins Directory"

		processDirectory Plugins "${APP}/Contents/Plugins"

		statusBanner "Searching for issues in the INDIWebManagerAPP Bundle's Math Plugins Directory"

		processDirectory MathPlugins "${APP}/Contents/Resources/MathPlugins"
	else
		echo "INDIWebManagerApp DMG Directory does not exist, not checking INDIWebManagerAPP.  You have to build it with Craft first. Use build-indiwebmanager.sh, then build a DMG"
	fi



