#/bin/zsh

# This script has three goals:
# 1) It makes sure the DMG folder is set up, KStars is copied there, and the variables aree correct.
# 2) identify programs that use libraries outside of the package (that meet certain criteria)
# 3) copy those libraries to the blah/Frameworks dir
# 4) Update those programs to know where to look for said libraries

DIR=$(dirname "$0")

#This adds a file to the list so it can be copied to Frameworks
	function addFileToCopy
	{
		for e in "${FILES_TO_COPY[@]}"
		do 
			if [[ "$e" == "$1" ]]
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
        if [[ $(otool -l $target| grep RPATH -A2) == *"${CRAFT_DIR}/lib"* ]]
        then
        	install_name_tool -delete_rpath ${CRAFT_DIR}/lib $target
		fi
        
		lineentries=$(otool -L $target | sed '1d' | awk '{print $1}' | egrep -v "$IGNORED_OTOOL_OUTPUT")
		entries=($(echo "$lineentries"))
		echo "Processing $target"
		
		# This should get the right rpath into the target file
		relativeRoot="${KSTARS_APP}/Contents"
		pathDiff=${target#${relativeRoot}*}
		if [[ "$pathDiff" == /Frameworks/* ]]
		then
			if [[ $(otool -l $target| grep RPATH -A2) == *"@loader_path/"* ]]
        	then
				install_name_tool -add_rpath "@loader_path/" $target	
			fi
		else
			pathToFrameworks=$(echo $(dirname "${pathDiff}") | awk -F/ '{for (i = 1; i < NF ; i++) {printf("../")} }')
			pathToFrameworks="${pathToFrameworks}Frameworks/"
			if [[ $(otool -l $target| grep RPATH -A2) == *"@loader_path/${pathToFrameworks}"* ]]
        	then
				install_name_tool -add_rpath "@loader_path/${pathToFrameworks}" $target
			fi
		fi
		
		for entry in $entries
		do
			baseEntry=$(basename $entry)
			newname=""
			newname="@rpath/${baseEntry}"
			if [[ $entry != $newname ]]
			then
			
				echo "    change reference $entry -> $newname" 
				install_name_tool -change \
				$entry \
				$newname \
				$target
			fi
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
			linkName=$(echo ${base}| cut -d. -f1).dylib

			if [[ $libFile == /* ]]
			then
				filename=$libFile
			else
				# see if I can find it, NOTE:  I had to add | cut -d" " -f1 because the find produced multiple results breaking the file copy.
				# I also had to add | awk -F '.dSYM' '{print $1}' because it sometimes found a file with the same name inside the .dSYM file
				filename=$(echo $(find "${CRAFT_DIR}/lib" -name "${base}")| cut -d" " -f1| awk -F '.dSYM' '{print $1}')
				if [[ "$filename" == "" ]]
				then
					if [[ -f "${FRAMEWORKS_DIR}/${base}" ]]
					then
						filename="${FRAMEWORKS_DIR}/${base}"
					else
						statusBanner "Failure to find library $libFile in craft-root or Frameworks.  Is it linked properly?"
						exit
					fi
				fi
			fi    

			if [ ! -f "${FRAMEWORKS_DIR}/${base}" ]
			then
				echo "HAVE TO COPY [$base] from [${filename}] to Frameworks"
				cp -fL "${filename}" "${FRAMEWORKS_DIR}"
				
				newname="@rpath/${linkName}"
				target="${FRAMEWORKS_DIR}/${base}"	
					
				echo "     Changing library id $target -> $newname" 
				install_name_tool -id \
				$newname \
				$target
				
				# This makes a link to the dylib with just the basic name of the library just in case
				if [[ "${base}" != "${linkName}" ]]
				then
					ln -s "${target}" "${FRAMEWORKS_DIR}/${linkName}" 
				fi
				
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

#This sets some important variables.
	DMG_DIR="${ASTRO_ROOT}/KStarsDMG"
	KSTARS_APP="${DMG_DIR}/KStars.app"
	FRAMEWORKS_DIR="${KSTARS_APP}/Contents/Frameworks"

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
		"Craft directory does not exist.  You have to build KStars with Craft first. Use build-kstars.sh"
		exit
	fi

#This code should make sure the KSTARS_APP and the DMG Directory are set correctly.
	if [ ! -e ${DMG_DIR} ] || [ ! -e ${KSTARS_APP} ]
	then
		"KStars.app does not exist in the DMG Directory.  Please run build-kstars.sh first!"
		exit
	fi
	
announce "Running Fix Libraries Script"

	FILES_TO_COPY=()

#Files in these locations do not need to be copied into the Frameworks folder.
	IGNORED_OTOOL_OUTPUT="/Qt|${KSTARS_APP}/|/usr/lib/|/System/"

	
cd ${DMG_DIR}

statusBanner "Processing kstars executable, dbus, indi, xplanet and others in the MacOS directory."
processDirectory MacOS "${KSTARS_APP}/Contents/MacOS"

statusBanner "Processing Phonon backend"
processTarget "${KSTARS_APP}/Contents/Plugins/phonon4qt5_backend/phonon_vlc.so"

statusBanner "Copying first round of files"
copyFilesToFrameworks

statusBanner "Processing Needed plugins and resources"

processDirectory kio "${KSTARS_APP}/Contents/Plugins/kf5/kio"

processDirectory GPHOTO_IOLIBS "${KSTARS_APP}/Contents/Resources/DriverSupport/gphoto/IOLIBS"
processDirectory GPHOTO_CAMLIBS "${KSTARS_APP}/Contents/Resources/DriverSupport/gphoto/CAMLIBS"

processDirectory MathPlugins "${KSTARS_APP}/Contents/Resources/MathPlugins"

processDirectory VLC_ACCESS "${KSTARS_APP}/Contents/Plugins/vlc/access"
processDirectory VLC_AUDIO_OUTPUT "${KSTARS_APP}/Contents/Plugins/vlc/audio_output"
processDirectory VLC_CODEC "${KSTARS_APP}/Contents/Plugins/vlc/codec"

statusBanner "Processing possibly needed plugins"
#I am not sure if we need the following plugins, but if we are going to include these plugins, they should not be linked to craft-root?
#processDirectory Platforms "${KSTARS_APP}/Contents/Plugins/platforms"
#processDirectory bearer "${KSTARS_APP}/Contents/Plugins/bearer"
#processDirectory designer "${KSTARS_APP}/Contents/Plugins/designer"
#processDirectory iconengines "${KSTARS_APP}/Contents/Plugins/iconengines"
#processDirectory kauthhelper "${KSTARS_APP}/Contents/Plugins/kauth/helper"
#processDirectory basePluginsDir "${KSTARS_APP}/Contents/Plugins"
#processDirectory kded "${KSTARS_APP}/Contents/Plugins/kf5/kded"
#processDirectory kiod "${KSTARS_APP}/Contents/Plugins/kf5/kiod"
#processDirectory kwindowsystem "${KSTARS_APP}/Contents/Plugins/kf5/kwindowsystem"
#processDirectory sonnet "${KSTARS_APP}/Contents/Plugins/kf5/sonnet"
#processDirectory urifilters "${KSTARS_APP}/Contents/Plugins/kf5/urifilters"
#processDirectory sqldrivers "${KSTARS_APP}/Contents/Plugins/sqldrivers"

statusBanner "Processing Frameworks"
processDirectory Frameworks "${FRAMEWORKS_DIR}"

while [ ${FILES_COPIED} -gt 0 ]
do
	statusBanner "${FILES_COPIED} more files were copied into Frameworks, we need to process it again."
	processDirectory Frameworks "${FRAMEWORKS_DIR}"
done

statusBanner "The following files are now in Frameworks:"
ls -lF ${FRAMEWORKS_DIR}

