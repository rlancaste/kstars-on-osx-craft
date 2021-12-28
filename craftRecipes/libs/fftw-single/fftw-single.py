# -*- coding: utf-8 -*-
import info
import os


class subinfo(info.infoclass):
    def setTargets(self):
        for ver in ['3.3.8']:
            self.targets[ver] = 'http://fftw.org/fftw-%s.tar.gz' % ver
            self.archiveNames[ver] = "fftw-%s.tar.gz" % ver
            self.targetInstSrc[ver] = 'fftw-' + ver
        self.description = 'C routines to compute the Discrete Fourier Transform'
        self.defaultTarget = '3.3.8'

    def setDependencies(self):
        self.runtimeDependencies["virtual/base"] = "default"


from Package.AutoToolsPackageBase import *

# Note: With these options, it doesn't build code that needs GCC or dependencies like fortran, openmp, or mpi.  
# Also it builds the single precision variant of FFTW, not the double precision or long-double precision variant
# For double precision, you should remove --enable-single
# For long double precision, you should add --enable-long-double and remove --enable-single --enable-sse2 --enable-avx and --enable-avx2

class Package(AutoToolsPackageBase):
    def __init__( self, **args ):
        AutoToolsPackageBase.__init__( self )
        self.subinfo.options.useShadowBuild = False
        prefix = str(self.shell.toNativePath(CraftCore.standardDirs.craftRoot()))
        self.subinfo.options.configure.args += "--disable-dependency-tracking" \
        " --disable-openmp" \
        " --disable-fortran" \
        " --disable-mpi" \
        " --enable-shared" \
        " --enable-threads" \
        " --enable-sse2" \
        " --enable-avx" \
        " --enable-avx2" \
        " --enable-single" \
        " --prefix=" + prefix
        
#This is required because of a current bug in fftw where it tries to include a non-existant file for projects that depend on fftw
#This bug only exists in AutoTools builds not cmake builds, but they recommend autotools builds and provide the documentation for that.
#This should fix it until they fix the bug.
    def postQmerge(self):
        root = str(CraftCore.standardDirs.craftRoot())
        craftLibDir = os.path.join(root,  'lib')
        f1name = os.path.join(craftLibDir, "cmake/fftw3/FFTW3Config.cmake")
        f1 = open(f1name, 'r')
        filedata = f1.read()
        f1.close()
        filedata = filedata.replace('\ninclude ("${CMAKE_CURRENT_LIST_DIR}/FFTW3LibraryDepends.cmake")', '\n#include ("${CMAKE_CURRENT_LIST_DIR}/FFTW3LibraryDepends.cmake")')
        f1 = open(f1name, 'w')
        f1.write(filedata)
        f1.close()
        return True







