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
    def fixLibraryID(self, packageName):
        root = str(CraftCore.standardDirs.craftRoot())
        craftLibDir = os.path.join(root,  'lib')
        utils.system("install_name_tool -add_rpath " + craftLibDir + " " + craftLibDir +"/" + packageName + ".dylib")
        utils.system("install_name_tool -id @rpath/" + packageName + ".dylib " + craftLibDir +"/" + packageName + ".dylib")

    def __init__(self):
        CMakePackageBase.__init__(self)
        root = str(CraftCore.standardDirs.craftRoot())
        craftLibDir = os.path.join(root,  'lib')
        self.subinfo.options.configure.args = "-DCMAKE_INSTALL_PREFIX=" + root + " -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_MACOSX_RPATH=1 -DBUILD_LIBS=1 -DCMAKE_INSTALL_RPATH=" + craftLibDir

    def postQmerge(self):
        self.fixLibraryID("libsbig")
        self.fixLibraryID("libASICamera2")
        self.fixLibraryID("libEAFFocuser")
        self.fixLibraryID("libEFWFilter")
        self.fixLibraryID("libPlayerOneCamera")
        self.fixLibraryID("libatikcameras")
        self.fixLibraryID("libgxccd")
        root = str(CraftCore.standardDirs.craftRoot())
        craftLibDir = os.path.join(root,  'lib')
        utils.system("install_name_tool -change /usr/local/opt/libusb/lib/libusb-1.0.0.dylib @rpath/libusb.dylib " + craftLibDir +  "/" + "libqhyccd.dylib")
        utils.system("install_name_tool -change @loader_path/libusb-1.0.0.dylib @rpath/libusb.dylib " + craftLibDir +  "/" + "libASICamera2.dylib")
        utils.system("install_name_tool -change /usr/local/lib/libusb-1.0.0.dylib @rpath/libusb.dylib " + craftLibDir + "/" + "libPlayerOneCamera.dylib")
        return True
