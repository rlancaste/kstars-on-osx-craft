# -*- coding: utf-8 -*-
import info


class subinfo(info.infoclass):
    def setTargets(self):
        for ver in ['2.5.27']:
            self.targets[ver] = 'https://downloads.sourceforge.net/project/gphoto/libgphoto/' + ver + '/libgphoto2-' + ver +  '.tar.bz2'
            self.archiveNames[ver] = "libgphoto2-%s.tar.gz" % ver
            self.targetInstSrc[ver] = 'libgphoto2-' + ver
        self.description = 'Gphoto2 digital camera library'
        self.defaultTarget = '2.5.27'

    def setDependencies(self):
        self.buildDependencies["libs/gettext"] = "default"
        self.buildDependencies["dev-utils/pkg-config"] = "default"
        self.runtimeDependencies["virtual/base"] = "default"
        self.runtimeDependencies["libs/glibtool"] = "default"
        self.runtimeDependencies["libs/libusb-compat"] = "default"
        #gd and libexif might be needed too

from Package.AutoToolsPackageBase import *

class Package(AutoToolsPackageBase):
    def __init__( self, **args ):
        AutoToolsPackageBase.__init__( self )
        prefix = str(self.shell.toNativePath(CraftCore.standardDirs.craftRoot()))
       	#self.subinfo.options.configure.bootstrap = True
       	self.subinfo.options.useShadowBuild = False
        self.subinfo.options.configure.args += " --disable-dependency-tracking" \
        " --disable-silent-rules" \
        " --prefix=" + prefix







