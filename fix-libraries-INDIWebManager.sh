#/bin/bash

# This script has three goals:
# 1) It makes sure the DMG folder is set up, INDIWebManagerApp is copied there, and the variables aree correct.
# 2) identify programs that use libraries outside of the package (that meet certain criteria)
# 3) copy those libraries to the blah/Frameworks dir
# 4) Update those programs to know where to look for said libraries

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

#This adds a file to the list so it can be copied to Frameworks
	function addFileToCopy
	{
		for e in "${FILES_TO_COPY[@]}"
		do 
			if [ "$e" == "$1" ]
			then
				return 0
			fi
		done
	
		FILES_TO_COPY+=($1)
	}

#This Function processes a given file using otool to see what files it is using
#Then it uses install_name_tool to change that target to be a file in Frameworks
#Finally, it adds the file that it changed to the list of files to copy there.
	function processTarget
	{
		target=$1
		
		#This hard coded rpath needs to be removed from any files that have it for packaged apps because later there could be rpath conflicts
        #if the program is run on a computer with the same paths as the build computer
        install_name_tool -delete_rpath ${CRAFT_DIR}/lib $file
        	
		entries=$(otool -L $target | sed '1d' | awk '{print $1}' | egrep -v "$IGNORED_OTOOL_OUTPUT")
		echo "Processing $target"
	
		relativeRoot="${INDI_WEB_MANAGER_APP}/Contents"
	
		pathDiff=${target#${relativeRoot}*}

		#This is a Framework file
		if [[ "$pathDiff" == /Frameworks/* ]]
		then
			newname="@rpath/$(basename $target)"
			install_name_tool -add_rpath "@loader_path/" $file		
			echo "    This is a Framework, change its own id $target -> $newname" 
			
			install_name_tool -id \
			$newname \
			$target
		else
		    pathToFrameworks=$(echo $(dirname "${pathDiff}") | awk -F/ '{for (i = 1; i < NF ; i++) {printf("../")} }')
			pathToFrameworks="${pathToFrameworks}Frameworks/"
			install_name_tool -add_rpath "@loader_path/${pathToFrameworks}" $file
		fi
		
		for entry in $entries
		do
			baseEntry=$(basename $entry)
			newname=""
			newname="@rpath/${baseEntry}"
			echo "    change reference $entry -> $newname" 

			install_name_tool -change \
			$entry \
			$newname \
			$target

			addFileToCopy "$entry"
		done
		echo ""
		echo "   otool for $target after"
		otool -L $target | egrep -v "$IGNORED_OTOOL_OUTPUT" | awk '{printf("\t%s\n", $0)}'
	
	}

#This copies all of the files in the list into Frameworks
	function copyFilesToFrameworks
	{
		FILES_COPIED=0
		for libFile in "${FILES_TO_COPY[@]}"
		do
			# if it starts with a / then easy.
			#
			base=$(basename $libFile)

			if [[ $libFile == /* ]]
			then
				filename=$libFile
			else
				# see if I can find it, NOTE:  I had to add the last part and the echo because the find produced multiple results breaking the file copy into frameworks.
				filename=$(echo $(find "${CRAFT_DIR}/lib" -name "${base}")| cut -d" " -f1)
				if [[ "$filename" == "" ]]
				then
					filename=$(echo $(find /usr/local/lib -name "${base}")| cut -d" " -f1)
				fi
			fi    

			if [ ! -f "${FRAMEWORKS_DIR}/${base}" ]
			then
				echo "HAVE TO COPY [$base] from [${filename}] to Frameworks"
				cp -fL "${filename}" "${FRAMEWORKS_DIR}"
				
				FILES_COPIED=$((FILES_COPIED+1))
			
				# Seem to need this for the macqtdeploy
				#
				chmod +w "${FRAMEWORKS_DIR}/${base}"
		
			
			else
				echo ""
				echo "Skipping Copy: $libFile already in Frameworks "
			fi
		done
	}
	
	function processDirectory
	{
		directoryName=$1
		directory=$2
		statusBanner "Processing all of the $directoryName files in $directory"
		FILES_TO_COPY=()
		for file in ${directory}/*
		do
    		base=$(basename $file)

        	statusBanner "Processing $directoryName file $base"
        	processTarget $file
        	
		done

		statusBanner "Copying required files for $directoryName into frameworks"
		copyFilesToFrameworks
	}
	
	
	
#########################################################################
#This is where the main part of the script starts!!
#

#This code should only run if the user is running the fix-libraries script without running build-indiwebmanagerapp.sh or generate-dmg.sh
if [ -z "${ASTRO_ROOT}" ]
then
	source ${DIR}/build-env.sh
fi

#This sets some important variables.
	DMG_DIR="${ASTRO_ROOT}/INDIWebManagerAppDMG"
	INDI_WEB_MANAGER_APP="${DMG_DIR}/INDIWebManagerApp.app"
	FRAMEWORKS_DIR="${INDI_WEB_MANAGER_APP}/Contents/Frameworks"

#This should stop the script so that it doesn't run if these paths are blank.
#That way it doesn't try to edit /Applications instead of ${CRAFT_DIR}/Applications for example
	if [ -z "${DIR}" ] || [ -z "${DMG_DIR}" ] || [ -z  "${CRAFT_DIR}" ]
	then
		echo "directory error! aborting Fix Libraries Script"
		exit 9
	fi
	
#This code makes sure the craft directory exists.  This won't work too well if it doesn't
	if [ ! -e ${CRAFT_DIR} ]
	then
		"Craft directory does not exist.  You have to build INDIWebManager with Craft first. Use build-INDIWebManagerApp.sh"
		exit
	fi
	
#This code should make sure the INDI_WEB_MANAGER_APP and the DMG Directory are set correctly.
	if [ ! -e ${DMG_DIR} ] || [ ! -e ${INDI_WEB_MANAGER_APP} ]
	then
		"INDIWebManager.app does not exist in the DMG Directory.  Please run build-indiwebmanagerapp.sh first!"
		exit
	fi
	
announce "Running Fix Libraries Script"

	FILES_TO_COPY=()
	FRAMEWORKS_DIR="${INDI_WEB_MANAGER_APP}/Contents/Frameworks"

#Files in these locations do not need to be copied into the Frameworks folder.
	IGNORED_OTOOL_OUTPUT="/Qt|${INDI_WEB_MANAGER_APP}/|/usr/lib/|/System/"
	
cd ${DMG_DIR}

statusBanner "Processing INDIWebManager.app executable"
processTarget "${INDI_WEB_MANAGER_APP}/Contents/MacOS/INDIWebManagerApp"

# Also cheat, and add libindidriver.1.dylib to the list
#
addFileToCopy "libindidriver.1.dylib"

statusBanner "Copying first round of files"
copyFilesToFrameworks

statusBanner "Processing libindidriver library"

# need to process libindidriver.1.dylib
#
processTarget "${FRAMEWORKS_DIR}/libindidriver.1.dylib"
processDirectory indi "${INDI_WEB_MANAGER_APP}/Contents/MacOS/indi"

processDirectory GPHOTO_IOLIBS "${INDI_WEB_MANAGER_APP}/Contents/Resources/DriverSupport/gphoto/IOLIBS"
processDirectory GPHOTO_CAMLIBS "${INDI_WEB_MANAGER_APP}/Contents/Resources/DriverSupport/gphoto/CAMLIBS"

processDirectory MathPlugins "${INDI_WEB_MANAGER_APP}/Contents/Resources/MathPlugins"

#This should not be necessary because macdeployqt used to do this.  Why do I need to add this?
processDirectory Platforms "${INDI_WEB_MANAGER_APP}/Contents/PlugIns/platforms"

processDirectory Frameworks "${FRAMEWORKS_DIR}"

while [ ${FILES_COPIED} -gt 0 ]
do
	statusBanner "${FILES_COPIED} more files were copied into Frameworks, we need to process it again."
	processDirectory Frameworks "${FRAMEWORKS_DIR}"
done

statusBanner "The following files are now in Frameworks:"
ls -lF ${FRAMEWORKS_DIR}

