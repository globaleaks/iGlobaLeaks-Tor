#!/bin/bash
#  Builds tor for all three current iPhone targets: iPhoneSimulator-i386,
#  iPhoneOS-armv6, iPhoneOS-armv7.
#
#  Copyright 2012 Mike Tigas <mike@tig.as>
#
#  Based on work by Felix Schulze on 16.12.10.
#  Copyright 2010 Felix Schulze. All rights reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
###########################################################################
#  Choose your tor version and your currently-installed iOS SDK version:
#
VERSION="0.2.4.15-rc"
SDKVERSION="6.1"
VERIFYGPG=false
#
#
###########################################################################
#
# Don't change anything under this line!
#
###########################################################################

# No need to change this since xcode build will only compile in the
# necessary bits from the libraries we create
ARCHS="i386 armv7 armv7s"

DEVELOPER=`xcode-select -print-path`

cd "`dirname \"$0\"`"
REPOROOT=$(pwd)

# Where we'll end up storing things in the end
OUTPUTDIR="${REPOROOT}/dependencies"
mkdir -p ${OUTPUTDIR}/include
mkdir -p ${OUTPUTDIR}/lib


BUILDDIR="${REPOROOT}/build"

# where we will keep our sources and build from.
SRCDIR="${BUILDDIR}/src"
mkdir -p $SRCDIR
# where we will store intermediary builds
INTERDIR="${BUILDDIR}/built"
mkdir -p $INTERDIR

########################################

cd $SRCDIR

# Exit the script if an error happens
set -e

if [ ! -e "${SRCDIR}/tor-${VERSION}.tar.gz" ]; then
	echo "Downloading tor-${VERSION}.tar.gz"
	#curl -O https://archive.torproject.org/tor-package-archive/tor-${VERSION}.tar.gz
	curl -O https://www.torproject.org/dist/tor-${VERSION}.tar.gz
fi
echo "Using tor-${VERSION}.tar.gz"

# see https://www.torproject.org/docs/verifying-signatures.html.en
# and https://www.torproject.org/docs/signing-keys.html.en
# up to you to set up `gpg` and add keys to your keychain
if $VERIFYGPG; then
	if [ ! -e "${SRCDIR}/tor-${VERSION}.tar.gz.asc" ]; then
		curl -O https://www.torproject.org/dist/tor-${VERSION}.tar.gz.asc
	fi
	echo "Using tor-${VERSION}.tar.gz.asc"
	if out=$(gpg --status-fd 1 --verify "tor-${VERSION}.tar.gz.asc" "tor-${VERSION}.tar.gz" 2>/dev/null) &&
	echo "$out" | grep -qs "^\[GNUPG:\] VALIDSIG"; then
		echo "$out" | egrep "GOODSIG|VALIDSIG"
		echo "Verified GPG signature for source..."
	else
		echo "$out" >&2
		echo "COULD NOT VERIFY PACKAGE SIGNATURE..."
		exit 1
	fi
fi

rm -fr "${SRCDIR}/tor-${VERSION}"
tar zxf tor-${VERSION}.tar.gz -C $SRCDIR
cd "${SRCDIR}/tor-${VERSION}"

####
# Patch to remove the "DisableDebuggerAttachment" ptrace() calls
# that are not allowed in App Store apps
patch -p3 < ../../../build-patches/tor-ptrace.diff

# Patch to remove "_NSGetEnviron()" call not allowed in App Store
# apps (even fails to compile under iPhoneSDK due to that function
# being undefined)
patch -p3 < ../../../build-patches/tor-nsenviron.diff

#####
# Collect libz.dylib from the iPhoneSimulator.sdk and iPhoneOS.sdk (already contains armv6 and armv7)
# and compile into a single libz.a file (since that is what tor is looking for)

lipo -create ${DEVELOPER}/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator${SDKVERSION}.sdk/usr/lib/libz.dylib \
${DEVELOPER}/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS${SDKVERSION}.sdk/usr/lib/libz.dylib \
-output ${OUTPUTDIR}/lib/libz.a

cp -R ${DEVELOPER}/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator${SDKVERSION}.sdk/usr/include/zlib* ${OUTPUTDIR}/include/

# Copy ptrace in (since the header is only available on iPhoneSimulator.sdk
# but the compile steps still need it for iPhoneOS)
mkdir -p ${OUTPUTDIR}/include/sys/
cp -R ${DEVELOPER}/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator${SDKVERSION}.sdk/usr/include/sys/ptrace.h ${OUTPUTDIR}/include/sys/

#####
# Now compile tor

cd "${SRCDIR}/tor-${VERSION}"

set +e # don't bail out of bash script if ccache doesn't exist
CCACHE=`which ccache`
if [ $? == "0" ]; then
	echo "Building with ccache: $CCACHE"
	CCACHE="${CCACHE} "
