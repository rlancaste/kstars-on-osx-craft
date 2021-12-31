import info
import os
import subprocess

class subinfo(info.infoclass):
    def setTargets(self):
        self.versionInfo.setDefaultValues()
        self.description = 'a desktop planetarium'
        self.displayName = "KStars Desktop Planetarium"
        
        self.svnTargets['Latest'] = "https://github.com/KDE/kstars.git"
        self.svnTargets['3.5.6'] = "https://github.com/KDE/kstars.git||stable-3.5.6"
        
       # for ver in ['3.5.4']:
       #     self.targets[ver] = 'https://github.com/KDE/kstars.git||stable-' + ver
       #     self.targetInstSrc[ver] = 'kstars-%s' % ver
        self.defaultTarget = '3.5.6'

    def setDependencies(self):
        self.runtimeDependencies["libs/qt5/qtbase"] = None
        self.runtimeDependencies["libs/qt5/qtdeclarative"] = None
        self.runtimeDependencies["libs/qt5/qtquickcontrols"] = None
        self.runtimeDependencies["libs/qt5/qtquickcontrols2"] = None
        self.runtimeDependencies["libs/qt5/qtsvg"] = None
        self.runtimeDependencies["libs/qt5/qtdatavis3d"] = None
        self.runtimeDependencies["libs/qt5/qtwebsockets"] = None
        self.runtimeDependencies["kde/frameworks/tier1/kconfig"] = None
        self.runtimeDependencies["kde/frameworks/tier2/kdoctools"] = None
        self.runtimeDependencies["kde/frameworks/tier1/kwidgetsaddons"] = None
        self.runtimeDependencies["kde/frameworks/tier3/knewstuff"] = None
        self.runtimeDependencies["kde/frameworks/tier1/kdbusaddons"] = None
        self.runtimeDependencies["kde/frameworks/tier1/ki18n"] = None
        self.runtimeDependencies["kde/frameworks/tier3/kinit"] = None
        self.runtimeDependencies["kde/frameworks/tier2/kjobwidgets"] = None
        self.runtimeDependencies["kde/frameworks/tier3/kio"] = None
        self.runtimeDependencies["kde/frameworks/tier3/kxmlgui"] = None
        self.runtimeDependencies["kde/frameworks/tier1/kplotting"] = None
        self.runtimeDependencies["kde/frameworks/tier3/knotifications"] = None
        self.runtimeDependencies["kde/frameworks/tier3/knotifyconfig"] = None
        self.runtimeDependencies["libs/eigen3"] = None
        self.runtimeDependencies["libs/cfitsio"] = None
        self.runtimeDependencies["libs/wcslib"] = None
        self.runtimeDependencies["libs/libraw"] = None
        self.runtimeDependencies["libs/gsl"] = None
        self.runtimeDependencies["libs/stellarsolver"] = None
        self.runtimeDependencies["qt-libs/qtkeychain"] = None
        
        self.runtimeDependencies["libs/libgphoto2"] = "default"
        self.runtimeDependencies["libs/xplanet"] = "default"
        self.runtimeDependencies["libs/gsc"] = "default"
        #Making these dependencies doesn't seem to download the latest versions, it downloads the default.
        #self.runtimeDependencies["libs/indiserver"] = "Latest"
        #self.runtimeDependencies["libs/indiserver3rdParty"] = "Latest"

        # The icons are now in the mac files repo
        #self.runtimeDependencies["kde/frameworks/tier1/breeze-icons"] = None
        
        if not CraftCore.compiler.isMacOS:
            self.runtimeDependencies["qt-libs/phonon-vlc"] = None


from Package.CMakePackageBase import *


