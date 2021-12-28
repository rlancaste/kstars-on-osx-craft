# -*- coding: utf-8 -*-
import info


class subinfo(info.infoclass):
    def setTargets(self):
        for ver in ['2.4.6']:
            self.targets[ver] = 'https://ftp.gnu.org/gnu/libtool/libtool-%s.tar.xz' % ver
            self.archiveNames[ver] = "libtool-%s.tar.gz" % ver
            self.targetInstSrc[ver] = 'libtool-' + ver
        self.description = 'Generic library support script'
        self.defaultTarget = '2.4.6'

    def setDependencies(self):
        self.runtimeDependencies["virtual/base"] = "default"

from Package.AutoToolsPackageBase import *

class Package(AutoToolsPackageBase):
    def __init__( self, **args ):
        AutoToolsPackageBase.__init__( self )
        prefix = str(self.shell.toNativePath(CraftCore.standardDirs.craftRoot()))
        # prevent libtool from hardcoding sed path from superenv
        self.subinfo.options.configure.autoreconf = False
       	os.environ['SED'] = "sed"
       	self.subinfo.options.useShadowBuild = False
        self.subinfo.options.configure.args += " --disable-dependency-tracking" \
        " --disable-silent-rules" \
        " --program-prefix=g" \
        " --enable-ltdl-install" \
        " --prefix=" + prefix




