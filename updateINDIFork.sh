#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# Prepare to run the script by setting all of the environment variables	
	source "${DIR}/build-env.sh"
	
if [ -z "${INDI_DIR}" ]
then
	echo "The build environment is not configured correctly."
	exit
fi

mkdir -p ${INDI_DIR}

cd ${INDI_DIR}/

if [ ! -d indi ]
then
	echo "No indi directory, please run the download INDI Fork script"
	exit
fi

# Get into the indi directory
cd indi

# Attach the upstream repository and update your local fork to it.
git fetch upstream
git merge upstream/master
git push

# Get into the indi 3rd Party directory
cd indi-3rdparty

# Attach the upstream repository and update your local fork to it.
git fetch upstream
git merge upstream/master
git push

		