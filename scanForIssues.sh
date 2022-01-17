#/bin/bash

#This script is meant to search for issues in the Craft bin and lib directories that could cause issues with packaging and/or running KStars

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

#Files in these locations can be safely ignored.
	IGNORED_OTOOL_OUTPUT="/usr/lib/|/System/"

	# This fuction is meant to check for IDs that are not rpaths or full paths, since that causes linking problems later.
	function checkForBadID
	{
		target=$1
		
		itsID=$(otool -D $target | sed -n '2 p')
		if [[ "$itsID" != @rpath* ]] && [[ "$itsID" != ${CRAFT_DIR}/* ]]
		then
			echo "$target has the wrong install ID: $itsID"
		fi
		
	}
	
	#This function is meant to check for links to homebrew programs or libraries.  
	#We want to link to craft libraries, not homebrew since homebrew doesn't build for distribution, so minimum macos version is newer than you want.
	function checkForHomebrewLinks
	{
		target=$1
        	
		entries=$(otool -L $target | sed '1d' | awk '{print $1}' | egrep -v "$IGNORED_OTOOL_OUTPUT")
		#echo "Processing $target"
		
		for entry in $entries
		do
		#echo "$entry"
			if [[ "$entry" == /usr/local/* ]]
			then
				echo "$target has a link to HomeBrew: $entry"
			fi
		done
		
	}
	
	#This function is intended to search for links that are not full paths, links to external folders, or not rpaths
	function checkForBadPaths
	{
		target=$1
        	
		entries=$(otool -L $target | sed '1d' | awk '{print $1}' | egrep -v "$IGNORED_OTOOL_OUTPUT")
		#echo "Processing $target"
		
		for entry in $entries
		do
		#echo "$entry"
			if [[ "$entry" != @rpath* ]] && [[ "$entry" != ${CRAFT_DIR}/* ]] && [[ "$entry" != /usr/local/* ]]
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
				truePath=${CRAFT_DIR}/lib/"${entry:7}"
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
    		
    		if [[ "$file" != *".dSYM" ]] && [[ "$file" != *".framework" ]] && [[ "$file" == ${CRAFT_DIR}/* ]]
    		then
				if [[ -f "$file" ]]
				then
					#statusBanner "Processing $directoryName file $base"
					if [[ "$file" == *".dylib" ]]
					then
						checkForBadID $file
					fi
					
					if [[ "$file" != *".a" ]]
					then
						checkForBrokenLinks $file
						checkForHomebrewLinks $file
						checkForBadPaths $file
					fi
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
	if [ -z "${DIR}" ] || [ -z  "${CRAFT_DIR}" ]
	then
		echo "directory error! aborting Fix Libraries Script"
		exit 9
	fi

#This code makes sure the craft directory exists.  This won't work too well if it doesn't
	if [ ! -e ${CRAFT_DIR} ]
	then
		"Craft directory does not exist.  You have to build KStars with Craft first. Use build-kstars.sh"
		exit
	fi


statusBanner "Searching for issues in CraftRoot Lib Directory and subfolders"

processDirectory lib "/Users/rlancaste/AstroRoot/craft-root/lib"

statusBanner "Processing CraftRoot Bin Directory"

processDirectory bin "/Users/rlancaste/AstroRoot/craft-root/bin"

statusBanner "Processing CraftRoot Bin Directory"

processDirectory plugins "/Users/rlancaste/AstroRoot/craft-root/Plugins"

