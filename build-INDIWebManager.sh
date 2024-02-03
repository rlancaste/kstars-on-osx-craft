#!/bin/zsh

DIR=$(dirname "$0")

ANNOUNCE=""
BUILD_INDI=""
STABLE_BUILD=""
GENERATE_DMG=""
#GENERATE_XCODE=""
FORCE_RUN=""
INDI_WEB_MANAGER_APP=""
REMOVE_ALL=""
VERBOSE=""

#This will print out how to use the script
function usage
{

cat <<EOF
	options:
	    -a Announce stuff as you go
	    -s Build the latest stable release (the default is to build the latest version from git master)
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
				#x)
				#	GENERATE_XCODE="Yep"
				#	;;
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
		#echo "GENERATE_XCODE     = ${GENERATE_XCODE:-Nope}"
		echo "FORCE_RUN          = ${FORCE_RUN:-Nope}"
		echo "REMOVE_ALL         = ${REMOVE_ALL:-Nope}"
		echo "VERBOSE            = ${VERBOSE:-Nope}"
	}

# This function checks to see if a connection to a website exists.
#
	function checkForConnection
	{
		testCommand=$(curl -Is $2 | head -n 1)
		if [[ "${testCommand}" == *"OK"* || "${testCommand}" == *"Moved"* || "${testCommand}" == *"HTTP/2 301"* || "${testCommand}" == *"HTTP/2 200"* ]]
  		then 
  			echo "$1 connection was found."
  		else
  			echo "$1, ($2), a required connection, was not found, aborting script."
  			echo "If you would like the script to run anyway, please comment out the line that tests this connection in build-INDIWebManager.sh."
  			exit
		fi
	}

