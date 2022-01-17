import info
import os
import subprocess

class subinfo(info.infoclass):
    def setTargets(self):
        self.versionInfo.setDefaultValues()
        self.description = 'A Graphical program to Manage, Configure, Launch, and Monitor an INDI WebManager on OS X and Linux'
        self.displayName = "INDI Web Manager App"
        
        self.svnTargets['master'] = "https://github.com/rlancaste/INDIWebManagerApp.git"
        
       # for ver in ['3.1.1']:
       #     self.targets[ver] = 'http://download.kde.org/stable/kstars/kstars-%s.tar.xz' % ver
       #     self.targetInstSrc[ver] = 'kstars-%s' % ver
            
        self.defaultTarget = 'master'

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
        self.runtimeDependencies["libs/indiclient"] = None
        self.runtimeDependencies["libs/libraw"] = None
        self.runtimeDependencies["libs/gsl"] = None
        self.runtimeDependencies["qt-libs/qtkeychain"] = None
        
        self.runtimeDependencies["libs/_mac/libgphoto2"] = None

        self.runtimeDependencies["libs/_mac/gsc"] = None
        self.runtimeDependencies["libs/_mac/indiserver"] = None
        self.runtimeDependencies["libs/_mac/indiserver-3rdparty"] = None

        # Install proper theme
        self.runtimeDependencies["kde/frameworks/tier1/breeze-icons"] = None
        
        if not CraftCore.compiler.isMacOS:
            self.runtimeDependencies["qt-libs/phonon-vlc"] = None


from Package.CMakePackageBase import *


class Package(CMakePackageBase):
    def __init__(self):
        CMakePackageBase.__init__(self)
        self.ignoredPackages.append("binary/mysql")
        
    def make(self):
        if not super().make():
            return False
            
            
        #Copying things needed for MacOS INDI Web Manager
        
        
        #	Defining Craft Directories
        buildDir = self.buildDir()
        sourceDir = self.sourceDir()
        packageDir = self.packageDir()
        imageDir = self.imageDir()
        craftRoot = str(CraftCore.standardDirs.craftRoot())
        INDI_WEB_MANAGER_APP = os.path.join(buildDir , 'INDIWebManagerApp.app')
        INDI_WEB_MANAGER_APP_RESOURCES = os.path.join(INDI_WEB_MANAGER_APP , 'Contents' , 'Resources')
        INDI_WEB_MANAGER_APP_PLUGINS = os.path.join(INDI_WEB_MANAGER_APP , 'Contents' , 'PlugIns')
        
        #	The Translations Directory
       # utils.system("cp -rf " + craftRoot + "/share/locale " + INDI_WEB_MANAGER_APP_RESOURCES)
				
        #	INDI Drivers
        utils.system("cp -f " + craftRoot + "/bin/indi* " + INDI_WEB_MANAGER_APP + "/Contents/MacOS/")
        
        #	INDI firmware files"
        utils.system("mkdir -p " + INDI_WEB_MANAGER_APP_RESOURCES + "/DriverSupport/")
        utils.system("cp -rf " + craftRoot + "/usr/local/lib/indi/DriverSupport " + INDI_WEB_MANAGER_APP_RESOURCES)
        
        #	Driver XML Files
        utils.system("cp -f " + craftRoot + "/share/indi/* " + INDI_WEB_MANAGER_APP_RESOURCES + "/DriverSupport/")
        
        #missed xml?
        
        #	Math Plugins
        utils.system("cp -rf " + craftRoot + "/lib/indi/MathPlugins " + INDI_WEB_MANAGER_APP_RESOURCES)
        
        #	The gsc executable
        utils.system("cp -f " + craftRoot + "/bin/gsc " + INDI_WEB_MANAGER_APP + "/Contents/MacOS/")
        
        #	GPhoto Plugins
        GPHOTO_VERSION = subprocess.getoutput("pkg-config --modversion libgphoto2")
        PORT_VERSION = "0.12.0"
        utils.system("mkdir -p " + INDI_WEB_MANAGER_APP_RESOURCES + "/DriverSupport/gphoto/IOLIBS")
        utils.system("mkdir -p " + INDI_WEB_MANAGER_APP_RESOURCES + "/DriverSupport/gphoto/CAMLIBS")
        utils.system("cp -rf " + craftRoot + "/lib/libgphoto2_port/" + PORT_VERSION + "/* " + INDI_WEB_MANAGER_APP_RESOURCES + "/DriverSupport/gphoto/IOLIBS/")
        utils.system("cp -rf " + craftRoot + "/lib/libgphoto2/" + GPHOTO_VERSION + "/* " + INDI_WEB_MANAGER_APP_RESOURCES + "/DriverSupport/gphoto/CAMLIBS/")
        
        #   Plugins
        utils.system("cp -rf " + craftRoot + "/plugins/* " + INDI_WEB_MANAGER_APP_PLUGINS)
        
        #	icons
      #  utils.system("mkdir " + INDI_WEB_MANAGER_APP_RESOURCES + "/icons")
      #  utils.system("cp -f " + craftRoot + "/share/icons/breeze/breeze-icons.rcc " + INDI_WEB_MANAGER_APP_RESOURCES + "/icons/")
      #  utils.system("cp -f " + craftRoot + "/share/icons/breeze-dark/breeze-icons-dark.rcc " + INDI_WEB_MANAGER_APP_RESOURCES + "/icons/")
        
        # qt.conf
        confContents = "[Paths]\n"
        confContents += "Prefix = " + craftRoot + "\n"
        confContents += "Plugins = plugins\n"
        
        utils.system("touch " + INDI_WEB_MANAGER_APP_RESOURCES + "/qt.conf")
        utils.system("echo \"" + confContents + "\" >> " + INDI_WEB_MANAGER_APP_RESOURCES + "/qt.conf")
        
        #	Editing the info.plist file
        pListFile = INDI_WEB_MANAGER_APP + "/Contents/info.plist"

        utils.system("plutil -insert NSPrincipalClass -string NSApplication " + pListFile)
        utils.system("plutil -insert NSHighResolutionCapable -string True " + pListFile)
        utils.system("plutil -insert NSRequiresAquaSystemAppearance -string NO " + pListFile)
        utils.system("plutil -replace CFBundleName -string INDIWebManagerApp " + pListFile)
        utils.system("plutil -replace CFBundleVersion -string ${INDI_WEB_MANAGER_APP_VERSION} " + pListFile)
        utils.system("plutil -replace CFBundleLongVersionString -string ${INDI_WEB_MANAGER_APP_VERSION} " + pListFile)
        utils.system("plutil -replace CFBundleShortVersionString -string ${INDI_WEB_MANAGER_APP_VERSION} " + pListFile)
        utils.system("plutil -replace NSHumanReadableCopyright -string \"© 2019 Robert Lancaster, Freely Released under GNU GPL V2\" "  + pListFile)

        return True