else
	echo "Building without ccache"
	CCACHE=""
fi
set -e # back to regular "bail out on error" mode

for ARCH in ${ARCHS}
do
	if [ "${ARCH}" == "i386" ];
	then
		PLATFORM="iPhoneSimulator"
		EXTRA_CONFIG=""
	else
		PLATFORM="iPhoneOS"
		EXTRA_CONFIG="--host=arm-apple-darwin11 --target=arm-apple-darwin11 --disable-gcc-hardening --disable-linker-hardening"
	fi

	mkdir -p "${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"
	mkdir -p "${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/include"
	mkdir -p "${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/lib"

	./configure ${EXTRA_CONFIG} \
	--prefix="${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" \
	--enable-static-openssl --enable-static-libevent --enable-static-zlib \
	--with-openssl-dir="${OUTPUTDIR}" \
	--with-libevent-dir="${OUTPUTDIR}" \
	--with-zlib-dir="${OUTPUTDIR}" \
	--disable-asciidoc \
	CC="${CCACHE}${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/usr/bin/gcc -arch ${ARCH}" \
	LDFLAGS="$LDFLAGS -L${OUTPUTDIR}/lib" \
	CFLAGS="$CFLAGS -I${OUTPUTDIR}/include -isysroot ${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk" \
	CPPFLAGS="$CPPFLAGS -I${OUTPUTDIR}/include -isysroot ${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk"

	# Build the application
	make -j4

	# Don't make install. We actually don't want the tor binary or the
	# documentation, we just want the archives of the compiled sources.
	cp src/common/libor-crypto.a "${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/lib/"
	cp src/common/libor-event.a "${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/lib/"
	cp src/common/libor.a "${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/lib/"
	cp src/common/libcurve25519_donna.a "${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/lib/"
	cp src/or/libtor.a "${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/lib/"

	mkdir -p "${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/include/common/"
	mkdir -p "${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/include/or/"
	mkdir -p "${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/include/tools/"
	cp micro-revision.i "${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/include/"
	cp orconfig.h "${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/include/"
	cp src/ext/ht.h "${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/include/"
	find src/common -name "*.h" -exec cp {} "${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/include/common/" \;
	find src/or -name "*.h" -exec cp {} "${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/include/or/" \;
	find src/or -name "*.i" -exec cp {} "${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/include/or/" \;
	find src/tools -name "*.h" -exec cp {} "${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/include/tools/" \;
	make clean
done

########################################

echo "Build library..."

# These are the libs that comprise tor's internals
OUTPUT_LIBS="libor-crypto.a libor-event.a libor.a libtor.a libcurve25519_donna.a"
for OUTPUT_LIB in ${OUTPUT_LIBS}; do
	INPUT_LIBS=""
	for ARCH in ${ARCHS}; do
		if [ "${ARCH}" == "i386" ];
		then
			PLATFORM="iPhoneSimulator"
		else
			PLATFORM="iPhoneOS"
		fi
		INPUT_ARCH_LIB="${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/lib/${OUTPUT_LIB}"
		if [ -e $INPUT_ARCH_LIB ]; then
			INPUT_LIBS="${INPUT_LIBS} ${INPUT_ARCH_LIB}"
		fi
	done
	# Combine the three architectures into a universal library.
	if [ -n "$INPUT_LIBS"  ]; then
		lipo -create $INPUT_LIBS \
		-output "${OUTPUTDIR}/lib/${OUTPUT_LIB}"
	else
		echo "$OUTPUT_LIB does not exist, skipping (are the dependencies installed?)"
	fi
done

for ARCH in ${ARCHS}; do
	if [ "${ARCH}" == "i386" ];
	then
		PLATFORM="iPhoneSimulator"
	else
		PLATFORM="iPhoneOS"
	fi
	cp -R ${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/include/* ${OUTPUTDIR}/include/
	if [ $? == "0" ]; then
		# We only need to copy the headers over once. (So break out of forloop
		# once we get first success.)
		break
	fi
done

mkdir -p ${OUTPUTDIR}/share
cp "${SRCDIR}/tor-${VERSION}/src/config/geoip" ${OUTPUTDIR}/share

####################

echo "Building done."
echo "Cleaning up..."
# Remove the copy of libz we created. (Our XCode project will use the system
# version.) Ditto with sys/pthread.h.
rm -f ${OUTPUTDIR}/lib/libz.a
rm -f ${OUTPUTDIR}/include/zlib*
rm -fr ${OUTPUTDIR}/include/sys/

# Remove intermediary and source directories
rm -fr ${INTERDIR}
rm -fr "${SRCDIR}/tor-${VERSION}"
echo "Done."
