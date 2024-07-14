#!/bin/bash

set -ex

FFMPEG_SOURCE=$SOURCE_DIR/ffmpeg
TOOLCHAIN_ROOT=/binary/toolchain
export PATH=$TOOLCHAIN_ROOT/bin:$PATH

export SYSROOT=$TOOLCHAIN_ROOT/x86_64-pc-linux-gnu/sys-root/
export CC=x86_64-pc-linux-gnu-gcc
export CXX=x86_64-pc-linux-gnu-g++

function build_x265 {
    if [ ! -d "$SOURCE_DIR/x265" ]; then
        git clone https://bitbucket.org/multicoreware/x265_git.git $SOURCE_DIR/x265
    fi

    pushd $BUILD_DIR
    rm -rf x265
    mkdir x265
    pushd x265

    cmake -S $SOURCE_DIR/x265/source -B . \
        -G Ninja \
        -DCMAKE_SYSTEM_NAME=Linux \
        -DCMAKE_SYSTEM_PROCESSOR=i686 \
        -DCMAKE_C_COMPILER=$CC \
        -DCMAKE_CXX_COMPILER=$CXX \
        -DCMAKE_FIND_ROOT_PATH=$SYSROOT \
        -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
        -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
        -DENABLE_SHARED=OFF \
        -DCMAKE_SYSROOT=$SYSROOT \
        -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR 
    
    cmake --build . --target install --config Release --parallel $(nproc)

    popd
    popd
}

function build_openssl {
    if [ ! -d "$SOURCE_DIR/openssl" ]; then
        wget https://www.openssl.org/source/openssl-3.3.1.tar.gz -O $SOURCE_DIR/openssl.tar.gz
        tar -xvf $SOURCE_DIR/openssl.tar.gz -C $SOURCE_DIR
        mv $SOURCE_DIR/openssl-3.3.1 $SOURCE_DIR/openssl
        rm $SOURCE_DIR/openssl.tar.gz
    fi

    pushd $BUILD_DIR
    rm -rf openssl
    mkdir openssl
    pushd openssl

    $SOURCE_DIR/openssl/Configure linux-generic32 \
        --prefix=$INSTALL_DIR \
        --openssldir=$INSTALL_DIR \
        -static
    
    make -j$(nproc)
    make install        # TODO: disable docs to speed up build

    popd
    popd
}

function build_ffmpeg {
    pushd $BUILD_DIR
    rm -rf ffmpeg
    mkdir ffmpeg

    pushd ffmpeg

    export EXTRA_C_FLAGS="-I$INSTALL_DIR/include"
    export EXTRA_LDFLAGS="-L$INSTALL_DIR/lib"
    export PKG_CONFIG_PATH="$INSTALL_DIR/lib/pkgconfig"

    CMD="$FFMPEG_SOURCE/configure \
        --prefix=$INSTALL_DIR \
        --target-os=linux \
        --arch=i686 \
        --cross-prefix=x86_64-pc-linux-gnu- \
        --extra-cflags="$EXTRA_C_FLAGS" \
        --extra-ldflags="$EXTRA_LDFLAGS" \
        --pkg-config-flags="--static" \
        --enable-cross-compile \
        --sysroot=$SYSROOT \
        --enable-static --disable-shared \
        --disable-ffplay --disable-doc \
        --disable-debug \
        --enable-gpl --enable-nonfree \
        --enable-protocol=file --enable-protocol=http \
        --disable-x86asm"
    
    if [ "$ENABLE_LIBX265" = "1" ]; then
        build_x265
        CMD="$CMD --enable-libx265"
    fi

    if [ "$ENABLE_HTTPS" = "1" ]; then
        build_openssl
        CMD="$CMD --enable-openssl --enable-protocol=https"
    fi

    $CMD

    make -j$(nproc)
    make install

    popd
    popd
}

build_ffmpeg