# -*- coding: utf-8 -*-
import info


class subinfo(info.infoclass):
    def setTargets(self):
        for ver in ['8.45']:
            self.targets[ver] = f"https://sourceforge.net/projects/pcre/files/pcre/{ver}/pcre-{ver}.tar.bz2"
            self.targetInstSrc[ver] = f"pcre-{ver}"
            self.archiveNames[ver] = "pcre-%s.tar.gz" % ver
        self.description = 'Perl compatible regular expressions library'
        self.defaultTarget = '8.45'

    def setDependencies(self):
        self.runtimeDependencies["virtual/base"] = "default"
        self.runtimeDependencies["libs/libbzip2"] = "default"
        self.runtimeDependencies["libs/zlib"] = "default"
       # self.runtimeDependencies["libs/glibtool"] = "default"

from Package.AutoToolsPackageBase import *

class Package(AutoToolsPackageBase):
    def fixLibraryID(self, packageName):
        root = str(CraftCore.standardDirs.craftRoot())
        craftLibDir = os.path.join(root,  'lib')
        utils.system("install_name_tool -add_rpath " + craftLibDir + " " + craftLibDir +"/" + packageName + ".dylib")
        utils.system("install_name_tool -id @rpath/" + packageName + ".dylib " + craftLibDir +"/" + packageName + ".dylib")

    def __init__( self, **args ):
        AutoToolsPackageBase.__init__( self )
        prefix = self.shell.toNativePath(CraftCore.standardDirs.craftRoot())
        #self.subinfo.options.configure.bootstrap = True
        self.subinfo.options.useShadowBuild = False
        self.subinfo.options.configure.args += " --disable-dependency-tracking" \
        " --prefix=#{prefix}" \
        " --enable-utf8" \
        " --enable-pcre8" \
        " --enable-pcre16" \
        " --enable-pcre32" \
        " --enable-unicode-properties" \
        " --enable-pcregrep-libz" \
        " --enable-pcregrep-libbz2" \
        " --enable-jit"

    def postQmerge(self):
        self.fixLibraryID("libpcre")
        self.fixLibraryID("libpcrecpp")
        self.fixLibraryID("libpcreposix")
        root = str(CraftCore.standardDirs.craftRoot())
        craftLibDir = os.path.join(root,  'lib')
        utils.system("install_name_tool -change libpcre.dylib @rpath/libpcre.dylib " + craftLibDir +  "/" + "libpcrecpp.dylib")
        utils.system("install_name_tool -change libpcre.dylib @rpath/libpcre.dylib " + craftLibDir +  "/" + "libpcreposix.dylib")
        return True






