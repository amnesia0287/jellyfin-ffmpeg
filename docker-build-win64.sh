#!/bin/bash

# Builds the EXE/ZIP inside the Docker container

set -o errexit
set -o xtrace

# Update mingw-w64 headers
git clone --depth=1 https://github.com/mirror/mingw-w64.git
pushd mingw-w64/mingw-w64-headers
./configure \
    --prefix=/usr/${FF_TOOLCHAIN} \
    --host=${FF_TOOLCHAIN} \
    --with-default-win32-winnt="0x601" \
    --enable-idl
make -j$(nproc)
make install
popd

# mingw-std-threads
git clone --depth=1 https://github.com/meganz/mingw-std-threads.git
pushd mingw-std-threads
mkdir -p ${FF_DEPS_PREFIX}/include
mv *.h ${FF_DEPS_PREFIX}/include
popd

# ICONV
mkdir iconv
pushd iconv
iconv_ver="1.16"
iconv_link="https://ftp.gnu.org/pub/gnu/libiconv/libiconv-${iconv_ver}.tar.gz"
wget ${iconv_link} -O iconv.tar.gz
tar xaf iconv.tar.gz
pushd libiconv-${iconv_ver}
./configure \
    --prefix=${FF_DEPS_PREFIX} \
    --host=${FF_TOOLCHAIN} \
    --disable-shared \
    --enable-{static,extra-encodings} \
    --with-pic
make -j$(nproc)
make install
popd
popd

# LIBXML2
git clone --depth=1 https://gitlab.gnome.org/GNOME/libxml2.git
pushd libxml2
./autogen.sh \
    --prefix=${FF_DEPS_PREFIX} \
    --host=${FF_TOOLCHAIN} \
    --disable-{shared,maintainer-mode} \
    --enable-static \
    --without-python
make -j$(nproc)
make install
popd

# ZLIB
git clone --depth=1 https://github.com/madler/zlib.git
pushd zlib
./configure \
    --prefix=${FF_DEPS_PREFIX} \
    --static
make -j$(nproc) CC=${FF_CROSS_PREFIX}gcc AR=${FF_CROSS_PREFIX}ar
make install
popd

# FREETYPE
mkdir freetype
pushd freetype
ft_ver="2.11.1"
ft_link="https://sourceforge.net/projects/freetype/files/freetype2/${ft_ver}/freetype-${ft_ver}.tar.xz/download"
wget ${ft_link} -O ft.tar.gz
tar xaf ft.tar.gz
pushd freetype-${ft_ver}
./configure \
    --prefix=${FF_DEPS_PREFIX} \
    --host=${FF_TOOLCHAIN} \
    --disable-shared \
    --enable-static
make -j$(nproc)
make install
popd
popd

# FRIBIDI
git clone --depth=1 https://github.com/fribidi/fribidi.git
pushd fribidi
mkdir build
pushd build
meson \
    --prefix=${FF_DEPS_PREFIX} \
    --cross-file=${FF_MESON_TOOLCHAIN} \
    --buildtype=release \
    --default-library=static \
    -D{bin,docs,tests}=false \
    ..
ninja -j$(nproc)
meson install
sed -i 's/Cflags:/Cflags: -DFRIBIDI_LIB_STATIC/' ${FF_DEPS_PREFIX}/lib/pkgconfig/fribidi.pc
popd
popd

# GMP
mkdir gmp
pushd gmp
gmp_ver="6.2.1"
gmp_link="https://ftp.gnu.org/gnu/gmp/gmp-${gmp_ver}.tar.xz"
wget ${gmp_link} -O gmp.tar.gz
tar xaf gmp.tar.gz
pushd gmp-${gmp_ver}
autoreconf -i
./configure \
    --prefix=${FF_DEPS_PREFIX} \
    --host=${FF_TOOLCHAIN} \
    --disable-shared \
    --enable-static
make -j$(nproc)
make install
popd
popd

# LZMA
mkdir xz
pushd xz
xz_ver="5.2.5"
xz_link="https://sourceforge.net/projects/lzmautils/files/xz-${xz_ver}.tar.xz/download"
wget ${xz_link} -O xz.tar.xz
tar xaf xz.tar.xz
pushd xz-${xz_ver}
./configure \
    --prefix=${FF_DEPS_PREFIX} \
    --host=${FF_TOOLCHAIN} \
    --disable-shared \
    --enable-static \
    --with-pic
make -j$(nproc)
make install
popd
popd

