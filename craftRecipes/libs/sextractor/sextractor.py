# -*- coding: utf-8 -*-
import info


class subinfo(info.infoclass):
    def setTargets(self):
        for ver in ['2.19.5']:
            self.targets[ver] = 'https://github.com/astromatic/sextractor/archive/refs/tags/' + ver + '.tar.gz'
            self.archiveNames[ver] = "sextractor-%s.tar.gz" % ver
            self.targetInstSrc[ver] = 'sextractor-' + ver
            self.patchToApply['2.19.5'] = [("configure.ac.diff", 1)]
            self.patchToApply['2.19.5'] += [("cx_accelerate.m4.diff", 1)]
            self.patchToApply['2.19.5'] += [("pattern.c.diff", 1)]
        self.description = 'Extractor is a program that builds a catalogue of objects from an astronomical image. Although it is particularly oriented towards reduction of large scale galaxy-survey data, it can perform reasonably well on moderately crowded star fields.'
        self.defaultTarget = '2.19.5'

    def setDependencies(self):
        self.runtimeDependencies["virtual/base"] = "default"
        self.runtimeDependencies["libs/fftw-single"] = "default"

from Package.AutoToolsPackageBase import *

class Package(AutoToolsPackageBase):
    def __init__( self, **args ):
        AutoToolsPackageBase.__init__( self )
        prefix = str(self.shell.toNativePath(CraftCore.standardDirs.craftRoot()))
       	#self.subinfo.options.configure.bootstrap = True
       	self.subinfo.options.useShadowBuild = False
        self.subinfo.options.configure.args += " --disable-dependency-tracking" \
        " --enable-accelerate" \
        " --prefix=" + prefix


 #	Note that this setting of the environment flags to not have an error on implicit declarations of functions solves an error in building in XCode 12
    def configure(self):
        self.shell.environment["CFLAGS"]+="-Wno-implicit-function-declaration"
        AutoToolsPackageBase.configure(self)
        return True

