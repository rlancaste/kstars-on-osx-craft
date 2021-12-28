# -*- coding: utf-8 -*-
import info

class subinfo(info.infoclass):
    def setTargets(self):
        for ver in ['0.5.4']:
            self.targets[ver] = 'https://github.com/steve-m/librtlsdr/archive/v%s.tar.gz' % ver
            self.archiveNames[ver] = "librtlsdr-%s.tar.gz" % ver
            self.targetInstSrc[ver] = 'librtlsdr-' + ver
        self.description = 'Use Realtek DVT-T dongles as a cheap SDR'
        self.defaultTarget = '0.5.4'

    def setDependencies(self):
        self.buildDependencies["dev-utils/pkg-config"] = "default"
        self.runtimeDependencies["virtual/base"] = "default"
        self.runtimeDependencies["libs/libusb"] = "default"
        
from Package.CMakePackageBase import *

class Package(CMakePackageBase):
    def __init__(self, **args):
        CMakePackageBase.__init__(self)
        root = str(CraftCore.standardDirs.craftRoot())
        craftLibDir = os.path.join(root,  'lib')
        # both examples and tests can be run here
        self.subinfo.options.configure.args = "-DCMAKE_MACOSX_RPATH=1 -DCMAKE_INSTALL_RPATH=" + craftLibDir


