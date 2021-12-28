import info

class subinfo(info.infoclass):
    def setTargets(self):
        for ver in ['7.2']:
            self.targets[ver] = 'ftp://ftp.atnf.csiro.au/pub/software/wcslib/wcslib-%s.tar.bz2' % ver
            self.archiveNames[ver] = "wcslib-%s.tar.gz" % ver
            self.targetInstSrc[ver] = 'wcslib-' + ver

        self.defaultTarget = '7.2'

    def setDependencies(self):
        self.runtimeDependencies["virtual/base"] = None


from Package.AutoToolsPackageBase import *

class Package(AutoToolsPackageBase):
    def __init__( self, **args ):
        AutoToolsPackageBase.__init__( self )
        prefix = self.shell.toNativePath(CraftCore.standardDirs.craftRoot())
        #self.subinfo.options.configure.bootstrap = True
        self.subinfo.options.useShadowBuild = False
        self.subinfo.options.configure.args += " --disable-dependency-tracking" \
        " --prefix=#{prefix}" \
        " --without-pgplot" \
        " --disable-fortran"
        craftLibDir = os.path.join(prefix,  'lib')
        self.subinfo.options.configure.ldflags += '-Wl,-rpath,' + craftLibDir
        
    def postQmerge(self):
        packageName = "libwcs"
        root = str(CraftCore.standardDirs.craftRoot())
        craftLibDir = os.path.join(root,  'lib')
        utils.system("install_name_tool -add_rpath " + craftLibDir + " " + craftLibDir + "/" + packageName + ".dylib")
        utils.system("install_name_tool -id @rpath/" + packageName + ".dylib " + craftLibDir + "/" + packageName + ".dylib")
        return True