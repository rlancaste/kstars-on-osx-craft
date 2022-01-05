import info
from Package.CMakePackageBase import *


class subinfo(info.infoclass):
    def setTargets(self):
        self.targets['0.18.13'] = "https://www.libraw.org/data/LibRaw-0.18.13.tar.gz"
        self.archiveNames['0.18.13'] = "LibRaw-0.18.13.tar.gz"
        self.targetInstSrc['0.18.13'] = "LibRaw-0.18.13"
        self.patchToApply['0.18.13'] = [("LibRaw-0.18.13-20180720.diff", 1)]#https://github.com/LibRaw/LibRaw-cmake/
        self.targetDigests['0.18.13'] = (['cb1f9d0d1fabc8967d501d95c05d2b53d97a2b917345c66553b1abbea06757ca'], CraftHash.HashAlgorithm.SHA256)
        self.patchLevel["0.18.13"] = 1
        
        # 0.20.2
        self.targets['0.20.2'] = "https://www.indilib.org/jdownloads/libraw/LibRaw-0.20.2.tar.gz"
        self.archiveNames['0.20.2'] = "LibRaw-0.20.2.tar.gz"
        self.targetInstSrc['0.20.2'] = "LibRaw-0.20.2"        
        self.targetDigests['0.20.2'] = (['d5eba8cc57c4f6f6a1267de5967d2627f2bb27d12b9e89f65400fb76a22fc6f4'], CraftHash.HashAlgorithm.SHA256)

        self.description = "LibRaw is a library for reading RAW files obtained from digital photo cameras (CRW/CR2, NEF, RAF, DNG, and others)."

        self.defaultTarget = '0.18.13'

    def setDependencies(self):
        self.runtimeDependencies["virtual/base"] = None
        self.runtimeDependencies["libs/lcms2"] = None
        self.runtimeDependencies["libs/libjpeg-turbo"] = None


class Package(CMakePackageBase):
    def fixLibraryFolder(self, folder):
        craftLibDir = os.path.join(CraftCore.standardDirs.craftRoot(),  'lib')
        for library in utils.filterDirectoryContent(str(folder)):
            for path in utils.getLibraryDeps(str(library)):
                if path.startswith(craftLibDir):
                    utils.system(["install_name_tool", "-change", path, os.path.join("@rpath", os.path.basename(path)), library])
                if "/" not in path:
                    utils.system(["install_name_tool", "-change", path, os.path.join("@rpath", path), library])
            if library.endswith(".dylib"):
                utils.system(["install_name_tool", "-id", os.path.join("@rpath", os.path.basename(library)), library])
            utils.system(["install_name_tool", "-add_rpath", craftLibDir, library])

    def fixLibraryID(self, packageName):
        root = str(CraftCore.standardDirs.craftRoot())
        craftLibDir = os.path.join(root,  'lib')
        utils.system("install_name_tool -add_rpath " + craftLibDir + " " + craftLibDir +"/" + packageName + ".dylib")
        utils.system("install_name_tool -id @rpath/" + packageName + ".dylib " + craftLibDir +"/" + packageName + ".dylib")

    def __init__(self):
        CMakePackageBase.__init__(self)

    def install(self):
        ret = CMakePackageBase.install(self)
        if OsUtils.isMac():
             self.fixLibraryFolder(os.path.join(str(self.imageDir()),  "lib"))
             self.fixLibraryFolder(os.path.join(str(self.imageDir()),  "bin"))
        return ret

