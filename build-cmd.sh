#!/usr/bin/env bash

cd "$(dirname "$0")" 

echo "Building tracy library"

# turn on verbose debugging output for parabuild logs.
set -x
# make errors fatal
set -e
# complain about unset env variables
set -u

# Check autobuild is around or fail
if [ -z "$AUTOBUILD" ] ; then 
    exit 1
fi

if [ "$OSTYPE" = "cygwin" ] ; then
    autobuild="$(cygpath -u $AUTOBUILD)"
else
    autobuild="$AUTOBUILD"
fi

top="$(pwd)"
stage_dir="$(pwd)/stage"
mkdir -p "$stage_dir"
tmp_dir="$(pwd)/tmp"
mkdir -p "$tmp_dir"

# Load autobuild provided shell functions and variables
srcenv_file="$tmp_dir/ab_srcenv.sh"
"$autobuild" source_environment > "$srcenv_file"
. "$srcenv_file"

build_id=${AUTOBUILD_BUILD_ID:=0}
tracy_version="$(sed -n -E 's/(v[0-9]+\.[0-9]+\.[0-9]+) \(.+\)/\1/p' tracy/NEWS | head -1)"
echo "${tracy_version}.${build_id}" > "${stage_dir}/VERSION.txt"

source_dir="tracy"
pushd "$source_dir"
    case "$AUTOBUILD_PLATFORM" in
        windows*)
            load_vsvars

            cmake . -G "$AUTOBUILD_WIN_CMAKE_GEN" -DCMAKE_C_FLAGS="$LL_BUILD_RELEASE"
            build_sln "tracy.sln" "Release|$AUTOBUILD_WIN_VSPLATFORM" "tracy"

            mkdir -p "$stage_dir/lib/release"
            mv Release/tracy.lib "$stage_dir/lib/release"

            mkdir -p "$stage_dir/include/tracy"
            cp *.hpp "$stage_dir/include/tracy/"

            mkdir -p "$stage_dir/include/tracy/common"
            cp common/*.hpp "$stage_dir/include/tracy/common"
            cp common/*.h "$stage_dir/include/tracy/common"

            mkdir -p "$stage_dir/include/tracy/client"
            cp client/*.hpp "$stage_dir/include/tracy/client"
            cp client/*.h "$stage_dir/include/tracy/client"
        ;;

        darwin*)
            cmake . -DCMAKE_INSTALL_PREFIX:STRING="${stage_dir}" \
                    -DCMAKE_C_FLAGS="$LL_BUILD_RELEASE"
            make
            make install

            mkdir -p "$stage_dir/lib/release"
            mv "$stage_dir/lib/libtracy.a" "$stage_dir/lib/release/libtracy.a"

            mkdir -p "$stage_dir/include/tracy"
            cp Tracy.hpp "$stage_dir/include/tracy/"
            cp TracyOpenGL.hpp "$stage_dir/include/tracy/"

            rm -r "$stage_dir/lib/cmake"
        ;;
    esac
popd

# copy license file
mkdir -p "$stage_dir/LICENSES"
cp tracy/LICENSE "$stage_dir/LICENSES/tracy_license.txt"
