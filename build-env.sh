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

export DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export ASTRO_ROOT=~/AstroRoot
export CRAFT_DIR=${ASTRO_ROOT}/kstars-craft
export GSC_DIR=${ASTRO_ROOT}/gsc

export GSC_TARGET_DIR=${CRAFT_DIR}/Applications/KDE/kstars.app/Contents/MacOS/gsc
export QMAKE_MACOSX_DEPLOYMENT_TARGET=10.11
export MACOSX_DEPLOYMENT_TARGET=10.11

# The repos are listed here just in case you want to build from a fork
export KSTARS_REPO=git://anongit.kde.org/kstars.git
export LIBINDI_REPO=https://github.com/indilib/indi.git
export CRAFT_REPO=git://anongit.kde.org/craft.git

export KSTARS_VERSION=3.1.0

echo "DIR          		 is [${DIR}]"
echo "ASTRO_ROOT          is [${ASTRO_ROOT}]"
echo "CRAFT_DIR  	     is [${CRAFT_DIR}]"

echo "GSC_DIR            is [${GSC_DIR}]"

echo "PATH               is [${PATH}]"

echo "PATH               is [${PATH}]"

echo "GSC_TARGET_DIR     is [${GSC_TARGET_DIR}]"
echo "OSX Deployment target [${QMAKE_MACOSX_DEPLOYMENT_TARGET}]"
echo "KStars Version [${KSTARS_VERSION}]"
