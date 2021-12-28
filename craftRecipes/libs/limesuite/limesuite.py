# -*- coding: utf-8 -*-
import info


class subinfo(info.infoclass):
    def setTargets(self):
        for ver in ['18.10.0']:
            self.targets[ver] = 'https://github.com/myriadrf/LimeSuite/archive/v%s.tar.gz' % ver
            self.archiveNames[ver] = "limesuite-%s.tar.bz2" % ver
            self.targetInstSrc[ver] = 'LimeSuite-%s' % ver
        self.description = 'Lime suite device drivers, GUI, and SDR support'
        self.defaultTarget = '18.10.0'

    def setDependencies(self):
        self.buildDependencies["dev-utils/pkg-config"] = "default"
        self.buildDependencies["libs/swig"] = "default"
        self.buildDependencies["libs/libusb"] = "default"
        self.runtimeDependencies["virtual/base"] = "default"

from Package.CMakePackageBase import *

class Package(CMakePackageBase):
    def __init__(self):
        CMakePackageBase.__init__(self)
        self.subinfo.options.useShadowBuild = False
        root = str(CraftCore.standardDirs.craftRoot())
        self.subinfo.options.configure.args = "-DENABLE_STREAM=ON -DENABLE_GUI=OFF -DENABLE_NOVENARF7=OFF -DENABLE_SOAPY_LMS7=OFF -DLIME_SUITE_EXTVER=release -DLIME_SUITE_ROOT=" + root