# SDL2
mkdir sdl2
pushd sdl2
sdl2_ver="2.0.20"
sdl2_link="https://libsdl.org/release/SDL2-${sdl2_ver}.tar.gz"
wget ${sdl2_link} -O sdl2.tar.gz
tar xaf sdl2.tar.gz
pushd SDL2-${sdl2_ver}
./autogen.sh
./configure \
    --prefix=${FF_DEPS_PREFIX} \
    --host=${FF_TOOLCHAIN} \
    --disable-shared \
    --enable-static
make -j$(nproc)
make install
popd
popd

# FONTCONFIG
mkdir fontconfig
pushd fontconfig
fc_ver="2.13.96"
fc_link="https://www.freedesktop.org/software/fontconfig/release/fontconfig-${fc_ver}.tar.xz"
wget ${fc_link} -O fc.tar.gz
tar xaf fc.tar.gz
pushd fontconfig-${fc_ver}
./configure \
    --prefix=${FF_DEPS_PREFIX} \
    --host=${FF_TOOLCHAIN} \
    --disable-{shared,docs} \
    --enable-{static,libxml2,iconv}
make -j$(nproc)
make install
popd
popd

# HARFBUZZ
git clone --depth=1 https://github.com/harfbuzz/harfbuzz.git
pushd harfbuzz
./autogen.sh \
    --prefix=${FF_DEPS_PREFIX} \
    --host=${FF_TOOLCHAIN} \
    --disable-shared \
    --enable-static \
    --with-pic
make -j$(nproc)
make install
popd

# LIBUDFREAD
git clone --depth=1 https://code.videolan.org/videolan/libudfread.git
pushd libudfread
./bootstrap
./configure \
    --prefix=${FF_DEPS_PREFIX} \
    --host=${FF_TOOLCHAIN} \
    --disable-shared \
    --enable-static \
    --with-pic
make -j$(nproc)
make install
popd

# LIBASS
git clone --depth=1 https://github.com/libass/libass.git
pushd libass
./autogen.sh
./configure \
    --prefix=${FF_DEPS_PREFIX} \
    --host=${FF_TOOLCHAIN} \
    --disable-shared \
    --enable-static \
    --with-pic
make -j$(nproc)
make install
popd

# LIBBLURAY
git clone --depth=1 https://code.videolan.org/videolan/libbluray.git
pushd libbluray
./bootstrap
./configure \
    --prefix=${FF_DEPS_PREFIX} \
    --host=${FF_TOOLCHAIN} \
    --disable-{shared,examples,bdjava-jar} \
    --disable-doxygen-{doc,dot,html,ps,pdf} \
    --enable-static \
    --with-pic
make -j$(nproc)
make install
popd

# LAME
mkdir lame
pushd lame
lame_ver="3.100"
lame_link="https://sourceforge.net/projects/lame/files/lame/${lame_ver}/lame-${lame_ver}.tar.gz/download"
wget ${lame_link} -O lame.tar.gz
tar xaf lame.tar.gz
pushd lame-${lame_ver}
./configure \
    --prefix=${FF_DEPS_PREFIX} \
    --host=${FF_TOOLCHAIN} \
    --disable-{shared,gtktest,cpml,frontend} \
    --enable-{static,nasm}
make -j$(nproc)
make install
popd
popd

# OGG
git clone --depth=1 https://github.com/xiph/ogg.git
pushd ogg
./autogen.sh
./configure \
    --prefix=${FF_DEPS_PREFIX} \
    --host=${FF_TOOLCHAIN} \
    --disable-shared \
    --enable-static \
    --with-pic
make -j$(nproc)
make install
popd

# OPUS
git clone --depth=1 https://github.com/xiph/opus.git
pushd opus
./autogen.sh
./configure \
    --prefix=${FF_DEPS_PREFIX} \
    --host=${FF_TOOLCHAIN} \
    --disable-{shared,extra-programs} \
    --enable-static
make -j$(nproc)
make install
popd

# THEORA
git clone --depth=1 https://github.com/xiph/theora.git
pushd theora
./autogen.sh
./configure \
    --prefix=${FF_DEPS_PREFIX} \
    --host=${FF_TOOLCHAIN} \
    --disable-{shared,examples,extra-programs,oggtest,vorbistest,spec,doc} \
    --enable-static \
    --with-pic
make -j$(nproc)
make install
popd

# VORBIS
git clone --depth=1 https://github.com/xiph/vorbis.git
pushd vorbis
./autogen.sh
./configure \
    --prefix=${FF_DEPS_PREFIX} \
    --host=${FF_TOOLCHAIN} \
    --disable-{shared,oggtest} \
    --enable-static
make -j$(nproc)
make install
popd