#This checks to see that this script is up to date.  If it is not, you can use the -f option to force it to run.
	function checkUpToDate
	{	
		cd "$DIR"

		localVersion=$(git log --pretty=%H ...refs/heads/master^ | head -n 1)
		remoteVersion=$(git ls-remote origin -h refs/heads/master | cut -f1)
		isChildOfRemote=$(git merge-base --is-ancestor "$remoteVersion" "$localVersion")
		cd - > /dev/null
		echo ""
		echo ""

		if [[ $isChildOfRemote -eq 1 ]]
		then
			if [ -z "$FORCE_RUN" ]
			then
				echo "Script is out of date"
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
			if [[ $remoteVersion == $localVersion ]]
			then
			    echo "Script is up-to-date"
			    echo ""
			else
			    echo "Script has local additions"
			    echo ""
			fi
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
	
# Set the working directory to /tmp because otherwise setup.py for craft will be placed in the user directory and that is messy.
	cd /tmp
	
# Before starting, check to see if the remote servers are accessible
	statusBanner "Checking Connections"
	checkForConnection Homebrew "https://raw.githubusercontent.com/Homebrew/install/master/install"
	checkForConnection Craft "https://raw.githubusercontent.com/KDE/craft/master/setup/CraftBootstrap.py"
	checkForConnection INDIWebSrc "https://github.com/rlancaste/INDIWebManagerApp.git"
	checkForConnection Oxygen "https://github.com/KDE/oxygen.git"
	checkForConnection CustomMacBlueprints "https://github.com/rlancaste/craft-blueprints-kde.git"
	
#Announce the script is starting and what will be done.
	announce "Starting script, building INDI and INDIWebManager with Craft"
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
	if [[ $(command -v brew) == "" ]]
	then
		announce "Installing Homebrew."
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	else
		#This will remove all the homebrew packages if desired.
		if [ -n "$REMOVE_ALL" ]
		then
			announce "You have selected the REMOVE_ALL option.  Warning, this will clear all currently installed homebrew packages."
			read runscript"?Do you really wish to proceed? (y/n)"
			if [ "$runscript" != "y" ]
			then
				echo "Quitting the script as you requested."
				exit
			fi
			brew remove --force $(brew list) --ignore-dependencies
		fi  
	fi

#This will install INDI_WEB_MANAGER dependencies from Homebrew.
	announce "Installing Homebrew Dependencies."
	brew upgrade
	
	# python is required for craft to work.
	brew install python
	
	# Craft does build ninja and install it to the craft directory, but QT Creator expects the homebrew version.
	brew install ninja

#This will create the Astro Directory if it doesn't exist
	mkdir -p "${ASTRO_ROOT}"

#This will install craft if it is not installed yet.  It will clear the old one if the REMOVE_ALL option was selected.
	if [ -d "${CRAFT_DIR}" ]
	then
		#This will remove the current craft if desired.
		if [ -n "$REMOVE_ALL" ]
		then
			announce "You have selected the REMOVE_ALL option.  Warning, this will clear the entire craft directory."
			read runscript2"?Do you really wish to proceed? (y/n)"
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
			curl https://raw.githubusercontent.com/KDE/craft/master/setup/CraftBootstrap.py -o setup.py && $(brew --prefix)/bin/python3 setup.py --prefix "${CRAFT_DIR}"
		fi
	else
		announce "Installing craft"
		mkdir -p ${CRAFT_DIR}
		curl https://raw.githubusercontent.com/KDE/craft/master/setup/CraftBootstrap.py -o setup.py && $(brew --prefix)/bin/python3 setup.py --prefix "${CRAFT_DIR}"
	fi  
	
#This copies all the required craft settings
	statusBanner "Copying Craft Settings and Blueprint settings specific to building on macs."
	cp ${DIR}/settings/CraftSettings.ini ${CRAFT_DIR}/etc/
	cp ${DIR}/settings/BlueprintSettings.ini ${CRAFT_DIR}/etc/
	statusBanner "Copying in indiwebmanager recipe."
	rm -rf ${CRAFT_DIR}/etc/blueprints/locations/craft-blueprints-kde/kde/applications/indiwebmanagerapp-mac # This will need to be finished and accepted before it can be merged.
	# This copies in all the new recipes.
	cp -R ${DIR}/craftRecipes/kde/applications/indiwebmanagerapp-mac ${CRAFT_DIR}/etc/blueprints/locations/craft-blueprints-kde/kde/applications/ # This copies in the main web manager app recipe
	
#This sets the craft environment based on the settings.
	source "${CRAFT_DIR}/craft/craftenv.sh"

#This will build indi, including the 3rd Party drivers.
	announce "Building INDI and required dependencies"
	
	# This will build INDI Core.  We want to do that every time since INDI changes often.
	if [ -n "$STABLE_BUILD" ]
	then
		craft "$VERBOSE" -i --target "stable" indiserver
	else
		craft "$VERBOSE" -i --target "master" indiserver
	fi
	
	# This will build INDI 3rd Party with the build libraries flag set.  We want to do that every time since INDI changes often.
	announce "Building INDI 3rd Party Libraries and required dependencies"
	if [ -n "$STABLE_BUILD" ]
	then
		craft "$VERBOSE" -i --target "stable" indiserver-3rdparty-libraries
	else
		craft "$VERBOSE" -i --target "master" indiserver-3rdparty-libraries
	fi
	
	# This will build INDI 3rd Party drivers only.  We want to do that every time since INDI changes often.
	announce "Building INDI 3rd Party Drivers"
	if [ -n "$STABLE_BUILD" ]
	then
		craft "$VERBOSE" -i --target "stable" indiserver-3rdparty
	else
		craft "$VERBOSE" -i --target "master" indiserver-3rdparty
	fi
	
	# This will check for broken links before proceeding.  Sometimes the INDI build fails to properly build drivers due to broken links.
	# If it does find broken links, you should fix them.
	testBrokenLinks=$(find -L "${CRAFT_DIR}/lib" -maxdepth 1 -type l)
	if [ -n "$testBrokenLinks" ]
	then
		echo "There are several broken links in the Craft Lib Directory. Please correct these prior to proceeding."
		echo "Here are the issues: "
		find -L "${CRAFT_DIR}/lib" -maxdepth 1 -type l
		exit
	fi

#This will build gsc if Needed, but no need to build it every time.
	if [ ! -d "${CRAFT_DIR}"/gsc ]
	then
		announce "Building GSC"
		craft "$VERBOSE" -i gsc
	fi

#This will set the INDI_WEB_MANAGER App directory and craft INDI_WEB_MANAGER.
	announce "Building INDIWebManager and required dependencies"
	export INDI_WEB_MANAGER_APP="${CRAFT_DIR}/Applications/KDE/INDIWebManager.app"
	if [ -d "${INDI_WEB_MANAGER_APP}" ]
	then
		rm -rf "${INDI_WEB_MANAGER_APP}"
	fi
		
	statusBanner "Crafting icons"
	craft "$VERBOSE" breeze-icons
		
	statusBanner "Crafting INDIWebManager"
	if [ -n "$STABLE_BUILD" ]
	then
		craft "$VERBOSE" -i --target "stable" indiwebmanagerapp-mac
	else
		craft "$VERBOSE" -i --target "master" indiwebmanagerapp-mac
	fi
		
	announce "CRAFT COMPLETE"
	
#This will create some symlinks that make it easier to edit INDI and INDIWebManager
	announce "Creating symlinks"
	mkdir -p ${SHORTCUTS_DIR}
	
	if [ -d ${SHORTCUTS_DIR} ]
	then
		rm -f ${SHORTCUTS_DIR}/*
	fi
	
	#Craft Shortcuts
	ln -sf ${CRAFT_DIR}/bin ${SHORTCUTS_DIR}
	ln -sf ${CRAFT_DIR}/build ${SHORTCUTS_DIR}
	ln -sf ${CRAFT_DIR}/lib ${SHORTCUTS_DIR}
	ln -sf ${CRAFT_DIR}/include ${SHORTCUTS_DIR}
	ln -sf ${CRAFT_DIR}/share ${SHORTCUTS_DIR}
	ln -sf ${CRAFT_DIR}/etc/blueprints/locations/craft-blueprints-kde ${SHORTCUTS_DIR}
	
	# INDIWebManager
	ln -sf ${CRAFT_DIR}/download/git/kde/applications/indiwebmanagerapp-mac ${SHORTCUTS_DIR}
	mv ${SHORTCUTS_DIR}/indiwebmanagerapp-mac ${SHORTCUTS_DIR}/indiwebmanagerapp-source
	ln -sf ${CRAFT_DIR}/build/kde/applications/indiwebmanagerapp-mac/work/build ${SHORTCUTS_DIR}
	mv ${SHORTCUTS_DIR}/build ${SHORTCUTS_DIR}/indiwebmanagerapp-build
	
	# KStars
	ln -sf ${CRAFT_DIR}/download/git/kde/applications/kstars ${SHORTCUTS_DIR}
	mv ${SHORTCUTS_DIR}/kstars ${SHORTCUTS_DIR}/kstars-source
	ln -sf ${CRAFT_DIR}/build/kde/applications/kstars/work/build ${SHORTCUTS_DIR}
	mv ${SHORTCUTS_DIR}/build ${SHORTCUTS_DIR}/kstars-build
	
	# INDIServer
	ln -sf ${CRAFT_DIR}/download/git/libs/_mac/indiserver ${SHORTCUTS_DIR}
	mv ${SHORTCUTS_DIR}/indiserver ${SHORTCUTS_DIR}/indiserver-source
	ln -sf ${CRAFT_DIR}/build/libs/_mac/indiserver/work/build ${SHORTCUTS_DIR}
	mv ${SHORTCUTS_DIR}/build ${SHORTCUTS_DIR}/indiserver-build
	
	# INDIServer 3rdParty
	ln -sf ${CRAFT_DIR}/download/git/libs/_mac/indiserver-3rdparty ${SHORTCUTS_DIR}
	mv ${SHORTCUTS_DIR}/indiserver-3rdparty ${SHORTCUTS_DIR}/indiserver-3rdparty-source
	ln -sf ${CRAFT_DIR}/build/libs/_mac/indiserver-3rdparty/work/build ${SHORTCUTS_DIR}
	mv ${SHORTCUTS_DIR}/build ${SHORTCUTS_DIR}/indiserver-3rdparty-build

#This will package everything up into the app and then make a dmg.
	if [ -n "$GENERATE_DMG" ]
	then
		source ${DIR}/generate-dmg-INDIWebManager.sh
	fi
# Finally, remove the trap
	trap - EXIT
	announce "Script execution complete"
