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
	echo "Cloning indi library"
	git clone ${FORKED_INDI_REPO}
	# Get into indi directory
	cd indi

	# Attach the upstream repository and update your local fork to it.
	git remote add upstream https://github.com/indilib/indi.git
	git fetch upstream
	git checkout master
	git merge upstream/master
	git push
else
	echo "INDI is already downloaded.  If you want to update it, please run the Update INDI Fork Script."
	exit
fi





		