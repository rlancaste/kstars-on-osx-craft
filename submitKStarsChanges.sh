#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# Prepare to run the script by setting all of the environment variables	
	source "${DIR}/build-env.sh"

# Download Arcanist and Phabricator if they don't exist yet.
if [ ! -d "${ASTRO_ROOT}"/arc ]
then
	echo "Downloading Arcanist and Phabricator for use with KStars."
	mkdir -p "${ASTRO_ROOT}"/arc
	cd "${ASTRO_ROOT}"/arc
	git clone https://github.com/phacility/libphutil.git
	git clone https://github.com/phacility/arcanist.git
fi

# Check to see that the user has actually already downloaded and built KStars, Craft, etc.
if [ ! -d ${CRAFT_DIR}/download/git/kde/applications/kstars ]
then
	echo "No KStars git repo detected.  Please make sure to run build-KStars.sh first and make changes to submit."
	exit
fi

# Export the Arcanist path so that it can be run.
	export PATH="${ASTRO_ROOT}"/arc/arcanist/bin:$PATH
# Change to the kstars directory so that the changes can be submitted.
	cd ${CRAFT_DIR}/download/git/kde/applications/kstars
# Check with the user to see if they want to create a new diff or change the current one.
	read -p "Do you either want to create a new arcanist diff (1) or update an existing one (2)? " arcDiffOpts

	if [ "$arcDiffOpts" == "1" ]
	then
		echo "Creating a new diff."
		arc diff --create
	elif [ "$arcDiffOpts" == "2" ]
	then
		echo "Updating the existing diff (if one exists already)."
		arc diff
	else
		echo "That was an invalid option, please select either 1 or 2 when you run the script."
	fi



		