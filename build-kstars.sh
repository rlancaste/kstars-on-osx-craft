#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

ANNOUNCE=""
BUILD_INDI=""
GENERATE_DMG=""
FORCE_RUN=""
KSTARS_APP=""
REMOVE_ALL=""

#This will print out how to use the script
function usage
{

cat <<EOF
	options:
	    -a Announce stuff as you go
	    -d Generate dmg
	    -f Force build even if there are script updates
	    -r Remove everything and do a fresh install
EOF
}

#This function prints the usage information if the user enters an invalid option or no option at all and quits the program 
	function dieUsage
	{
		echo ""
		echo $*
		echo ""
		usage
		exit 9
	}

#These functions are involved in quitting the script
	function exitEarly
	{
		announce "$*"
		trap - EXIT
		exit 0
	}
	
	function scriptDied
	{
    	announce "Something failed"
	}

#This function processes the user's options for running the script
	function processOptions
	{
		while getopts "adfr" option
		do
			case $option in
				a)
					ANNOUNCE="Yep"
					;;
				d)
					GENERATE_DMG="Yep"
					;;
				f)
					FORCE_RUN="Yep"
					;;
				r)
					REMOVE_ALL="Yep"
					;;
				*)
					dieUsage "Unsupported option $option"
					;;
			esac
		done
		shift $((${OPTIND} - 1))

		echo ""
		echo "ANNOUNCE            = ${ANNOUNCE:-Nope}"
		echo "GENERATE_DMG  	= ${GENERATE_DMG:-Nope}"
		echo "FORCE_RUN           = ${REMOVE_ALL:-Nope}"
		echo "REMOVE_ALL           = ${REMOVE_ALL:-Nope}"
	}

#This function checks to see that all connections are available before starting the script
#That could save time if one of the repositories is not available and it would crash later
	function checkForConnections
	{
		git ls-remote ${KSTARS_REPO} &> /dev/null
		git ls-remote ${LIBINDI_REPO} &> /dev/null
		git ls-remote ${CRAFT_REPO} &> /dev/null
		statusBanner "All Git Respositories found"
	}

#This checks to see that this script is up to date.  If it is not, you can use the -f option to force it to run.
	function checkUpToDate
	{	
		cd "$DIR"

		localVersion=$(git log --pretty=%H ...refs/heads/master^ | head -n 1)
		remoteVersion=$(git ls-remote origin -h refs/heads/master | cut -f1)
		cd - > /dev/null
		echo ""
		echo ""

		if [ "${localVersion}" != "${remoteVersion}" ]
		then

			if [ -z "$FORCE_RUN" ]
			then
				announce "Script is out of date"
				echo ""
				echo "override with a -f"
				echo ""
				echo "There is a newer version of the script available, please update - run"
				echo "cd $DIR ; git pull"

				echo "Aborting run"
				exit 9
			else
				echo "WARNING: Script is out of date"
			
				echo "Forcing run"
			fi
		else
			echo "Script is up-to-date"
			echo ""
		fi	
	}


########################################################################################
# This is where the main part of the script starts!
#

#Process the command line options to determine what to do.
	processOptions $@
	
#Check to see that this script is up to date.  If you want it to run anyway, use the -f option.
	checkUpToDate
	
# Prepare to run the script by setting all of the environment variables	
	source "${DIR}/build-env.sh"
	
# Before starting, check for QT and to see if the remote servers are accessible
	checkForConnections
	
#Announce the script is starting and what will be done.
	announce "Starting script, building INDI and KStars with Craft"
	if [ -n "$GENERATE_DMG" ]
	then
		announce "and then building a DMG"
	fi
	
# This installs the xcode command line tools if not installed yet.
# Yes these tools will be automatically installed if the user has never used git before
# But sometimes they need to be installed again.
# If they are already installed, it will just print an error message
	announce "Installing xcode command line tools"
	xcode-select --install
	
# From here on out exit if there is a failure
	set -e
	trap scriptDied EXIT
	
