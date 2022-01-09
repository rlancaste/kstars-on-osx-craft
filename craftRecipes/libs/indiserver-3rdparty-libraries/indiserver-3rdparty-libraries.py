import glob
from xml.etree import ElementTree as et

import info

class subinfo(info.infoclass):
    def setTargets(self):
        self.description = 'INDI Library 3rd Party'
        self.svnTargets['Latest'] = "https://github.com/indilib/indi-3rdparty.git"
        self.targetInstSrc['Latest'] = ""
        
        ver = 'stable-1.9.3'
        #self.svnTargets[ver] = "https://github.com/indilib/indi-3rdparty.git||" + ver
        self.svnTargets[ver] = "https://github.com/indilib/indi-3rdparty.git"
        self.archiveNames[ver] = 'indi-%s.tar.gz' % ver
        self.targetInstSrc[ver] = ""

        self.defaultTarget = ver
    
    def setDependencies(self):
        self.buildDependencies["dev-utils/grep"] = "default"
        self.runtimeDependencies["virtual/base"] = "default"
        self.runtimeDependencies["libs/qt5/qtbase"] = "default"
        self.runtimeDependencies["libs/libnova"] = "default"
        self.runtimeDependencies["libs/cfitsio"] = "default"
        self.runtimeDependencies["libs/libgphoto2"] = "default"
        self.runtimeDependencies["libs/libftdi"] = "default"
        self.runtimeDependencies["libs/libdc1394"] = "default"
        self.runtimeDependencies["libs/libraw"] = "default"
        self.runtimeDependencies["libs/tiff"] = "default"
        self.runtimeDependencies["libs/fftw-double"] = "default"
        self.runtimeDependencies["libs/ffmpeg"] = "default"
        #Making these dependencies doesn't seem to download the latest versions, it downloads the default.
        #self.runtimeDependencies["libs/indiserver"] = "Latest"
        self.runtimeDependencies["libs/librtlsdr"] = "default"



from Package.CMakePackageBase import *


class Package(CMakePackageBase):
    def fixLibraryFolder(self, folder):
        craftLibDir = os.path.join(CraftCore.standardDirs.craftRoot(),  'lib')
        for library in utils.filterDirectoryContent(str(folder)):
            for path in utils.getLibraryDeps(str(library)):
                if path.startswith(craftLibDir):
                    utils.system(["install_name_tool", "-change", path, os.path.join("@rpath", os.path.basename(path)), library])
                # Note: The following code is to correct hard coded links to homebrew
                # The links are often caused by different camera manufacturer's binary libraries, not built by us.
                if path == "/usr/local/lib/libusb-1.0.0.dylib" or path == "/usr/local/opt/libusb/lib/libusb-1.0.0.dylib" or path == "@loader_path/libusb-1.0.0.dylib":
                    utils.system(["install_name_tool", "-change", path, os.path.join("@rpath/libusb.dylib"), library])
            if library.endswith(".dylib"):
                utils.system(["install_name_tool", "-id", os.path.join("@rpath", os.path.basename(library)), library])
            utils.system(["install_name_tool", "-add_rpath", craftLibDir, library])

    def __init__(self):
        CMakePackageBase.__init__(self)
        root = str(CraftCore.standardDirs.craftRoot())
        craftLibDir = os.path.join(root,  'lib')
        self.subinfo.options.configure.args = "-DCMAKE_INSTALL_PREFIX=" + root + " -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_MACOSX_RPATH=1 -DBUILD_LIBS=1 -DCMAKE_INSTALL_RPATH=" + craftLibDir

    def install(self):
        ret = CMakePackageBase.install(self)
        if OsUtils.isMac():
             self.fixLibraryFolder(os.path.join(str(self.imageDir()),  "bin"))
             self.fixLibraryFolder(os.path.join(str(self.imageDir()),  "lib"))
        return ret