# LIBWEBP
git clone --depth=1 https://chromium.googlesource.com/webm/libwebp
pushd libwebp
./autogen.sh
./configure \
    --prefix=${FF_DEPS_PREFIX} \
    --host=${FF_TOOLCHAIN} \
    --disable-{shared,libwebpextras,libwebpdemux,sdl,gl,png,jpeg,tiff,gif} \
    --enable-{static,libwebpmux} \
    --with-pic
make -j$(nproc)
make install
popd

# LIBVPX
git clone --depth=1 https://chromium.googlesource.com/webm/libvpx
pushd libvpx
export CROSS=${FF_CROSS_PREFIX}
./configure \
    --prefix=${FF_DEPS_PREFIX} \
    --target=x86_64-win64-gcc \
    --disable-{shared,unit-tests,examples,tools,docs,install-bins} \
    --enable-{static,pic,vp9-postproc,vp9-highbitdepth}
make -j$(nproc)
make install
popd

# ZIMG
git clone --depth=1 https://github.com/sekrit-twc/zimg.git
pushd zimg
./autogen.sh
./configure \
    --prefix=${FF_DEPS_PREFIX} \
    --host=${FF_TOOLCHAIN} \
    --disable-shared \
    --enable-pic \
    --with-pic
make -j$(nproc)
make install
popd

# X264
git clone --depth=1 https://code.videolan.org/videolan/x264.git
pushd x264
./configure \
    --prefix=${FF_DEPS_PREFIX} \
    --host=${FF_TOOLCHAIN} \
    --cross-prefix=${FF_CROSS_PREFIX} \
    --disable-cli \
    --enable-{static,lto,strip,pic}
make -j$(nproc)
make install
popd

# X265
git clone -b 3.5 --depth=1 https://bitbucket.org/multicoreware/x265_git.git
pushd x265_git
x265_conf="
    -DCMAKE_TOOLCHAIN_FILE=${FF_CMAKE_TOOLCHAIN}
    -DCMAKE_INSTALL_PREFIX=${FF_DEPS_PREFIX}
    -DCMAKE_ASM_NASM_FLAGS=-w-macro-params-legacy
    -DENABLE_ASSEMBLY=ON
    -DENABLE_SHARED=OFF
    -DENABLE_TESTS=OFF
    -DENABLE_CLI=OFF
    -DENABLE_PIC=ON
"
mkdir 8b 10b 12b
cmake \
    ${x265_conf} \
    -DHIGH_BIT_DEPTH=ON \
    -DEXPORT_C_API=OFF \
    -DENABLE_HDR10_PLUS=ON \
    -DMAIN12=ON \
    -S source \
    -B 12b &
cmake \
    ${x265_conf} \
    -DHIGH_BIT_DEPTH=ON \
    -DEXPORT_C_API=OFF \
    -DENABLE_HDR10_PLUS=ON \
    -S source \
    -B 10b &
cmake \
    ${x265_conf} \
    -DEXTRA_LIB="x265_main10.a;x265_main12.a" \
    -DEXTRA_LINK_FLAGS=-L. \
    -DLINKED_{10,12}BIT=ON \
    -S source \
    -B 8b &
wait
cat > Makefile << "EOF"
all: 12b/libx265.a 10b/libx265.a 8b/libx265.a
%/libx265.a:
	$(MAKE) -C $(subst /libx265.a,,$@)
.PHONY: all
EOF
make -j$(nproc)
pushd 8b
mv ../12b/libx265.a ../8b/libx265_main12.a
mv ../10b/libx265.a ../8b/libx265_main10.a
mv libx265.a libx265_main.a
${FF_CROSS_PREFIX}ar -M << "EOF"
CREATE libx265.a
ADDLIB libx265_main.a
ADDLIB libx265_main10.a
ADDLIB libx265_main12.a
SAVE
END
EOF
make install
popd
popd

# DAV1D
git clone -b 1.0.0 --depth=1 https://code.videolan.org/videolan/dav1d.git
pushd dav1d
mkdir build
pushd build
meson \
    --prefix=${FF_DEPS_PREFIX} \
    --cross-file=${FF_MESON_TOOLCHAIN} \
    --buildtype=release \
    --default-library=static \
    -Denable_asm=true \
    -Denable_{tools,tests,examples}=false \
    ..
ninja -j$(nproc)
meson install
popd
popd

# OpenCL headers
git clone --depth=1 https://github.com/KhronosGroup/OpenCL-Headers
pushd OpenCL-Headers/CL
mkdir -p ${FF_DEPS_PREFIX}/include/CL
mv * ${FF_DEPS_PREFIX}/include/CL
popd

