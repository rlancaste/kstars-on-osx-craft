#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

ANNOUNCE=""
BUILD_INDI=""
STABLE_BUILD=""
GENERATE_DMG=""
FORCE_RUN=""
KSTARS_APP=""
REMOVE_ALL=""
VERBOSE=""

#This will print out how to use the script
function usage
{

cat <<EOF
	options:
	    -a Announce stuff as you go
	    -s Build the latest stable release (the default is to build the latest version from git)
	    -d Generate dmg
	    -f Force build even if there are script updates
	    -r Remove everything and do a fresh install
	    -v Print out verbose output while building
	    -q Craft is in quiet mode while building
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
		while getopts "adfrvsq" option
		do
			case $option in
				a)
					ANNOUNCE="Yep"
					;;
				s)
					STABLE_BUILD="Yep"
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
				v)
					VERBOSE="-vvv"
					;;
				q)
					VERBOSE="-q"
					;;
				*)
					dieUsage "Unsupported option $option"
					;;
			esac
		done
		shift $((${OPTIND} - 1))

		echo ""
		echo "ANNOUNCE           = ${ANNOUNCE:-Nope}"
		echo "STABLE_BUILD       = ${STABLE_BUILD:-Nope}"
		echo "GENERATE_DMG       = ${GENERATE_DMG:-Nope}"
		echo "FORCE_RUN          = ${FORCE_RUN:-Nope}"
		echo "REMOVE_ALL         = ${REMOVE_ALL:-Nope}"
		echo "VERBOSE            = ${VERBOSE:-Nope}"
	}