#This will install homebrew if it hasn't been installed yet, or reset homebrew if desired.
	if [ -d "/usr/local/Homebrew" ]
	then
		#This will remove all the homebrew packages if desired.
		if [ -n "$REMOVE_ALL" ]
		then
			announce "You have selected the REMOVE_ALL option.  Warning, this will clear all currently installed homebrew packages."
			read -p "Do you really wish to proceed? (y/n)" runscript
			if [ "$runscript" != "y" ]
			then
				echo "Quitting the script as you requested."
				exit
			fi
			brew remove --force $(brew list) --ignore-dependencies
		fi  
	else
		/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	fi

#This will install KStars dependencies from Homebrew.
	announce "Installing Homebrew Dependencies."
	brew upgrade
	brew install python
	brew install gpsd #(I tried to write a recipe for gpsd, but it requires scons, and I have no idea what to do)

#This will create the Astro Directory if it doesn't exist
	mkdir -p "${ASTRO_ROOT}"

#This will install craft if it is not installed yet.  It will clear the old one if the REMOVE_ALL option was selected.
	if [ -d "${CRAFT_DIR}" ]
	then
		#This will remove the current craft if desired.
		if [ -n "$REMOVE_ALL" ]
		then
			announce "You have selected the REMOVE_ALL option.  Warning, this will clear the entire craft directory."
			read -p "Do you really wish to proceed? (y/n)" runscript2
			if [ "$runscript2" != "y" ]
			then
				echo "Quitting the script as you requested."
				exit
			fi
			rm -rf "${CRAFT_DIR}"
		fi
	else
		announce "Installing craft"
		mkdir -p ${CRAFT_DIR}
		curl https://raw.githubusercontent.com/KDE/craft/master/setup/CraftBootstrap.py -o setup.py && python3.7 setup.py --prefix "${CRAFT_DIR}"
	fi  
	
#This copies all the required craft settings
	statusBanner "Copying Craft Settings and Blueprint settings specific to building on macs."
	cp ${DIR}/CraftSettings.ini ${CRAFT_DIR}/etc/
	cp ${DIR}/BlueprintSettings.ini ${CRAFT_DIR}/etc/
	statusBanner "Replacing default craft recipes with revised Mac recipes until they get revised and accepted."
	rm -rf ${CRAFT_DIR}/etc/blueprints/locations/craft-blueprints-kde
	cd ${CRAFT_DIR}/etc/blueprints/locations
	git clone https://github.com/rlancaste/craft-blueprints-kde.git

#This will build indi, including the 3rd Party drivers.
	announce "Building INDI and required dependencies"
	source ${CRAFT_DIR}/craft/craftenv.sh
	craft -vvv -i indiserver-latest
	craft -vvv -i indiserver3rdParty-latest

#This will build gsc
	announce "Building GSC"
	craft -vvv -i gsc

