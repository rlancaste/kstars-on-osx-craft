## Instructions for Installing KStars, INDI, Dependencies, and related software on OS X with CRAFT

This script is built on:

	-the initial work that seanhoughton did to get KStars to run on OS X initially
	
	-the work that rlancaste did to get KStars modified to work decently on OS X
	
	-the work that Gonzothegreat did to figure out how to create a deployable app bundle and dmg
	
	-the work that jamiesmith did to automate the entire process in a simple and easy to use script
	
	-and the later work of rlancaste (myself) over the last couple of years to continue to revise, improve, and add new functionality

	-Note, Most of the epic journey is logged on the indilib forums http://indilib.org/forum/ekos/525-ekos-on-mac-os-x.html?start=564#11793
	
	-The old version of the script is on: https://github.com/jamiesmith/kstars-on-osx

### Prerequisites for running the script (no longer required beforehand!!!)

	This script makes use of the xcode command line tools, qt, homebrew (not much anymore), and craft.
	In the old version of the script, you had to install many of these first, but it can now do them automatically. 
	You can install these things beforehand if you like, but it is not required, as they will install.
	Warning:  Craft now must use its own internal version of QT.  If you have one installed elsewhere, such as ~/Qt, it could cause issues.  
	I kept getting this error where KStars wouldn't launch because it said certain classes were defined in two different places and it said 
	"One of the two will be used. Which one is undefined."  So it is better to just have the one qt.

	Links to the websites of key tools:
	QT         https://www.qt.io
	Homebrew   https://brew.sh
	Craft      https://community.kde.org/Craft

### Downloading the files from this repo 

```console
	mkdir -p ~/Projects
	cd ~/Projects/
	
	# if you don't already have the repo:
	# 
	git clone https://github.com/rlancaste/kstars-on-osx-craft.git
	
	# if you do already have it:
	# (if you changed something then you will have to work that out)
	cd ~/Projects/kstars-on-osx-craft
	git pull
```

### Editing the build-env.sh file to reflect your installation

	You should not need to change anything in the file unless you want to.  
	But if you want to build from different repositories or to install in different directories, these settings are for you.

### Running the build-kstars.sh Script
```console
	# If you want to build KStars to just use the latest version of the program, then do:
	~/Projects/kstars-on-osx-craft/build-kstars.sh
	# If you want to build KStars and get audible announcements along the way, then do:
	~/Projects/kstars-on-osx-craft/build-kstars.sh -a
	# If you want to build KStars to produce a distributable DMG, then do:
	~/Projects/kstars-on-osx-craft/build-kstars.sh -d
	# If you want to build KStars, but have an out of date script but still want to build anyway, then do:
	~/Projects/kstars-on-osx-craft/build-kstars.sh -f
	# If you want to build KStars completely fresh, deleting all of homebrew and all of craft:
	~/Projects/kstars-on-osx-craft/build-kstars.sh -r
	# Note that you can also use any combination of these options.
```

	After the script finishes, whichever method you chose, you should have built a kstars app that can actually be used.
	If you chose the dmg option, you can now distribute the app and/or dmg to other people freely.  
	The dmg has associated md5 and sha256 files for download verification.

### Running the fixLibraries.sh Script

	This script can only be run after building kstars as described above.  
	It will copy all required libraries and frameworks into the app bundle (except qt) and prepare it for distribution.  
	If you choose the -d option in build-kstars.sh, it runs this script automatically.  
	The only reason you would want to run it separately is if there is an issue you have to fix after KStars is built but before making the dmg.

### Running the generateDMG.sh Script

	This script can only be run after building kstars as described above.  It will first run the fixLibraries.sh script and then generate a DMG.  If you choose the -d option in build-kstars.sh, it runs this script automatically.  The only reason you would want to run it separately is if there is an issue you have to fix after KStars is built but before making the dmg.

### Editing KStars and/or INDI in QT Creator

	Please see the document EditingKStarsInQTCreatorOnOSX.pdf

	If you have already run the build-kstars.sh script, you will be all set up to edit KStars and/or INDI.  
	It is recommended that you use QT Creator for this editing because it has extra tools for editing QT specific files like GUI interface files.
	So you will want to first install QT Creator from QT's website: https://www.qt.io/download-qt-installer
	The open source license version is free of charge.
	Warning:  As indicated above, Craft now must use its own internal version of QT.  
	If you install a version of QT in ~/QT from their website it may cause problems as described above.  
	Follow the setup instructions in EditingKStarsInQTCreatorOnOSX.pdf to get this all set up to work in QT Creator.
	
### Submitting any changes you make in KStars and/or INDI

	KStars changes must be submitted using phabricator.  Instructions will be added for this.
	
	INDI changes must be submitted using a pull request on Github.  Instructions will be added for this.


