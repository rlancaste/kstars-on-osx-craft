#/bin/bash

# This script has three goals:
# 1) It makes sure the DMG folder is set up, KStars is copied there, and the variables aree correct.
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
	
		relativeRoot="${KSTARS_APP}/Contents"
	
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

#This code should only run if the user is running the fix-libraries script without running build-kstars or generate-dmg
if [ -z "${ASTRO_ROOT}" ]
then
	source ${DIR}/build-env.sh
fi

#This should stop the script so that it doesn't run if these paths are blank.
#That way it doesn't try to edit /Applications instead of ${CRAFT_DIR}/Applications for example
	if [ -z "${DIR}" ] || [ -z  "${CRAFT_DIR}" ]
	then
		echo "directory error! aborting Libraries script!"
		exit 9
	fi

#This code should make sure the KStars app and the DMG Directory are set correctly.
#In the case of the CMAKE and XCode builds, it also creates the dmg directory and copies in the app
	if [ ! -e ${CRAFT_DIR} ]
	then
		"KStars Craft directory does not exist.  You have to build KStars with Craft first. Use build-kstars.sh"
		exit
	fi
	DMG_DIR="${CRAFT_DIR}/Applications/KDE/"
	KSTARS_APP="${DMG_DIR}/KStars.app"
	
announce "Running Fix Libraries Script"

	FILES_TO_COPY=()
	FRAMEWORKS_DIR="${KSTARS_APP}/Contents/Frameworks"

#Files in these locations do not need to be copied into the Frameworks folder.
	IGNORED_OTOOL_OUTPUT="/Qt|${KSTARS_APP}/|/usr/lib/|/System/"

#This preserves the couple of Frameworks files that we cannot regenerate with this script currently
	statusBanner "Preserving Several Frameworks"
	mkdir -p "${KSTARS_APP}/Contents/Frameworks2"
	cp -f "${FRAMEWORKS_DIR}/libphonon4qt5.4.dylib" "${KSTARS_APP}/Contents/Frameworks2/libphonon4qt5.4.dylib"
	cp -f "${FRAMEWORKS_DIR}/libphonon4qt5experimental.4.dylib" "${KSTARS_APP}/Contents/Frameworks2/libphonon4qt5experimental.4.dylib"
	cp -f "${FRAMEWORKS_DIR}/libvlc.dylib" "${KSTARS_APP}/Contents/Frameworks2/libvlc.dylib"
	cp -f "${FRAMEWORKS_DIR}/libvlccore.dylib" "${KSTARS_APP}/Contents/Frameworks2/libvlccore.dylib"

#This deletes the former Frameworks folder so you can start fresh.  This is needed if it ran before.
	statusBanner "Replacing the Frameworks Directory"
	rm -fr "${FRAMEWORKS_DIR}"
	
#This copies back the preserved frameworks
	statusBanner "Restoring Preserved Frameworks"
	mv "${KSTARS_APP}/Contents/Frameworks2" "${FRAMEWORKS_DIR}"
	
# This deletes the qt.conf file so macdeployqt can create a new one which points inside the app bundle
	statusBanner "Deleting qt.conf so a new one that points inside the bundle can be made."
	rm -f "${KSTARS_APP}/Contents/Resources/qt.conf"

	
cd ${DMG_DIR}

statusBanner "Processing kstars executable"
processTarget "${KSTARS_APP}/Contents/MacOS/kstars"

statusBanner "Processing dbus programs"
processTarget "${KSTARS_APP}/Contents/MacOS/dbus-daemon"
processTarget "${KSTARS_APP}/Contents/MacOS/dbus-send"

statusBanner "Processing Phonon backend"
processTarget "${KSTARS_APP}/Contents/Plugins/phonon4qt5_backend/phonon_vlc.so"

# Also cheat, and add libindidriver.1.dylib to the list
#
addFileToCopy "libindidriver.1.dylib"

statusBanner "Copying first round of files"
copyFilesToFrameworks

statusBanner "Processing libindidriver library"

# need to process libindidriver.1.dylib
#
processTarget "${FRAMEWORKS_DIR}/libindidriver.1.dylib"
processDirectory indi "${KSTARS_APP}/Contents/MacOS/indi"
processDirectory xplanet "${KSTARS_APP}/Contents/MacOS/xplanet/bin"
processDirectory astrometry "${KSTARS_APP}/Contents/MacOS/astrometry/bin"
processDirectory netpbm "${KSTARS_APP}/Contents/MacOS/netpbm/bin"
processDirectory kio "${KSTARS_APP}/Contents/PlugIns/kf5/kio"

processDirectory GPHOTO_IOLIBS "${KSTARS_APP}/Contents/Resources/DriverSupport/gphoto/IOLIBS"
processDirectory GPHOTO_CAMLIBS "${KSTARS_APP}/Contents/Resources/DriverSupport/gphoto/CAMLIBS"

processDirectory MathPlugins "${KSTARS_APP}/Contents/Resources/MathPlugins"

processDirectory VLC_ACCESS "${KSTARS_APP}/Contents/PlugIns/vlc/access"
processDirectory VLC_AUDIO_OUTPUT "${KSTARS_APP}/Contents/PlugIns/vlc/audio_output"
processDirectory VLC_CODEC "${KSTARS_APP}/Contents/PlugIns/vlc/codec"

#This should not be necessary because macdeployqt used to do this.  Why do I need to add this?
processDirectory Platforms "${KSTARS_APP}/Contents/PlugIns/platforms"

processDirectory Frameworks "${FRAMEWORKS_DIR}"

while [ ${FILES_COPIED} -gt 0 ]
do
	statusBanner "${FILES_COPIED} more files were copied into Frameworks, we need to process it again."
	processDirectory Frameworks "${FRAMEWORKS_DIR}"
done

statusBanner "The following files are now in Frameworks:"
ls -lF ${FRAMEWORKS_DIR}

