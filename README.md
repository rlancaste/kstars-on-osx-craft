## Instructions for Installing KStars, INDI, Dependencies, and related software on MacOS with CRAFT

![Screenshot of KStars on OS X](ScreenShotKStarsOnOSX.png "Screenshot of KStars on OS X")

This script is written by Rob Lancaster (rlancaste), but it is built upon:

- the initial work that seanhoughton did to get KStars to build and run on OS X initially
	
- the work that rlancaste did to get KStars modified to work decently on OS X
	
- the work that Gonzothegreat did to figure out how to create a deployable app bundle and dmg
	
- the work that jamiesmith did to automate the entire process in a simple and easy to use script
	
- and the later work of rlancaste (myself) over the last couple of years to continue to revise, improve, and add new functionality

- Note, Most of the epic journey is logged on the indilib forums [https://indilib.org/forum/ekos/525-ekos-on-mac-os-x.html?start=0](https://indilib.org/forum/ekos/525-ekos-on-mac-os-x.html?start=0)
	
- The old version of the script is on: [https://github.com/jamiesmith/kstars-on-osx](https://github.com/jamiesmith/kstars-on-osx)

# Getting Started

### Prerequisites for running the script (no longer required beforehand!!!)

One very important requirement is that your mac must be running OS X Sierra (10.12) or later.  QT refuses to build now on earlier versions.
This script makes use of the xcode command line tools, qt, homebrew (not much anymore), and craft.
In the old version of the script, you had to install many of these first, but it can now do them automatically. 
You can install these things beforehand if you like, but it is not required, as they will install.
Warning:  Craft now must use its own internal version of QT.  If you have one installed elsewhere, such as ~/Qt, it could cause issues.  
I kept getting this error where KStars wouldn't launch because it said certain classes were defined in two different places and it said 
"One of the two will be used. Which one is undefined."  So it is better to just have the one qt.

Links to the websites of key tools:
- QT         [https://www.qt.io](https://www.qt.io)
- Homebrew   [https://brew.sh](https://brew.sh)
- Craft      [https://community.kde.org/Craft](https://community.kde.org/Craft)

### Downloading the files from this repo using the Mac OS X Terminal

```
	mkdir -p ~/Projects
	cd ~/Projects/
	git clone https://github.com/rlancaste/kstars-on-osx-craft.git
```
### Updating the files in this repo to the latest version if you already have it

```
	cd ~/Projects/kstars-on-osx-craft
	git pull
```

### Editing the files to reflect your installation

The main file you would need to edit is [build-env.sh](build-env.sh) but you should not need to change anything in the file unless you want to.
Note that if you do make changes to the paths, then some of the instructions in this README will have incorrect paths for your system. 
But if you want to build from different repositories or to install in different directories, these settings are for you.
Also note that you may have to run the following command on some or all of the scripts to make them executable on your system.
You probably will not need to, but just in case, here it is for one of them.
```
	cd ~/Projects/kstars-on-osx-craft
	chmod +x build-kstars.sh
```

# Building KStars and INDI on MacOS

### Running the [build-kstars.sh](build-kstars.sh) Script

Note that you don't need to use any special options to use the script, you can just run the this command below from the OS X Terminal.
(assuming that this is where your script is located)
```
	~/Projects/kstars-on-osx-craft/build-kstars.sh
```

### Generating a distributable DMG

This is an extremely important function of the script, to generate a DMG so that KStars can be used on other machines.
To generate a DMG that you can share, run this command:
```
	~/Projects/kstars-on-osx-craft/build-kstars.sh -d
```
Combining this with other options will not compromise the creation of the DMG.  
If the script finishes successfully, the DMG will be located in the ~/AstroRoot/craft-shortcuts/KDE folder.
You can now distribute the app and/or dmg to other people freely.  
The dmg has associated md5 and sha256 files for download verification.

### Other Options for the build-kstars.sh Script

The script has a number of options that are explained below.

	-a	The build script will speak out loud as it is doing key steps.

	-v	This will set Craft to use verbose output showing all the gory details

	-q	This will set craft to use quiet mode (prints MUCH less detail)

	-s	This will make the script build the latest STABLE version of KStars and INDI (Note that by default, this script installs the LATEST version of KStars and INDI from github)
		
	-d	This will build KStars and produce a distributable DMG

	-x	This will create an XCode Project in addition to the normal build for editing or analyzing purposes

	-f	This will allow you to build KStars anyway with this script being out of date (If there is a newer version, it will prompt you to update by default)

	-r	This will install KStars completely fresh, deleting all of homebrew and all of craft. (Be careful!!  But this is really good for testing purposes or if your installation breaks.)

Note that you can also use any combination of these options. For example:
```
	~/Projects/kstars-on-osx-craft/build-kstars.sh -advx
```

After the script finishes, with whichever options you chose, you should have built a kstars app that can actually be used.

### Running the [fixLibraries.sh](fixLibraries.sh) Script

This script can only be run after building kstars as described above.  
It will copy all required libraries and frameworks into the app bundle (except qt) and prepare it for distribution.  
If you choose the -d option in [build-kstars.sh](build-kstars.sh), it runs this script automatically.  
The only reason you would want to run it separately is if there is an issue you have to fix after KStars is built but before making the dmg.

### Running the [generateDMG.sh](generateDMG.sh) Script

This script can only be run after building kstars as described above.  
It will first run the [fixLibraries.sh](fixLibraries.sh) script and then generate a DMG.  
If you choose the -d option in [build-kstars.sh](build-kstars.sh), it runs this script automatically.  
The only reason you would want to run it separately is if there is an issue you have to fix after KStars is built but before making the dmg.

# Getting Set Up For Editing KStars and INDI on MacOS

### Editing KStars and/or INDI in QT Creator

- Please see the document [EditingKStarsInQTCreatorOnOSX.pdf](EditingKStarsInQTCreatorOnOSX.pdf) for editing KStars
- Please see the document [EditingINDIInQTCreatorOnOSX.docx](EditingINDIInQTCreatorOnOSX.docx) for editing INDI

If you have already run the build-kstars.sh script, you will be able to edit KStars.
For INDI, you will need to also create a Fork on your own GitHub account first and then run the [downloadINDIForkForEditing.sh](downloadINDIForkForEditing.sh) script.  
It is recommended that you use QT Creator for editing KStars because it has extra tools for editing QT specific files like GUI interface files.
So you will want to first install QT Creator from QT's website: [https://www.qt.io/download-qt-installer](https://www.qt.io/download-qt-installer)
The open source license version is free of charge.
Warning:  As indicated above, Craft now must use its own internal version of QT.  
If you install a version of QT in ~/QT from their website it may cause problems as described above.  
Follow the setup instructions in the documents to get this all set up to work in QT Creator.

### Editing KStars in XCode

There is an option to create an XCode Project with this script.  This is not the recommended method for editing
KStars on OS X because it doesn't have some of the QT layout editing features present in QT Creator.
However, XCode does have a number of code analysis features that are not present in QT Creator.
So it is provided here both for convenience and for additional functionality.

### Submitting any changes you make in KStars

Let's say you made some change that was totally awesome or made some significant improvement and you want to submit it.
The KStars Code is hosted on this GIT Repository: [https://github.com/KDE/kstars](https://github.com/KDE/kstars)
But KStars changes must be submitted using Phabricator. Please see this website for details: [https://phabricator.kde.org/project/profile/295/](https://phabricator.kde.org/project/profile/295/)
	
###### To set yourself up to be able to submit your changes, run the following code from the OS X Terminal:
```
	mkdir -p ~/AstroRoot/arc
	cd ~/AstroRoot/arc
	git clone https://github.com/phacility/libphutil.git
	git clone https://github.com/phacility/arcanist.git
```
###### To actually commit and submit your changes, you can run this code:
```
	export PATH="~/AstroRoot/arc/arcanist/bin:$PATH"
	cd ~/AstroRoot/kstars-craft/download/git/kde/applications/kstars-mac
	arc diff
```

### Using the INDI Repository Scripts.
There are two scripts in this repo that are going to be useful for editing INDI.  
- [downloadINDIForkForEditing.sh](downloadINDIForkForEditing.sh) is useful for downloading a Fork of INDI that you have created and getting it setup to edit in QT Creator
- [updateINDIFork.sh](updateINDIFork.sh) is useful for making sure your INDI Fork is up to date before your pull request.
Please see the document EditingINDIInQTCreatorOnOSX.docx for more detailed instructions.

### Submitting any changes you make in INDI
	
INDI changes must be submitted using a pull request on Github.
The INDI Code is hosted on this Repository: [https://github.com/indilib/indi](https://github.com/indilib/indi)
Once you have made a fork, run the download script and edited your changes as described in the section above.
When you are ready to submit your changes, you should do the following:
	
1. Test everything you did in INDI throughly with KStars
2. Go to the command line and do the following (where "My Commit Message" corresponds to an explanation of what you did):
```
	cd ~/AstroRoot/indi-work/indi
	git commit -am "My Commit Message"
	git push
```
3.  If it has been awhile since you made your fork, you should update it to the latest version using the updateINDIFork.sh script
4.  Go to Github on your INDI Fork and click "New Pull Request" to submit your changes.