class Package(CMakePackageBase):
    def __init__(self):
        CMakePackageBase.__init__(self)
        self.ignoredPackages.append("binary/mysql")
        self.blacklist_file = ["blacklist.txt"]
        
    def make(self):
        if not super().make():
            return False
            
            
        #Copying things needed for MacOS KStars
        
        #	Defining Craft Directories
        buildDir = str(self.buildDir())
        sourceDir = str(self.sourceDir())
        packageDir = str(self.packageDir())
        imageDir = str(self.imageDir())
        craftRoot = str(CraftCore.standardDirs.craftRoot())
        KSTARS_APP = os.path.join(buildDir , 'bin' , 'KStars.app')
        KSTARS_RESOURCES = os.path.join(KSTARS_APP , 'Contents' , 'Resources')
        KSTARS_PLUGINS = os.path.join(KSTARS_APP , 'Contents' , 'PlugIns')
        
        #	The Translations Directory
        utils.system("cp -rf " + craftRoot + "/share/locale " + KSTARS_RESOURCES)
				
        #	INDI Drivers
        utils.system("mkdir -p " + KSTARS_APP + "/Contents/MacOS/indi")
        utils.system("cp -f " + craftRoot + "/bin/indi* " + KSTARS_APP + "/Contents/MacOS/indi/")
        
        #	INDI firmware files"
        utils.system("mkdir -p " + KSTARS_RESOURCES + "/DriverSupport/")
        utils.system("cp -rf " + craftRoot + "/usr/local/lib/indi/DriverSupport " + KSTARS_RESOURCES)
        
        #	Driver XML Files
        utils.system("cp -f " + craftRoot + "/share/indi/* " + KSTARS_RESOURCES + "/DriverSupport/")
        
        #	Math Plugins
        utils.system("cp -rf " + craftRoot + "/lib/indi/MathPlugins " + KSTARS_RESOURCES)
        
        #	The gsc executable
        utils.system("cp -f " + craftRoot + "/bin/gsc " + KSTARS_APP + "/Contents/MacOS/indi/")

        #	xplanet
        #planet picture setup?
        xplanet_dir = KSTARS_APP + "/Contents/MacOS/xplanet"
        utils.system("mkdir -p " + xplanet_dir + "/bin")
        utils.system("mkdir -p " + xplanet_dir + "/share")
        utils.system("cp -f " + craftRoot + "/bin/xplanet " + xplanet_dir + "/bin/")
        utils.system("cp -rf " + craftRoot + "/share/xplanet " + xplanet_dir + "/share/")
        
        #	GPhoto Plugins
        GPHOTO_VERSION = subprocess.getoutput("pkg-config --modversion libgphoto2")
        PORT_VERSION = "0.12.0"
        utils.system("mkdir -p " + KSTARS_RESOURCES + "/DriverSupport/gphoto/IOLIBS")
        utils.system("mkdir -p " + KSTARS_RESOURCES + "/DriverSupport/gphoto/CAMLIBS")
        utils.system("cp -rf " + craftRoot + "/lib/libgphoto2_port/" + PORT_VERSION + "/* " + KSTARS_RESOURCES + "/DriverSupport/gphoto/IOLIBS/")
        utils.system("cp -rf " + craftRoot + "/lib/libgphoto2/" + GPHOTO_VERSION + "/* " + KSTARS_RESOURCES + "/DriverSupport/gphoto/CAMLIBS/")
        
        #   Plugins
        utils.system("cp -rf " + craftRoot + "/plugins/* " + KSTARS_PLUGINS)
        
        #	Notifications
        utils.system("cp -rf " + craftRoot + "/share/knotifications5 " + KSTARS_RESOURCES)
        
        # qt.conf
        confContents = "[Paths]\n"
        confContents += "Prefix = " + craftRoot + "\n"
        confContents += "Plugins = plugins\n"
        confContents += "Imports = qml\n"
        confContents += "Qml2Imports = qml\n"
        confContents += "Translations = " + craftRoot + "/share/locale\n"
        
        utils.system("touch " + KSTARS_RESOURCES + "/qt.conf")
        utils.system("echo \"" + confContents + "\" >> " + KSTARS_RESOURCES + "/qt.conf")

        return True
