#!/bin/bash

target_plat="$1"
cvc5_path="$2"
cvc5_version="$3"
toolchain_path="$4"
extra_params=
archive_plat=
is_win32=

case ${target_plat} in
	linux-x86_64)
	    archive_plat="x86_64-linux"
	    ;;
	mac-x86_64)
	    archive_plat="x86_64-darwin"
	    extra_params="-DCMAKE_OSX_ARCHITECTURES=x86_64"
	    ;;
	mac-arm64)
	    archive_plat="amd64-darwin"
	    extra_params="-DCMAKE_OSX_ARCHITECTURES=arm64"
	    ;;
	win32-x86_64)
	    archive_plat="x86_64-win32"
	    is_win32=y
	    extra_params="-DCMAKE_C_COMPILER=${TOOLCHAIN_PATH}/x86_64-w64-mingw32-clang -DCMAKE_CXX_COMPILER=${TOOLCHAIN_PATH}/x86_64-w64-mingw32-clang++ -DCMAKE_RC_COMPILER=${TOOLCHAIN_PATH}/x86_64-w64-mingw32-windres -DCMAKE_SYSTEM_NAME=Windows -DCROSS_TOOLCHAIN_FLAGS_NATIVE=-DCMAKE_TOOLCHAIN_FILE=$(pwd)/Toolchain-NATIVE.cmake"
	    git clone https://github.com/maximmenshikov/mingw-to-clang.git
	    ;;
	*)
	    echo "Unknown platform: ${target_plat}" >&2
	    exit 1
	    ;;
esac

if [ ! -d "${cvc5_path}" ] ; then
    echo "CVC5 folder doesn't exist: ${cvc5_path}"
    exit 2
fi

if [ "${cvc5_version}" == "" ] ; then
	echo "CVC5 version is not set"
	exit 3
fi

if [ ! -d "${toolchain_path}" ] ; then
	echo "Toolchain doesn't exit"
	exit 4
fi

export PATH="$(pwd)/mingw-to-clang:${toolchain_path}/bin:$PATH"
echo $(pwd)/mingw-to-clang:${toolchain_path}/bin
exit 1
flavor="${target_plat}"

pushd ${cvc5_path} > /dev/null
./configure.sh production ${is_win32:+--win64} --ninja --auto-download --prefix=$(pwd)/usr-${target_plat}
pushd build > /dev/null
ninja
if [ $? != 0 ] ; then
	echo "Failed to build CVC5" >&2
	exit 5
fi
ninja install
if [ $? != 0 ] ; then
	echo "Failed to install CVC5" >&2
	exit 6
fi
popd > /dev/null
popd > /dev/null