# OpenCL ICD loader
git clone -b v2022.01.04 --depth=1 https://github.com/KhronosGroup/OpenCL-ICD-Loader.git
pushd OpenCL-ICD-Loader
mkdir build
pushd build
cmake \
    -DCMAKE_TOOLCHAIN_FILE=${FF_CMAKE_TOOLCHAIN} \
    -DCMAKE_INSTALL_PREFIX=${FF_DEPS_PREFIX} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DOPENCL_ICD_LOADER_HEADERS_DIR=${FF_DEPS_PREFIX}/include \
    -DOPENCL_ICD_LOADER_{PIC,DISABLE_OPENCLON12}=ON \
    -DOPENCL_ICD_LOADER_{BUILD_TESTING,REQUIRE_WDK}=OFF \
    ..
make -j$(nproc)
make install
popd
mkdir -p ${FF_DEPS_PREFIX}/lib/pkgconfig
cat > ${FF_DEPS_PREFIX}/lib/pkgconfig/OpenCL.pc << EOF
prefix=${FF_DEPS_PREFIX}
exec_prefix=\${prefix}
libdir=\${prefix}/lib
includedir=\${prefix}/include
Name: OpenCL
Description: OpenCL ICD Loader
Version: 3.0
Libs: -L\${libdir} -lOpenCL
Cflags: -I\${includedir}
Libs.private: -lole32 -lshlwapi -lcfgmgr32
EOF
popd

# FFNVCODEC
git clone -b n11.0.10.1 --depth=1 https://github.com/FFmpeg/nv-codec-headers.git
pushd nv-codec-headers
make PREFIX=${FF_DEPS_PREFIX} install
popd

# AMF
git clone --depth=1 https://github.com/GPUOpen-LibrariesAndSDKs/AMF
pushd AMF/amf/public/include
mkdir -p ${FF_DEPS_PREFIX}/include/AMF
mv * ${FF_DEPS_PREFIX}/include/AMF
popd

# LIBMFX
git clone -b 1.35.1 --depth=1 https://github.com/lu-zero/mfx_dispatch.git
pushd mfx_dispatch
autoreconf -i
./configure \
    --prefix=${FF_DEPS_PREFIX} \
    --host=${FF_TOOLCHAIN} \
    --disable-shared \
    --enable-static \
    --with-pic
make -j$(nproc)
make install
popd

# Jellyfin-FFmpeg
pushd ${SOURCE_DIR}
ffversion="$(cat RELEASE)-${FF_REV}"
if [[ -f "patches/series" ]]; then
    quilt push -a
fi
./configure \
    --prefix=${FF_PREFIX} \
    ${FF_TARGET_FLAGS} \
    --extra-version=Jellyfin \
    --disable-ffplay \
    --disable-debug \
    --disable-doc \
    --disable-w32threads \
    --enable-pthreads \
    --enable-shared \
    --enable-lto \
    --enable-gpl \
    --enable-version3 \
    --enable-schannel \
    --enable-iconv \
    --enable-libxml2 \
    --enable-zlib \
    --enable-lzma \
    --enable-sdl2 \
    --enable-gmp \
    --enable-libfreetype \
    --enable-libfribidi \
    --enable-libfontconfig \
    --enable-libass \
    --enable-libbluray \
    --enable-libmp3lame \
    --enable-libopus \
    --enable-libtheora \
    --enable-libvorbis \
    --enable-libwebp \
    --enable-libvpx \
    --enable-libzimg \
    --enable-libx264 \
    --enable-libx265 \
    --enable-libdav1d \
    --enable-opencl \
    --enable-dxva2 \
    --enable-d3d11va \
    --enable-amf \
    --enable-libmfx \
    --enable-ffnvcodec \
    --enable-cuda \
    --enable-cuda-llvm \
    --enable-cuvid \
    --enable-nvdec \
    --enable-nvenc
make -j$(nproc)
make install
popd

# Zip and copy artifacts
mkdir -p ${ARTIFACT_DIR}/zip
pushd ${FF_PREFIX}/bin
ffpackage="jellyfin-ffmpeg_${ffversion}-windows_win64"
zip -r ${ARTIFACT_DIR}/zip/${ffpackage}.zip ./*.{exe,dll}
pushd ${ARTIFACT_DIR}/zip
sha256sum ./${ffpackage}.zip > ./${ffpackage}.zip.sha256sum
chown -Rc $(stat -c %u:%g ${ARTIFACT_DIR}) ${ARTIFACT_DIR}
popd
popd
