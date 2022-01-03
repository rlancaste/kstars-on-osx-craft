# -*- coding: utf-8 -*-
import info
import os


class subinfo(info.infoclass):
    def setTargets(self):
        for ver in ['3.3.10']:
            self.targets[ver] = 'http://fftw.org/fftw-%s.tar.gz' % ver
            self.archiveNames[ver] = "fftw-%s.tar.gz" % ver
            self.targetInstSrc[ver] = 'fftw-' + ver
        self.description = 'C routines to compute the Discrete Fourier Transform'
        self.defaultTarget = '3.3.10'

    def setDependencies(self):
        self.runtimeDependencies["virtual/base"] = "default"


from Package.AutoToolsPackageBase import *

# Note: With these options, it doesn't build code that needs GCC or dependencies like fortran, openmp, or mpi.  
# Also it builds the double precision variant of FFTW, not the single precision or long-double precision variant
# For single precision, you should add --enable-single
# For long double precision, you should add --enable-long-double and remove --enable-sse2 --enable-avx and --enable-avx2

class Package(AutoToolsPackageBase):
    def __init__( self, **args ):
        AutoToolsPackageBase.__init__( self )
        self.subinfo.options.useShadowBuild = False
        prefix = str(self.shell.toNativePath(CraftCore.standardDirs.craftRoot()))
        self.subinfo.options.configure.args += "--disable-dependency-tracking" \
        " --disable-openmp" \
        " --disable-debug" \
        " --disable-fortran" \
        " --disable-mpi" \
        " --enable-shared" \
        " --enable-threads" \
       # " --enable-sse2" \
       # " --enable-avx" \    Disabling these options so it compiles on M1 Macs
       # " --enable-avx2" \
        " --prefix=" + prefix

