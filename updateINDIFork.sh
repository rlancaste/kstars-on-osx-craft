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
	echo "No indi directory, please run the other download INDI Fork script"
	exit
fi

# Get into indi directory
cd indi

# Attach the upstream repository and update your local fork to it.
git fetch upstream
git merge upstream/master
git push



		