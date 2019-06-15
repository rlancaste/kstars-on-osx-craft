#/bin/bash

# This script has four goals:
# 1) Run the Fix-libraries script to get all frameworks into the App
# 2) Prepare files to create a dmg
# 3) Make the dmg look nice
# 4) Generate checksums

#This gets the current folder this script resides in.  It is needed to run other scripts.
	DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

#This function makes the dmg look nice.
	function set_bundle_display_options() {
		osascript <<-EOF
			tell application "Finder"
				set f to POSIX file ("${1}" as string) as alias
				tell folder f
					open
					tell container window
						set toolbar visible to false
						set statusbar visible to false
						set current view to icon view
						delay 1 -- sync
						set the bounds to {20, 50, 300, 400}
					end tell
					delay 1 -- sync
					set icon size of the icon view options of container window to 64
					set arrangement of the icon view options of container window to not arranged
					set position of item "QuickStart READ FIRST.pdf" to {100, 45}
					set position of item "CopyrightInfo and SourceCode.pdf" to {100, 145}
					set position of item "Applications" to {340, 45}
					set position of item "INDIWebManagerApp.app" to {340, 145}
					set background picture of the icon view options of container window to file "background.png" of folder "Pictures"
					set the bounds of the container window to {0, 0, 440, 270}
					update without registering applications
					delay 5 -- sync
					close
				end tell
				delay 5 -- sync
			end tell
		EOF
	}
	
#########################################################################
#This is where the main part of the script starts!!
#
	
set +e

#This code should only run if the user is running the generate-dmg script without running the build-indiwebmanagerapp.sh script
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
		echo "directory error! aborting DMG"
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
	
#This deletes the former Frameworks folder so you can start fresh.  This is needed if it ran before.
	statusBanner "Replacing the Frameworks Directory"
	rm -fr "${FRAMEWORKS_DIR}"
	mkdir -p "${FRAMEWORKS_DIR}"

#This copies the documentation that will be placed into the dmg.
	announce "Copying Documentation"
	cp -f ${DIR}/"CopyrightInfo and SourceCode.pdf" ${DMG_DIR}
	cp -f ${DIR}/"QuickStart READ FIRST-INDIWebManager.pdf" ${DMG_DIR}/"QuickStart READ FIRST.pdf"

#This deletes any previous dmg stuff so a new one can be made.
	announce "Removing any previous DMG, checksums, and unnecessary files"
	rm -r ${DMG_DIR}/kglobalaccel5.app
	rm -r ${DMG_DIR}/kwallet-query.app
	rm -r ${DMG_DIR}/kwalletd5.app
	rm ${DMG_DIR}/INDIWebManagerApp*.dmg
	rm ${DMG_DIR}/INDIWebManagerApp*.md5
	rm ${DMG_DIR}/INDIWebManagerApp*.sha256

###########################################
announce "Building DMG"
cd ${DMG_DIR}
macdeployqt INDIWebManagerApp.app 

#The Fix Libraries Script Copies library files into the app and runs otool on them.
	source ${DIR}/fix-libraries-INDIWebManager.sh

#Setting up some short paths
	UNCOMPRESSED_DMG=${DMG_DIR}/INDIWebManagerAppUncompressed.dmg

#Create and attach DMG
	hdiutil create -srcfolder ${DMG_DIR} -size 600m -fs HFS+ -format UDRW -volname INDIWebManagerApp ${UNCOMPRESSED_DMG}
	hdiutil attach ${UNCOMPRESSED_DMG}

# Obtain device information
	DEVS=$(hdiutil attach ${UNCOMPRESSED_DMG} | cut -f 1)
	DEV=$(echo $DEVS | cut -f 1 -d ' ')
	VOLUME=$(mount |grep ${DEV} | cut -f 3 -d ' ')

# copy in and set volume icon
	cp -f ${DIR}/DMGIcon-INDIWebManagerApp.icns ${VOLUME}/.VolumeIcon.icns
	SetFile -c icnC ${VOLUME}/.VolumeIcon.icns
	SetFile -a C ${VOLUME}

# copy in background image
	mkdir -p ${VOLUME}/Pictures
	cp -f ${DIR}/dmg_background-INDIWebManager.png ${VOLUME}/Pictures/background.png

# symlink Applications folder, arrange icons, set background image, set folder attributes, hide pictures folder
	ln -s /Applications/ ${VOLUME}/Applications
	set_bundle_display_options ${VOLUME}
	mv -f ${VOLUME}/Pictures ${VOLUME}/.Pictures

# Unmount the disk image
	hdiutil detach $DEV

# Convert the disk image to read-only
	hdiutil convert ${UNCOMPRESSED_DMG} -format UDBZ -o ${DMG_DIR}/INDIWebManagerApp-${INDI_WEB_MANAGER_APP_VERSION}.dmg

# Remove the Read Write DMG
	rm ${UNCOMPRESSED_DMG}

# Generate Checksums
	md5 ${DMG_DIR}/INDIWebManagerApp-${INDI_WEB_MANAGER_APP_VERSION}.dmg > ${DMG_DIR}/INDIWebManagerApp-${INDI_WEB_MANAGER_APP_VERSION}.dmg.md5
	shasum -a 256 ${DMG_DIR}/INDIWebManagerApp-${INDI_WEB_MANAGER_APP_VERSION}.dmg > ${DMG_DIR}/INDIWebManagerApp-${INDI_WEB_MANAGER_APP_VERSION}.dmg.sha256
