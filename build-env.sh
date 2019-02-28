#!/bin/bash

# This file will make it easier to use the scripts and do stuff on command line
#

function statusBanner
{
	echo -n -e "\033]0;$*\007"
    echo ""
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "~ $*"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo ""
}

function announce
{
    [ -n "$ANNOUNCE" ] && say -v Daniel "$*"
    statusBanner "$*"
}

# This sets the DIR variable to the current path of the scripts.
export DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# This sets the directory paths.  Note that these are customizable.
# Beware that none of them should have spaces in the file path.
	#This is the base path
export ASTRO_ROOT=~/AstroRoot
	#This is the path to the INDI directory for your personal editing work
export INDI_DIR="${ASTRO_ROOT}"/indi-work
	#This is the path to your personal fork of the INDI repository
export FORKED_INDI_REPO="https://github.com/rlancaste/indi.git"
	#This is the location of the craft root directory
export CRAFT_DIR="${ASTRO_ROOT}"/kstars-craft
	#This is the location of the craft shortcuts directory
export SHORTCUTS_DIR="${ASTRO_ROOT}"/craft-shortcuts
	#This is the path to your KStars XCode Build Directory
export KSTARS_XCODE_DIR="${ASTRO_ROOT}/kstars-xcode"

# This sets the minimum OS X version you are compiling for
# Note that the current version of qt can no longer build for anything less than 10.12
export QMAKE_MACOSX_DEPLOYMENT_TARGET=10.12
export MACOSX_DEPLOYMENT_TARGET=10.12

# This sets the current KStars version number that will be used throughout the script.
export KSTARS_VERSION=3.1.0

echo "DIR                   is [${DIR}]"
echo "ASTRO_ROOT            is [${ASTRO_ROOT}]"
echo "INDI_DIR              is [${INDI_DIR}]"
echo "FORKED_INDI_REPO      is [${FORKED_INDI_REPO}]"
echo "CRAFT_DIR             is [${CRAFT_DIR}]"
echo "SHORTCUTS_DIR         is [${SHORTCUTS_DIR}]"

echo "PATH                  is [${PATH}]"

echo "OSX Deployment target is [${QMAKE_MACOSX_DEPLOYMENT_TARGET}]"
echo "KStars Version        is [${KSTARS_VERSION}]"
