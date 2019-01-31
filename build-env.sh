#!/bin/bash

# This file will make it easier to use the scripts and do stuff on command line
#

function statusBanner
{
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
export ASTRO_ROOT=~/AstroRoot
export CRAFT_DIR="${ASTRO_ROOT}"/kstars-craft
export SHORTCUTS_DIR="${ASTRO_ROOT}"/craft-shortcuts

# This sets the minimum OS X version you are compiling for
# Note that the current version of qt can no longer build for anything less than 10.12
export QMAKE_MACOSX_DEPLOYMENT_TARGET=10.12
export MACOSX_DEPLOYMENT_TARGET=10.12

# This sets the current KStars version number that will be used throughout the script.
export KSTARS_VERSION=3.1.0

echo "DIR                   is [${DIR}]"
echo "ASTRO_ROOT            is [${ASTRO_ROOT}]"
echo "CRAFT_DIR             is [${CRAFT_DIR}]"
echo "SHORTCUTS_DIR         is [${SHORTCUTS_DIR}]"

echo "PATH                  is [${PATH}]"

echo "OSX Deployment target is [${QMAKE_MACOSX_DEPLOYMENT_TARGET}]"
echo "KStars Version        is [${KSTARS_VERSION}]"
