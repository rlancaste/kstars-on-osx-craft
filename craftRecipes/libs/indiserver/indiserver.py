import glob
from xml.etree import ElementTree as et

import info


class subinfo(info.infoclass):
    def setTargets(self):
        self.description = 'INDI Library'
        self.svnTargets['Latest'] = "https://github.com/indilib/indi.git"
        self.targetInstSrc['Latest'] = ""
        
        ver = 'stable-1.9.3'
        #self.svnTargets[ver] = "https://github.com/indilib/indi.git||" + ver
        self.svnTargets[ver] = "https://github.com/indilib/indi.git"
        self.archiveNames[ver] = 'indi-%s.tar.gz' % ver
        self.targetInstSrc[ver] = ""

        self.defaultTarget = ver

    def setDependencies(self):
        self.buildDependencies["dev-utils/grep"] = "default"
        self.runtimeDependencies["virtual/base"] = "default"
        self.runtimeDependencies["libs/qt5/qtbase"] = "default"
        self.runtimeDependencies["libs/libnova"] = "default"
        self.runtimeDependencies["libs/cfitsio"] = "default"
        self.runtimeDependencies["libs/libusb"] = "default"
        self.runtimeDependencies["libs/gsl"] = "default"
        self.runtimeDependencies["libs/libjpeg-turbo"] = "default"
        self.runtimeDependencies["libs/fftw-double"] = "default"


from Package.CMakePackageBase import *


class Package(CMakePackageBase):
    def fixLibraryFolder(self, folder):
        craftLibDir = os.path.join(CraftCore.standardDirs.craftRoot(),  'lib')
        for library in utils.filterDirectoryContent(str(folder)):
            for path in utils.getLibraryDeps(str(library)):
                if path.startswith(craftLibDir):
                    utils.system(["install_name_tool", "-change", path, os.path.join("@rpath", os.path.basename(path)), library])
            if library.endswith(".dylib"):
                utils.system(["install_name_tool", "-id", os.path.join("@rpath", os.path.basename(library)), library])
            utils.system(["install_name_tool", "-add_rpath", craftLibDir, library])

    def __init__(self):
        CMakePackageBase.__init__(self)
        root = str(CraftCore.standardDirs.craftRoot())
        craftLibDir = os.path.join(root,  'lib')
        self.subinfo.options.configure.args = "-DCMAKE_INSTALL_PREFIX=" + root + " -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_MACOSX_RPATH=1 -DCMAKE_INSTALL_RPATH=" + craftLibDir

    def install(self):
        ret = CMakePackageBase.install(self)
        if OsUtils.isMac():
             self.fixLibraryFolder(os.path.join(str(self.imageDir()),  "lib"))
             self.fixLibraryFolder(os.path.join(str(self.imageDir()),  "lib", "indi", "MathPlugins"))
             self.fixLibraryFolder(os.path.join(str(self.imageDir()),  "bin"))
        return ret