# This function checks to see if a connection to a website exists.
#
	function checkForConnection
	{
		testCommand=$(curl -Is $2 | head -n 1)
		if [[ "${testCommand}" == *"OK"* || "${testCommand}" == *"Moved"* ]]
  		then 
  			echo "$1 connection was found."
  		else
  			echo "$1, ($2), a required connection, was not found, aborting script."
  			echo "If you would like the script to run anyway, please comment out the line that tests this connection in build-kstars.sh."
  			exit
		fi
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
	source ${DIR}/build-env.sh
	
# Before starting, check to see if the remote servers are accessible
	statusBanner "Checking Connections"
	checkForConnection Homebrew "https://raw.githubusercontent.com/Homebrew/install/master/install"
	checkForConnection Craft "https://raw.githubusercontent.com/KDE/craft/master/setup/CraftBootstrap.py"
	checkForConnection Oxygen "https://github.com/KDE/oxygen.git"
	checkForConnection CustomMacBlueprints "https://github.com/rlancaste/craft-blueprints-kde.git"
	
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
		announce "Installing Homebrew."
		/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	fi

#This will install KStars dependencies from Homebrew.
	announce "Installing Homebrew Dependencies."
	brew upgrade
	
	# python is required for craft to work.
	brew install python
	
	# python 2 is now built in craft, but in fact installing numpy and pyfits relies on homebrew for some reason.
	brew install python2
	
	# I tried to write a recipe for gpsd, but it requires scons, and I have no idea what to do.
	brew install gpsd 
	
	# It would be good to sort this out.  gpg2 should be built in craft.  TODO!
	brew install gpg
	
	# This is because gpg is not called gpg2 and translations call on gpg2.  Fix this??
	ln -sf /usr/local/bin/gpg /usr/local/bin/gpg2
	
	# It would be good to get this stuff into craft too!!! TODO!
	# The problem here is that the system ruby can't be changed and we need logger-colors.
	brew install ruby
	export PATH=/usr/local/opt/ruby/bin:$PATH
	gem install logger-colors

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
			if [ -d "${CRAFT_DIR}" ]
			then
				rm -rf "${CRAFT_DIR}"
			fi
			mkdir -p ${CRAFT_DIR}
			curl https://raw.githubusercontent.com/KDE/craft/master/setup/CraftBootstrap.py -o setup.py && python3.7 setup.py --prefix "${CRAFT_DIR}"
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
	
	if [ -n "$STABLE_BUILD" ]
	then
		TARGET_VER="default"
	else
		TARGET_VER="Latest"
	fi
	
	craft "$VERBOSE" -i --target "${TARGET_VER}" indiserver
	
	announce "Building INDI 3rd Party Libraries and required dependencies"
	craft "$VERBOSE" -i --target "${TARGET_VER}" indiserver3rdPartyLibraries
	
	announce "Building INDI 3rd Party Drivers"
	craft "$VERBOSE" -i --target "${TARGET_VER}" indiserver3rdParty

#This will build gsc
	announce "Building GSC"
	craft "$VERBOSE" gsc

#This will build xplanet if it is not installed yet.
#This should be done by craft, but there is a build issue for xplanet using craft on Sierra that I cannot figure out, so this is a fix
#It works fine on my machine, but this fix is necessary for others.
#If this gets fixed, this entire section and the environment variable can be removed and xplanet can again be a craft dependency of kstars-mac
	if [ -n "$XPLANETNOCRAFT" ]
	then
		craft "$VERBOSE" netpbm
		cd ~/AstroRoot
		if [ -d xplanet-1.3.1 ]
		then
			rm -r xplanet-1.3.1
		fi
		xplanetArchiveFolder="${HOME}"/AstroRoot/kstars-craft/download/archives/libs/xplanet/
		xplanetArchive="${xplanetArchiveFolder}"/xplanet-1.3.1.tar.gz
		if [ ! -e "$xplanetArchive" ]
		then
			mkdir -p "${xplanetArchiveFolder}"
			cd "${xplanetArchiveFolder}"
			curl -O https://downloads.sourceforge.net/project/xplanet/xplanet/1.3.1/xplanet-1.3.1.tar.gz
		fi
		tar -xzf "$xplanetArchive" -C ~/AstroRoot
		cd xplanet-1.3.1
		export LDFLAGS="-Wl -rpath ${HOME}/AstroRoot/kstars-craft/lib -L${HOME}/AstroRoot/kstars-craft/lib"
		export CPPFLAGS="-I/usr/include -I/usr/local/include -I${HOME}/AstroRoot/kstars-craft/include"
		./configure --disable-dependency-tracking --without-cygwin --with-x=no --without-xscreensaver --with-aqua --prefix=${HOME}/AstroRoot/kstars-craft
		make
		make install
	else
		craft "$VERBOSE" xplanet
	fi
	

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
	export KSTARS_APP="${CRAFT_DIR}/Applications/KDE/KStars.app"
	if [ -d "${KSTARS_APP}" ]
	then
		rm -rf "${KSTARS_APP}"
	fi
	
	source ${CRAFT_DIR}/craft/craftenv.sh
		
	statusBanner "Crafting icons"
	craft "$VERBOSE" breeze-icons
		
	statusBanner "Crafting KStars"
	craft "$VERBOSE" -i --target "${TARGET_VER}" kstars-mac
		
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
	mkdir -p ${SHORTCUTS_DIR}
	
	if [ -d ${SHORTCUTS_DIR} ]
	then
		rm ${SHORTCUTS_DIR}/*
	fi
	
	#Craft Shortcuts
	ln -sf ${CRAFT_DIR}/Applications/KDE ${SHORTCUTS_DIR}
	ln -sf ${CRAFT_DIR}/bin ${SHORTCUTS_DIR}
	ln -sf ${CRAFT_DIR}/lib ${SHORTCUTS_DIR}
	ln -sf ${CRAFT_DIR}/include ${SHORTCUTS_DIR}
	ln -sf ${CRAFT_DIR}/share ${SHORTCUTS_DIR}
	ln -sf ${CRAFT_DIR}/etc/blueprints/locations/craft-blueprints-kde ${SHORTCUTS_DIR}
	
	# KStars
	ln -sf ${CRAFT_DIR}/download/git/kde/applications/kstars-mac ${SHORTCUTS_DIR}
	mv ${SHORTCUTS_DIR}/kstars-mac ${SHORTCUTS_DIR}/kstars-source
	ln -sf ${CRAFT_DIR}/build/kde/applications/kstars-mac/work/RelWithDebInfo-Latest ${SHORTCUTS_DIR}
	mv ${SHORTCUTS_DIR}/RelWithDebInfo-Latest ${SHORTCUTS_DIR}/kstars-build
	
	# INDIServer
	ln -sf ${CRAFT_DIR}/download/git/libs/indiserver ${SHORTCUTS_DIR}
	mv ${SHORTCUTS_DIR}/indiserver ${SHORTCUTS_DIR}/indiserver-source
	ln -sf ${CRAFT_DIR}/build/libs/indiserver/work/RelWithDebInfo-Latest ${SHORTCUTS_DIR}
	mv ${SHORTCUTS_DIR}/RelWithDebInfo-Latest ${SHORTCUTS_DIR}/indiserver-build
	
	# INDIServer 3rdParty
	ln -sf ${CRAFT_DIR}/download/git/libs/indiserver3rdParty ${SHORTCUTS_DIR}
	mv ${SHORTCUTS_DIR}/indiserver3rdParty ${SHORTCUTS_DIR}/indiserver-3rdParty-source
	ln -sf ${CRAFT_DIR}/build/libs/indiserver3rdParty/work/RelWithDebInfo-Latest ${SHORTCUTS_DIR}
	mv ${SHORTCUTS_DIR}/RelWithDebInfo-Latest ${SHORTCUTS_DIR}/indiserver-3rdParty-build

#This will package everything up into the app and then make a dmg.
	if [ -n "$GENERATE_DMG" ]
	then
		source ${DIR}/generate-dmg.sh
	fi

# Finally, remove the trap
	trap - EXIT
	announce "Script execution complete"
