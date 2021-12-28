import info

class subinfo(info.infoclass):
    def setTargets(self):
        for ver in ['0.20.2']:
            self.targets[ver] = 'https://www.libraw.org/data/LibRaw-' + ver + '.tar.gz'
            self.archiveNames[ver] = "LibRaw-%s.tar.gz" % ver
            self.targetInstSrc[ver] = 'LibRaw-' + ver
            self.targetDigests[ver] = (['dc1b486c2003435733043e4e05273477326e51c3ea554c6864a4eafaff1004a6'], CraftHash.HashAlgorithm.SHA256)

        self.description = "LibRaw is a library for reading RAW files obtained from digital photo cameras (CRW/CR2/CR3, NEF, RAF, DNG, and others)."
        self.defaultTarget = '0.20.2'

    def setDependencies(self):
        self.runtimeDependencies["virtual/base"] = None
        self.runtimeDependencies["libs/jasper"] = None
        self.runtimeDependencies["libs/lcms2"] = None
        self.runtimeDependencies["libs/libjpeg-turbo"] = None


from Package.AutoToolsPackageBase import *

class Package(AutoToolsPackageBase):
    def __init__( self, **args ):
        AutoToolsPackageBase.__init__( self )
        prefix = str(self.shell.toNativePath(CraftCore.standardDirs.craftRoot()))
       	self.subinfo.options.useShadowBuild = False
        self.subinfo.options.configure.args += " --disable-dependency-tracking" \
        " --disable-silent-rules" \
        " --prefix=" + prefix