#!/bin/sh

#set -x
#set +k
# this is so the cmd results are grabbed not hte result of the pipe
set -o pipefail

#special requirements not checked yet:
#1) libtool >= 2.4.2 (the shipped 2.2 version fails 
#2) pkgconfig.pkg in /usr/share/aclocal (have to copy it in from the orig 
#3) cmake >= 2.8.7
#4) qemu-arm-static >= 1.2.0

export SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"

# set this to what you want
KLAATU_NUMJOBS="-j20"
KLAATU_VERBOSE="V=1"


#
KLAATU_TOPDIR=$SCRIPT_DIR
#`pwd`
KLAATU_TMPDIR=`pwd`;
KLAATU_SUPPORTDIR=$KLAATU_TOPDIR/support_files
KLAATU_INFODIR=kwebkit_progress
if [ "$1" != "" ]; then
    KLAATU_TMPDIR=`readlink -f $1`
fi
KLAATU_BUILDDIR=$KLAATU_TMPDIR/kwebkit_build_dir
KLAATU_SRCDIR=$KLAATU_TMPDIR/kwebkit_src_downloads
KLAATU_PATCHDIR=$KLAATU_TOPDIR/patches


function cmdCheck {
    KLAATU_LOCALCC_RESULT=$1
    KLAATU_LOCALCC_PKG=$2
    KLAATU_LOCALCC_CMD=$3

    if [ $KLAATU_LOCALCC_RESULT -gt 0 ]; then
	echo "$KLAATU_LOCALCC_CMD failed $KLAATU_LOCAL_PKG"
	#patches check this xple times
	rm -f ${KLAATU_INFODIR}/kwebkit_${KLAATU_LOCALCC_CMD}.compleat
	exit 1
    fi
    touch ${KLAATU_INFODIR}/kwebkit_${KLAATU_LOCALCC_CMD}.compleat
 
}  

