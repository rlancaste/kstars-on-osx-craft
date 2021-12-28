# -*- coding: utf-8 -*-
import info

class subinfo(info.infoclass):
    def setTargets(self):
        for ver in ["2019.01.06"]:
            self.targets[ver] = f"https://ftp.gnu.org/gnu/autoconf-archive/autoconf-archive-{ver}.tar.xz"
            self.archiveNames[ver] = f"autoconf-archive-{ver}.tar.xz"
            self.targetInstSrc[ver] = "autoconf-archive-%s" % ver
        self.description = "Collection of over 500 reusable autoconf macros"
        self.webpage = "https://savannah.gnu.org/projects/autoconf-archive/"
        self.defaultTarget = "2019.01.06"

    def setDependencies(self):
        self.runtimeDependencies["virtual/base"] = None
        self.runtimeDependencies["autoconf"] = None


# I'm not sure why I had to rewrite the configure make and install commands, they failed when it was automatic.

from Package.AutoToolsPackageBase import *

class Package(AutoToolsPackageBase):
    def __init__( self, **args ):
        AutoToolsPackageBase.__init__( self )
        prefix = str(self.shell.toNativePath(CraftCore.standardDirs.craftRoot()))
        self.subinfo.options.configure.bootstrap = True
        self.subinfo.options.useShadowBuild = True
        self.subinfo.options.configure.args += " --prefix=" + prefix

    def configure(self):
        self.enterSourceDir()
        prefix = str(self.shell.toNativePath(CraftCore.standardDirs.craftRoot()))
        utils.system("./configure --prefix=" + prefix)
        return True
    
    def make(self):
        self.enterSourceDir()
        utils.system("make")
        return True
    
    def install(self):
        self.enterSourceDir()
        utils.system("make install")
        return True
    