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
					set position of item "KStars.app" to {340, 145}
					set background picture of the icon view options of container window to file "background.jpg" of folder "Pictures"
					set the bounds of the container window to {0, 0, 440, 270}
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

#This code should only run if the user is running the generate-dmg script without running the build-kstars script
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
		echo "directory error! aborting DMG"
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

#This copies the documentation that will be placed into the dmg.
	announce "Copying Documentation"
	cp -f ${DIR}/docs/"CopyrightInfo and SourceCode.pdf" ${DMG_DIR}
	cp -f ${DIR}/docs/"QuickStart READ FIRST-KStars.pdf" ${DMG_DIR}/"QuickStart READ FIRST.pdf"

#This deletes any previous dmg stuff so a new one can be made.
	announce "Removing any previous DMG and checksums"
	rm ${DMG_DIR}/kstars*.dmg
	rm ${DMG_DIR}/kstars*.md5
	rm ${DMG_DIR}/kstars*.sha256

###########################################
announce "Building DMG"
cd ${DMG_DIR}
macdeployqt KStars.app -executable=${KSTARS_APP}/Contents/MacOS/dbus-daemon -qmldir=${CRAFT_DIR}/download/git/kde/applications/kstars-mac/kstars/data/qml

#The Fix Libraries Script Copies library files into the app and runs otool on them.
	source ${DIR}/fix-libraries-KStars.sh

#Setting up some short paths
	UNCOMPRESSED_DMG=${DMG_DIR}/KStarsUncompressed.dmg

#Create and attach DMG
	hdiutil create -srcfolder ${DMG_DIR} -size 600m -fs HFS+ -format UDRW -volname KStars ${UNCOMPRESSED_DMG}
	hdiutil attach ${UNCOMPRESSED_DMG}

# Obtain device information
	DEVS=$(hdiutil attach ${UNCOMPRESSED_DMG} | cut -f 1)
	DEV=$(echo $DEVS | cut -f 1 -d ' ')
	VOLUME=$(mount |grep ${DEV} | cut -f 3 -d ' ')

# copy in and set volume icon
	cp -f ${DIR}/images/DMGIcon-KStars.icns ${VOLUME}/.VolumeIcon.icns
	SetFile -c icnC ${VOLUME}/.VolumeIcon.icns
	SetFile -a C ${VOLUME}

# copy in background image
	mkdir -p ${VOLUME}/Pictures
	cp -f ${DIR}/images/dmg_background-KStars.png ${VOLUME}/Pictures/background.jpg

# symlink Applications folder, arrange icons, set background image, set folder attributes, hide pictures folder
	ln -s /Applications/ ${VOLUME}/Applications
	set_bundle_display_options ${VOLUME}
	mv -f ${VOLUME}/Pictures ${VOLUME}/.Pictures

# Unmount the disk image
	hdiutil detach $DEV

# Convert the disk image to read-only
	hdiutil convert ${UNCOMPRESSED_DMG} -format UDBZ -o ${DMG_DIR}/kstars-${KSTARS_VERSION}.dmg

# Remove the Read Write DMG
	rm ${UNCOMPRESSED_DMG}

# Generate Checksums
	md5 ${DMG_DIR}/kstars-${KSTARS_VERSION}.dmg > ${DMG_DIR}/kstars-${KSTARS_VERSION}.dmg.md5
	shasum -a 256 ${DMG_DIR}/kstars-${KSTARS_VERSION}.dmg > ${DMG_DIR}/kstars-${KSTARS_VERSION}.dmg.sha256