#This will get some nice sounds for KStars
	statusBanner "Getting Oxygen Sounds for KStars"
	mkdir -p "${CRAFT_DIR}"/share/sounds/
	cd ${CRAFT_DIR}
	if [ ! -d oxygen ]
	then
		git clone https://github.com/KDE/oxygen.git
	fi
	cp -f "${CRAFT_DIR}"/oxygen/sounds/*.ogg "${CRAFT_DIR}"/share/sounds/

#This will set the KStars App directory and craft KStars.
	announce "Building KStars and required dependencies"
	KSTARS_APP="${CRAFT_DIR}/Applications/KDE/KStars.app"
	rm -rf ${KSTARS_APP}
	
	source ${CRAFT_DIR}/craft/craftenv.sh
		
	statusBanner "Crafting icons"
	craft -vvv -i breeze-icons
		
	statusBanner "Crafting KStars"
	craft -vvv -i kstars-latest
		
	announce "CRAFT COMPLETE"
	
#This will Post-Process the KStars build
		##########################################
		statusBanner "Post-processing KStars Build"
		echo "KSTARS_APP=${KSTARS_APP}"
		##########################################
		statusBanner "Editing info.plist"
		plutil -insert NSPrincipalClass -string NSApplication ${KSTARS_APP}/Contents/info.plist
		plutil -insert NSHighResolutionCapable -string True ${KSTARS_APP}/Contents/info.plist
		plutil -insert NSRequiresAquaSystemAppearance -string NO ${KSTARS_APP}/Contents/info.plist
		plutil -replace CFBundleName -string KStars ${KSTARS_APP}/Contents/info.plist
		plutil -replace CFBundleVersion -string $KSTARS_VERSION ${KSTARS_APP}/Contents/info.plist
		plutil -replace CFBundleLongVersionString -string $KSTARS_VERSION ${KSTARS_APP}/Contents/info.plist
		plutil -replace CFBundleShortVersionString -string $KSTARS_VERSION ${KSTARS_APP}/Contents/info.plist
		plutil -replace NSHumanReadableCopyright -string "© 2001 - 2018, The KStars Team, Freely Released under GNU GPL V2" ${KSTARS_APP}/Contents/info.plist
		##########################################

#This will create some symlinks that make it easier to edit INDI and KStars
	announce "Creating symlinks"
	SHORTCUTS_DIR=${ASTRO_ROOT}/craft-shortcuts
	mkdir -p ${SHORTCUTS_DIR}
	
	#Craft Shortcuts
	ln -s ${CRAFT_DIR}/bin ${SHORTCUTS_DIR}
	ln -s ${CRAFT_DIR}/lib ${SHORTCUTS_DIR}
	ln -s ${CRAFT_DIR}/include ${SHORTCUTS_DIR}
	ln -s ${CRAFT_DIR}/share ${SHORTCUTS_DIR}
	ln -s ${CRAFT_DIR}/etc/blueprints/locations/craft-blueprints-kde ${SHORTCUTS_DIR}
	
	# KStars Latest
	ln -s ${CRAFT_DIR}/download/git/kde/applications/kstars-latest ${SHORTCUTS_DIR}
	mv ${SHORTCUTS_DIR}/kstars-latest ${SHORTCUTS_DIR}/kstars-latest-source
	ln -s ${CRAFT_DIR}/build/kde/applications/kstars-latest/work/RelWithDebInfo-Latest ${SHORTCUTS_DIR}
	mv ${SHORTCUTS_DIR}/RelWithDebInfo-Latest ${SHORTCUTS_DIR}/kstars-latest-build
	
	# INDIServer Latest
	ln -s ${CRAFT_DIR}/download/git/libs/indiserver-latest ${SHORTCUTS_DIR}
	mv ${SHORTCUTS_DIR}/indiserver-latest ${SHORTCUTS_DIR}/indiserver-latest-source
	ln -s ${CRAFT_DIR}/build/libs/indiserver-latest/work/RelWithDebInfo-Latest ${SHORTCUTS_DIR}
	mv ${SHORTCUTS_DIR}/RelWithDebInfo-Latest ${SHORTCUTS_DIR}/indiserver-latest-build
	
	# INDIServer 3rdParty Latest
	ln -s ${CRAFT_DIR}/download/git/libs/indiserver3rdParty-latest ${SHORTCUTS_DIR}
	mv ${SHORTCUTS_DIR}/indiserver3rdParty-latest ${SHORTCUTS_DIR}/3rdParty-latest-source
	ln -s ${CRAFT_DIR}/build/libs/indiserver3rdParty-latest/work/RelWithDebInfo-Latest ${SHORTCUTS_DIR}
	mv ${SHORTCUTS_DIR}/RelWithDebInfo-Latest ${SHORTCUTS_DIR}/3rdParty-latest-build

#This will package everything up into the app and then make a dmg.
	if [ -n "$GENERATE_DMG" ]
	then
		source ${DIR}/generate-dmg.sh
	fi

# Finally, remove the trap
	trap - EXIT
	announce "Script execution complete"
