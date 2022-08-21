#!/bin/bash

target_plat="$1"
llvm_path="$2"
llvm_version="$3"
extra_params=
archive_plat=

case ${target_plat} in
      linux-x86_64)
            archive_plat="x86_64-linux"
            ;;
      mac-x86_64)
            archive_plat="x86_64-darwin"
            ;;
      mac-arm64)
            archive_plat="amd64-darwin"
            ;;
      win32-x86_64)
            archive_plat="x86_64-win32"
            extra_params="-DCMAKE_C_COMPILER=${TOOLCHAIN_PATH}/x86_64-w64-mingw32-clang -DCMAKE_CXX_COMPILER=${TOOLCHAIN_PATH}/x86_64-w64-mingw32-clang++ -DCMAKE_RC_COMPILER=${TOOLCHAIN_PATH}/x86_64-w64-mingw32-windres -DCMAKE_SYSTEM_NAME=Windows -DCROSS_TOOLCHAIN_FLAGS_NATIVE=-DCMAKE_TOOLCHAIN_FILE=$(pwd)/Toolchain-NATIVE.cmake"

            ;;
      *)
            echo "Unknown platform: ${target_plat}" >&2
            exit 1
            ;;
esac

if [ ! -d "${llvm_path}" ] ; then
      echo "LLVM folder doesn't exist: ${llvm_path}"
      exit 2
fi

if [ "${llvm_version}" == "" ] ; then
      echo "LLVM version is not set"
      exit 3
fi

flavor="${target_plat}"

pushd "${llvm_path}" > /dev/null

cmake -S llvm -B build-$flavor \
      -G Ninja \
      $EXTRA_PARAMS \
      -DLLVM_ENABLE_THREADS=OFF \
      -DCMAKE_BUILD_TYPE=Release \
      -DLLVM_TARGETS_TO_BUILD="" \
      -DLLVM_STATIC_LINK_CXX_STDLIB=ON \
      -DLLVM_BUILD_LLVM_DYLIB=ON \
      -DLLVM_LINK_LLVM_DYLIB=ON \
      -DLLVM_BUILD_EXAMPLES=OFF \
      -DLLVM_INCLUDE_TESTS=OFF \
      -DLLVM_INCLUDE_EXAMPLES=OFF \
      -DLLVM_ENABLE_PROJECTS="clang" \
      -DCLANG_ENABLE_STATIC_ANALYZER=OFF \
      -DCLANG_ENABLE_ARCMT=OFF \
      -DLLVM_ENABLE_LIBXML2=OFF \
      -DCMAKE_INSTALL_PREFIX=$(pwd)/usr-$flavor \
      -DLLVM_STATIC_LINK_CXX_STDLIB=ON \
      -DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS=ON
if [ $? != 0 ] ; then
      echo "Failed to generate build scripts for Clang" >&2
      exit 4
fi

pushd build-$flavor > /dev/null
      ninja
      if [ $? != 0 ] ; then
            echo "Failed to build Clang" >&2
            exit 5
      fi

      ninja install
      if [ $? != 0 ] ; then
            echo "Failed to install Clang" >&2
            exit 6
      fi
popd > /dev/null

full_path=
pushd usr-$flavor > /dev/null
      full_path="$(pwd)/llvm+clang-${llvm_version}-${archive_plat}.tar.xz"
      tar cJvf ${full_path} *
popd > /dev/null

popd > /dev/null

