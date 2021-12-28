# -*- coding: utf-8 -*-
import info


class subinfo(info.infoclass):
    def setTargets(self):
        for ver in ['0.76']:
            self.targets[ver] = 'https://github.com/dstndstn/astrometry.net/releases/download/'+ ver + '/astrometry.net-'+ ver + '.tar.gz'
            #self.targets[ver] = 'http://astrometry.net/downloads/astrometry.net-%s.tar.gz' % ver
            self.archiveNames[ver] = "astrometry.net-%s.tar.gz" % ver
            self.targetInstSrc[ver] = 'astrometry.net-' + ver
        self.targetDigests['0.76'] = 'e253ee3f58bf8800b7c6d4dcbdaeeb1919b8122f'
        self.description = 'astrometry.net, for plate solving astronomical images'
        self.defaultTarget = '0.76'

    def setDependencies(self):
        self.buildDependencies["libs/swig"] = "default"
        self.runtimeDependencies["libs/astrometry.net"] = "default"
        self.buildDependencies["dev-utils/pkg-config"] = "default"
        self.runtimeDependencies["virtual/base"] = "default"
        self.runtimeDependencies["libs/cfitsio"] = "default"
        self.runtimeDependencies["libs/libjpeg-turbo"] = "default"
        self.runtimeDependencies["libs/libpng"] = "default"
        self.runtimeDependencies["libs/wcslib"] = "default"
        self.runtimeDependencies["libs/gsl"] = "default"

from Package.AutoToolsPackageBase import *

class Package(AutoToolsPackageBase):
    def __init__( self, **args ):
        AutoToolsPackageBase.__init__( self )
        root = str(self.shell.toNativePath(CraftCore.standardDirs.craftRoot()))
        
        self.subinfo.options.useShadowBuild = False
        
        craftLibDir = os.path.join(root,  'lib')
        self.subinfo.options.configure.ldflags += '-Wl,-rpath,' + craftLibDir
        
    def configure(self):
        #This is for the one in Craft Root
        root = str(self.shell.toNativePath(CraftCore.standardDirs.craftRoot()))
        astrometryInstallDir = os.path.join(root,"astrometry")
        os.environ['INSTALL_DIR'] = astrometryInstallDir
        return AutoToolsPackageBase.configure(self)