function cmdTryPatch {
    KLAATU_LOCAL_CMD=$1
    KLAATU_LOCAL_PKG=$2
    cd $KLAATU_BUILDDIR/$KLAATU_LOCAL_PKG
    if [ ! -e ${KLAATU_INFODIR}/kwebkit_${KLAATU_LOCAL_CMD}.compleat ]; then
	if [ -d $KLAATU_PATCHDIR/${KLAATU_LOCAL_PKG} ]; then
	    for i in $KLAATU_PATCHDIR/${KLAATU_LOCAL_PKG}/*; do
		${KLAATU_LOCAL_CMD} -p1 < $i 2>&1 | tee -a ${KLAATU_INFODIR}/kwebkit_${KLAATU_LOCAL_CMD}.log
		cmdCheck $? $KLAATU_LOCAL_PKG $KLAATU_LOCAL_CMD
	    done
	else
	    echo "No patches for $KLAATU_LOCAL_PKG"
	fi
    else
	echo "$KLAATU_LOCAL_CMD has already been run for $KLAATU_LOCAL_PKG"
    fi
}
function cmdTry {
    KLAATU_LOCALCT_CMD=$1
    KLAATU_LOCALCT_PKG=$2
    KLAATU_LOCALCT_ARGS=$3
    cd $KLAATU_BUILDDIR/$KLAATU_LOCALCT_PKG
    if [ ! -e ${KLAATU_INFODIR}/kwebkit_${KLAATU_LOCALCT_CMD}.compleat ]; then
	echo "Running ->${KLAATU_LOCALCT_CMD} $KLAATU_LOCALCT_ARGS" for $KLAATU_LOCALCT_PKG in `pwd`
	if [ -f $KLAATU_LOCALCT_CMD -a  ! -x $KLAATU_LOCALCT_CMD ]; then
	    chmod a+x $KLAATU_LOCALCT_CMD
	fi
	KLAATU_LOCALCT_LOG=${KLAATU_INFODIR}/kwebkit_${KLAATU_LOCALCT_CMD}.log
	if [ -f $KLAATU_LOCALCT_CMD ]; then
	    KLAATU_LOCALCT_CMD="./$1"
	fi
	${KLAATU_LOCALCT_CMD} $KLAATU_LOCALCT_ARGS 2>&1 | tee  $KLAATU_LOCALCT_LOG
	cmdCheck $? $KLAATU_LOCALCT_PKG $KLAATU_LOCALCT_CMD	
    else
	echo "$KLAATU_LOCALCT_CMD has already been run for $KLAATU_LOCALCT_PKG"
    fi
}

# this is pretty much just for icu at the moment.  
# we could probably use it to separate the make and make install 
# parts of the build if we need to for more than just nettle
function cmdTryDeluxe {
    KLAATU_LOCALCTD_CMD=$1
    KLAATU_LOCALCTD_PKG=$2
    KLAATU_LOCALCTD_ARGS=$3
    KLAATU_LOCALCTD_FLAGNAME=$4
    
    if [ "$KLAATU_LOCALCTD_FLAGNAME" == "" ]; then
	echo "If there's no flag name, you shouldn't be using this function"
	exit -1;
    fi
    cd $KLAATU_BUILDDIR/$KLAATU_LOCALCTD_PKG
    mkdir -p $KLAATU_INFODIR

    if [ ! -e ${KLAATU_INFODIR}/kwebkit_${KLAATU_LOCALCTD_FLAGNAME}.compleat ]; then
	echo "Running ->${KLAATU_LOCALCTD_CMD} $KLAATU_LOCALCTD_ARGS" for $KLAATU_LOCALCTD_PKG in `pwd`
	if [ -f $KLAATU_LOCALCTD_CMD -a  ! -x $KLAATU_LOCALCTD_CMD ]; then
	    chmod a+x $KLAATU_LOCALCTD_CMD
	fi
	${KLAATU_LOCALCTD_CMD} $KLAATU_LOCALCTD_ARGS 2>&1 | tee  ${KLAATU_INFODIR}/kwebkit_${KLAATU_LOCALCTD_FLAGNAME}.log
	cmdCheck $? $KLAATU_LOCALCTD_PKG $KLAATU_LOCALCTD_FLAGNAME	
    else
	echo "$KLAATU_LOCALCTD_CMD has already been run for $KLAATU_LOCALCTD_PKG"
    fi
}

function untarTry {
    KLAATU_LOCAL_PKG=$1
    cd $KLAATU_BUILDDIR
    if [ ! -d $KLAATU_LOCAL_PKG ]; then
	tar xf ${KLAATU_SRCDIR}/${KLAATU_LOCAL_PKG}*
    fi
    mkdir -p $KLAATU_BUILDDIR/$KLAATU_LOCAL_PKG/$KLAATU_INFODIR
 


}
# and nix is special
function buildWebKitNix {
    KLAATU_LOCAL_PKG=$1
    KLAATU_LOCAL_PKG_BUILDDIR=$KLAATU_LOCAL_PKG/WebKitBuild/kwebkit

    untarTry $KLAATU_LOCAL_PKG
    cd $KLAATU_BUILDDIR/$KLAATU_LOCAL_PKG
    echo "**** Working on $KLAATU_LOCAL_PKG ****"
    mkdir -p WebKitBuild/kwebkit
    # for debugging issues
    #printenv | tee WebKitBuild/kwebkit/kwebkit_env_used_to_build
    cmdTryDeluxe cmake_webkitnix_build_cmd $KLAATU_LOCAL_PKG_BUILDDIR  "" cmake
    cmdTryDeluxe make $KLAATU_LOCAL_PKG_BUILDDIR "${KLAATU_NUMJOBS} ${KLAATU_VERBOSE}" make
    rsync -a bin/ ${ANDROID_BUILD_TOP}/usr/local/bin/
    rsync -a lib/ ${ANDROID_BUILD_TOP}/usr/local/lib/
    echo
}


# and some packages can only run configure....
function buildTryNoreconf {
    KLAATU_LOCAL_PKG=$1
    KLAATU_LOCAL_CONFIG_ARGS="--prefix=${ANDROID_BUILD_TOP}/usr/local --host=arm-linux --disable-docs"
    if [ "$2" != "" ]; then
	KLAATU_LOCAL_CONFIG_ARGS="$KLAATU_LOCAL_CONFIG_ARGS $2"
    fi
    untarTry $KLAATU_LOCAL_PKG
    cd $KLAATU_BUILDDIR/$KLAATU_LOCAL_PKG
    echo "**** Working on $KLAATU_LOCAL_PKG ****"
    cmdTryPatch patch $KLAATU_LOCAL_PKG
    cmdTry configure $KLAATU_LOCAL_PKG  "$KLAATU_LOCAL_CONFIG_ARGS"
    cmdTry make $KLAATU_LOCAL_PKG "${KLAATU_NUMJOBS} ${KLAATU_VERBOSE} install"
    echo
}

# some packages can be autoreconfed but not  the full autogen.sh style startup.
function buildTryAutoreconf {
    KLAATU_LOCAL_PKG=$1
    KLAATU_LOCAL_CONFIG_ARGS="--prefix=${ANDROID_BUILD_TOP}/usr/local --host=arm-linux --disable-docs"
    if [ "$2" != "" ]; then
	KLAATU_LOCAL_CONFIG_ARGS="$KLAATU_LOCAL_CONFIG_ARGS $2"
    fi
    untarTry $KLAATU_LOCAL_PKG
    cd $KLAATU_BUILDDIR/$KLAATU_LOCAL_PKG
    echo "**** Working on $KLAATU_LOCAL_PKG ****"
    cmdTryPatch patch $KLAATU_LOCAL_PKG
    cmdTry autoreconf $KLAATU_LOCAL_PKG "--force --install "
    cmdTry configure $KLAATU_LOCAL_PKG  "$KLAATU_LOCAL_CONFIG_ARGS"    
    cmdTry make $KLAATU_LOCAL_PKG "${KLAATU_NUMJOBS} ${KLAATU_VERBOSE} install"
    echo
}

function buildTry {
    KLAATU_LOCAL_PKG=$1
    KLAATU_LOCAL_CONFIG_ARGS="--prefix=${ANDROID_BUILD_TOP}/usr/local --host=arm-linux --disable-docs"
    if [ "$2" != "" ]; then
	KLAATU_LOCAL_CONFIG_ARGS="$KLAATU_LOCAL_CONFIG_ARGS $2"
    fi
    untarTry $KLAATU_LOCAL_PKG
    cd $KLAATU_BUILDDIR/$KLAATU_LOCAL_PKG
    echo "**** Working on $KLAATU_LOCAL_PKG ****"
    cmdTryPatch patch $KLAATU_LOCAL_PKG
    cmdTry libtoolize $KLAATU_LOCAL_PKG "--force --copy --automake"
    if [ -d m4 ]; then
	cmdTry aclocal $KLAATU_LOCAL_PKG "-I m4"
    else
	cmdTry aclocal $KLAATU_LOCAL_PKG
    fi
    cmdTry autoheader $KLAATU_LOCAL_PKG
    cmdTry automake $KLAATU_LOCAL_PKG "--force-missing --foreign -a -c"
    cmdTry autoconf $KLAATU_LOCAL_PKG 
    cmdTry configure $KLAATU_LOCAL_PKG  "$KLAATU_LOCAL_CONFIG_ARGS"
    cmdTry make $KLAATU_LOCAL_PKG "${KLAATU_NUMJOBS} ${KLAATU_VERBOSE} install"
    echo
}

# the ##$$#% icu folks don't bother putting a version in their tar downloads.
function buildICU {
    KLAATU_LOCAL_PKG=icu
    KLAATU_LOCAL_PKG_X86=${KLAATU_LOCAL_PKG}_x86
    KLAATU_LOCAL_PKG_ARM=${KLAATU_LOCAL_PKG}_arm
    KLAATU_LOCAL_CONFIG_ARGS_X86=""
    KLAATU_LOCAL_CONFIG_ARGS_ARM="--prefix=${ANDROID_BUILD_TOP}/usr/local --host=arm-linux --with-cross-build=$KLAATU_BUILDDIR/$KLAATU_LOCAL_PKG_X86  --enable-extras=no --enable-strict=no "
    untarTry $KLAATU_LOCAL_PKG
    cmdTryPatch patch $KLAATU_LOCAL_PKG

    # make the x86 one first
    echo "**** Working on $KLAATU_LOCAL_PKG_X86 ****"
    export CFLAGS=""
    export CXXFLAGS=""
    export LDFLAGS=""
    mkdir -p  $KLAATU_BUILDDIR/$KLAATU_LOCAL_PKG_X86
    cd $KLAATU_BUILDDIR/$KLAATU_LOCAL_PKG_X86
    cmdTryDeluxe ../$KLAATU_LOCAL_PKG/source/configure $KLAATU_LOCAL_PKG_X86  "$KLAATU_LOCAL_CONFIG_ARGS_X86" configure
    cmdTry make $KLAATU_LOCAL_PKG_X86 "${KLAATU_NUMJOBS} ${KLAATU_VERBOSE}"
    echo 
    # now make the arm one
    echo "**** Working on $KLAATU_LOCAL_PKG_ARM ****"
    export CFLAGS="$KLAATU_CFLAGS_ORIG  "
    export CXXFLAGS="$KLAATU_CXXFLAGS_ORIG "
    export LDFLAGS="$KLAATU_LDFLAGS_ORIG"
    mkdir -p  $KLAATU_BUILDDIR/$KLAATU_LOCAL_PKG_ARM
    cd $KLAATU_BUILDDIR/$KLAATU_LOCAL_PKG_ARM
    cmdTryDeluxe ../$KLAATU_LOCAL_PKG/source/configure $KLAATU_LOCAL_PKG_ARM  "$KLAATU_LOCAL_CONFIG_ARGS_ARM" configure
    cmdTry make $KLAATU_LOCAL_PKG_ARM "${KLAATU_NUMJOBS} ${KLAATU_VERBOSE} install "
    echo
    
}



#this checks for things needed to build.  It is not yet complete :(
if [ "$ANDROID_BUILD_TOP" == "" ]; then
    echo "you need a full AOSP build and you need to have run lunch..."
    exit -1;
fi

KLAATU_TC=`which arm-linux-gcc`;

if [ "$KLAATU_TC" == "" ]; then
    echo "
You need to set up your toolchain to have softlinks of the form arm-linux-xxx
I am currently targetting the android-ndk-r8d gcc 4.6 toolchain so I have a 
'niceBin' with links in it like :
android-ndk-r8d/toolchains/arm-linux-androideabi-4.6/prebuilt/linux-x86/niceBin/arm-linux-gcc -> ../bin/arm-linux-androideabi-gcc
for the whole toolchain.  This makes configure happy even with older packages that don't necessarily recognize the quad format.
"
    exit -1;
fi

if [ "$ANDROID_NDK_TOP" == "" ]; then
    echo "need to set ANDROID_NDK_TOP since this is an ndk based build now"
    exit -1
fi

if [ ! -e ${KLAATU_SUPPORTDIR}/configure_header ]; then
    echo "missing the configure_header file..."
    exit -1
fi
if [ ! -e ${KLAATU_SUPPORTDIR}/make_header ]; then
    echo "missing the make_header file..."
    exit -1
fi

if [ ! -e ${KLAATU_SUPPORTDIR}/ca-certs-ubuntu-12.04.tar.bz2 ]; then
    echo "missing the ca-certs tarball..."
    exit -1
fi

if [ ! -e ${KLAATU_SUPPORTDIR}/KlaatuPhoneEnvSet ]; then
    echo "missing the KlaatuPhoneEnvSet script..."
    exit -1
fi


mkdir -p $KLAATU_BUILDDIR
# the build is VERY order dependent
# generalzing it wouldnt help much since the 
# patches are also version dependent
source  ${KLAATU_SUPPORTDIR}/configure_header
source  ${KLAATU_SUPPORTDIR}/make_header
KLAATU_CFLAGS_ORIG=$CFLAGS
KLAATU_CXXFLAGS_ORIG=$CXXFLAGS
KLAATU_LDFLAGS_ORIG=$LDFLAGS
KLAATU_PATH_ORIG=$PATH
KLAATU_LD_LIBRARY_PATH_ORIG=$LD_LIBRARY_PATH

#  libpng
export CFLAGS="$KLAATU_CFLAGS_ORIG "
export CXXFLAGS="$KLAATU_CXXFLAGS_ORIG"
export LDFLAGS="$KLAATU_LDFLAGS_ORIG"

buildTry libpng-1.2.50



#  pixman-0.24
export CFLAGS=" -DPIXMAN_NO_TLS -include pixman-extra/pixman-elf-fix.h $KLAATU_CFLAGS_ORIG "
export CXXFLAGS=" -DPIXMAN_NO_TLS $KLAATU_CXXFLAGS_ORIG"
export LDFLAGS="$KLAATU_LDFLAGS_ORIG"
buildTry pixman-0.24.0  "--disable-arm-iwmmxt"

# freetype-2.4.2
# isn't standard. sigh
export CFLAGS="$KLAATU_CFLAGS_ORIG "
export CXXFLAGS="$KLAATU_CXXFLAGS_ORIG"
export LDFLAGS="$KLAATU_LDFLAGS_ORIG"
untarTry freetype-2.4.2
echo "**** Working on freetype-2.4.2 ****"
cmdTryPatch patch freetype-2.4.2
cmdTry autogen.sh freetype-2.4.2
cmdTry configure freetype-2.4.2 "--prefix=${ANDROID_BUILD_TOP}/usr/local --host=arm-linux --disable-docs"
cmdTry make $KLAATU_LOCAL_PKG "${KLAATU_NUMJOBS} ${KLAATU_VERBOSE} install"

#  libxml2
export CFLAGS="$KLAATU_CFLAGS_ORIG "
export CXXFLAGS="$KLAATU_CXXFLAGS_ORIG"
export LDFLAGS="$KLAATU_LDFLAGS_ORIG"
buildTry libxml2-2.7.6 " --without-iconv --without-python"

#  libxslt
export CFLAGS="$KLAATU_CFLAGS_ORIG "
export CXXFLAGS="$KLAATU_CXXFLAGS_ORIG"
export LDFLAGS="$KLAATU_LDFLAGS_ORIG"
buildTry libxslt-1.1.26 " --with-libxml-prefix=${ANDROID_BUILD_TOP}/usr/local  --without-crypto --without-python"

# fontconfig
export CFLAGS="$KLAATU_CFLAGS_ORIG "
export CXXFLAGS="$KLAATU_CXXFLAGS_ORIG"
export LDFLAGS="$KLAATU_LDFLAGS_ORIG"
buildTry fontconfig-2.8.0  " --with-arch=arm --with-cache-dir=/data/usr/local/fontconfig-cache --with-default-fonts=/data/usr/local/share/fonts"

# libffi
export CFLAGS="$KLAATU_CFLAGS_ORIG "
export CXXFLAGS="$KLAATU_CXXFLAGS_ORIG"
export LDFLAGS="$KLAATU_LDFLAGS_ORIG"
buildTryNoreconf libffi-3.0.11  

# libiconv
# sadly rerunning autotools on libiconv requires all new autotools.
# luckily, it doesn't mind the libtool mismatch.  go figure.
export CFLAGS="$KLAATU_CFLAGS_ORIG  -include time.h "
export CXXFLAGS="$KLAATU_CXXFLAGS_ORIG"
export LDFLAGS="$KLAATU_LDFLAGS_ORIG"

echo "**** Working on libiconv-1.14 ****"
untarTry libiconv-1.14
cd $KLAATU_BUILDDIR/libiconv-1.14
cmdTry configure libiconv-1.14  "--prefix=${ANDROID_BUILD_TOP}/usr/local --host=arm-linux --disable-docs --disable-nls"
cmdTry make libiconv-1.14 "${KLAATU_NUMJOBS} ${KLAATU_VERBOSE} install"


# gettext-0.18
export CFLAGS="$KLAATU_CFLAGS_ORIG -include time.h "
export CXXFLAGS="$KLAATU_CXXFLAGS_ORIG -include time.h "
export LDFLAGS="$KLAATU_LDFLAGS_ORIG"
buildTryAutoreconf gettext-0.18 " --disable-option-checking --enable-threads=pth --disable-curses --disable-acl --disable-libasprintf --disable-openmp --without-emacs --disable-java "


# glib-2.33.2
export CFLAGS="$KLAATU_CFLAGS_ORIG  "
export CXXFLAGS="$KLAATU_CXXFLAGS_ORIG "
export LDFLAGS="$KLAATU_LDFLAGS_ORIG"
buildTryAutoreconf glib-2.33.2 " --disable-silent-rules --disable-rebuilds --disable-modular-tests --disable-selinux --disable-fam --disable-xattr --disable-gtk-doc-html --disable-dtrace --disable-systemtap --disable-gcov --with-libiconv=gnu "



# gmp
export CFLAGS=" $KLAATU_CFLAGS_ORIG "
export CXXFLAGS=" $KLAATU_CXXFLAGS_ORIG"
export LDFLAGS="$KLAATU_LDFLAGS_ORIG"
buildTry gmp-5.0.5


# nettle
export CFLAGS="$KLAATU_CFLAGS_ORIG "
export CXXFLAGS="$KLAATU_CXXFLAGS_ORIG"
export LDFLAGS="$KLAATU_LDFLAGS_ORIG"
# this fails because nettles makefiles are screwed up.
# make install fails but a make;make install works.  sigh.
#buildTryAutoreconf nettle-2.5  
echo "**** Working on nettle-2.5  ****"
untarTry nettle-2.5
cd $KLAATU_BUILDDIR/nettle-2.5
cmdTry configure nettle-2.5  "--prefix=${ANDROID_BUILD_TOP}/usr/local --host=arm-linux --enable-public-key" 
cmdTry make nettle-2.5 "${KLAATU_NUMJOBS} ${KLAATU_VERBOSE} "
mv -n ${KLAATU_INFODIR}/kwebkit_make.compleat ${KLAATU_INFODIR}/kwebkit_make_noinstall.compleat
mv -n ${KLAATU_INFODIR}/kwebkit_make.log ${KLAATU_INFODIR}/kwebkit_make_noinstall.log
cmdTry make nettle-2.5 "${KLAATU_NUMJOBS} ${KLAATU_VERBOSE} install"

# gnutls-2.12.20
export CFLAGS="$KLAATU_CFLAGS_ORIG  "
export CXXFLAGS="$KLAATU_CXXFLAGS_ORIG "
export LDFLAGS="$KLAATU_LDFLAGS_ORIG"
buildTryAutoreconf gnutls-2.12.20 " --disable-silent-rules --disable-gtk-doc-html --enable-threads=pth   --disable-guile --without-pk11-kit  --disable-cxx "

# glib-networking-2.33.2
export CFLAGS="$KLAATU_CFLAGS_ORIG  "
export CXXFLAGS="$KLAATU_CXXFLAGS_ORIG "
export LDFLAGS="$KLAATU_LDFLAGS_ORIG"
buildTryNoreconf glib-networking-2.33.2 " --disable-silent-rules --disable-nls --disable-glibtest --disable-gcov --with-libproxy=no"

# icu4c-4_8_1_1
# this is the weirdest build we have.
# We need to first build it for x86 (not install)
# then we build the cross by pointing it at the x86 build.
# all builds are done in shadow directories
# I'll encapsulate this in a special buildICU function since it 
# is sooo messy :(
buildICU

# cairo-1.12.8
export CFLAGS="$KLAATU_CFLAGS_ORIG  "
export CXXFLAGS="$KLAATU_CXXFLAGS_ORIG "
# this one works with the gold linker
#export LDFLAGS="$KLAATU_LDFLAGS_ORIG -lglib-2.0 "
# bfd needs more explicit libs added
export LDFLAGS="$KLAATU_LDFLAGS_ORIG -lglib-2.0 -lintl -liconv -lGLESv2 -llog -lcutils -lEGL -lutils -lGLES_trace -lcorkscrew -lz -lstlport -lgccdemangle"
# needs to be autoreconfed since one of the patches is to an ac file.
buildTryAutoreconf  cairo-1.12.8 " --enable-tee  --enable-glesv2 --with-x=no --enable-xlib=no --enable-xcb=no"


# harfbuzz
export CFLAGS="$KLAATU_CFLAGS_ORIG  "
export CXXFLAGS="$KLAATU_CXXFLAGS_ORIG "
# this works for the gold linker but bnot for bfd
#export LDFLAGS="$KLAATU_LDFLAGS_ORIG"
export LDFLAGS="$KLAATU_LDFLAGS_ORIG -lglib-2.0 -lintl -liconv -lGLESv2 -llog -lcutils -lEGL -lutils -lGLES_trace -lcorkscrew -lz -lstlport -lgccdemangle"
export PATH="$PATH:${ANDROID_BUILD_TOP}/usr/local/bin"
export LD_LIBRARY_PATH="${ANDROID_BUILD_TOP}/usr/local/lib:${ANDROID_BUILD_TOP}/usr/lib:${ANDROID_NDK_TOP}/sources/cxx-stl/gnu-libstdc++/4.6/libs/armeabi-v7a"
buildTryNoreconf harfbuzz-0.9.6 
export PATH=$KLAATU_PATH_ORIG
export LD_LIBRARY_PATH_ORIG=$KLAATU_LD_LIBRARY_PATH_ORIG


# libsoup-2.39.4.1
export CFLAGS="$KLAATU_CFLAGS_ORIG  "
export CXXFLAGS="$KLAATU_CXXFLAGS_ORIG "
# this works for the gold linker but bnot for bfd
#export LDFLAGS="$KLAATU_LDFLAGS_ORIG"
export LDFLAGS="$KLAATU_LDFLAGS_ORIG  -lglib-2.0 -lintl -liconv -lgthread-2.0 -lgmodule-2.0 -lffi  -lz"
export PATH="$PATH:${ANDROID_BUILD_TOP}/usr/local/bin"
export LD_LIBRARY_PATH="${ANDROID_BUILD_TOP}/usr/local/lib:${ANDROID_BUILD_TOP}/usr/lib:${ANDROID_NDK_TOP}/sources/cxx-stl/gnu-libstdc++/4.6/libs/armeabi-v7a"
buildTryNoreconf libsoup-2.39.4.1 "--disable-silent-rules --disable-introspection --without-gnome"
export PATH=$KLAATU_PATH_ORIG
export LD_LIBRARY_PATH_ORIG=$KLAATU_LD_LIBRARY_PATH_ORIG


# webkitgtk-test-fonts-0.0.3
# this is just an rsync
export CFLAGS="$KLAATU_CFLAGS_ORIG  "
export CXXFLAGS="$KLAATU_CXXFLAGS_ORIG "
export LDFLAGS="$KLAATU_LDFLAGS_ORIG"
echo "**** Working on webkitgtk-test-fonts-0.0.3 ****"
cd $KLAATU_BUILDDIR
untarTry webkitgtk-test-fonts-0.0.3
cd $KLAATU_BUILDDIR/webkitgtk-test-fonts-0.0.3
mkdir -p ${ANDROID_BUILD_TOP}/usr/local/share/fonts/truetype
rsync -a *.[to]tf ${ANDROID_BUILD_TOP}/usr/local/share/fonts/truetype
echo


# shared-mime-info-1.1
export CFLAGS="$KLAATU_CFLAGS_ORIG  "
export CXXFLAGS="$KLAATU_CXXFLAGS_ORIG "
export LDFLAGS="$KLAATU_LDFLAGS_ORIG  -lglib-2.0 -lintl -liconv -lgthread-2.0 -lgmodule-2.0 -lffi  -lz"
buildTryNoreconf shared-mime-info-1.1 "--disable-silent-rules --disable-nls --disable-update-mimedb"
export PATH=$KLAATU_PATH_ORIG
export LD_LIBRARY_PATH_ORIG=$KLAATU_LD_LIBRARY_PATH_ORIG

# ca-certs
# talk about hacks.  this is just swiped from an Ubuntu 12.04 workstation.
echo "**** Working on ca-certs HACK ****"
mkdir -p ${ANDROID_BUILD_TOP}/usr/local/etc/ssl
mkdir -p ${ANDROID_BUILD_TOP}/usr/local/share
tar xf ${KLAATU_SUPPORTDIR}/ca-certs-ubuntu-12.04.tar.bz2 -C ${ANDROID_BUILD_TOP}/usr/local

# KlaatuPhoneEnvSet
rsync -a  ${KLAATU_SUPPORTDIR}/KlaatuPhoneEnvSet ${ANDROID_BUILD_TOP}/usr/local/bin

# webkit nix. very very special case
export CFLAGS="$KLAATU_CFLAGS_ORIG  "
export CXXFLAGS="$KLAATU_CXXFLAGS_ORIG "
export LDFLAGS="$KLAATU_LDFLAGS_ORIG"
echo "LDFLAGS I am using are: $LDFLAGS"
# the complicated cmake command is in the supportdir
# also, cmake loves to find the build tools in the outmoded 
# ndk or aosp path so we need a clean path for the build
# we put /usr/local first to allow you to shadow less desirable
# versions
export PATH="/usr/local/bin:/bin:/usr/sbin:/usr/bin:`dirname ${KLAATU_TC}`:.:$KLAATU_SUPPORTDIR"
WEBKITNIX_BRANCH=`cat $KLAATU_SUPPORTDIR/WebKitNixBranch | head -1`
buildWebKitNix webkitnix-${WEBKITNIX_BRANCH}
export PATH=$KLAATU_PATH_ORIG
