# Cross compile FFmpeg for Synology NAS

FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    build-essential \
    ninja-build \
    pkg-config \
    cmake \
    autoconf \
    git \
    wget \
    curl \
    fd-find vim bat zsh # for debugging

RUN mkdir /source /binary /build /install
WORKDIR /source

ENV SOURCE_DIR=/source
ENV BUILD_DIR=/build
ENV INSTALL_DIR=/install

# Download toolchain
# For Synology 224+ only, TODO: add more toolchains
RUN wget "https://global.synologydownload.com/download/ToolChain/toolchain/7.2-72746/Intel%20x86%20Linux%204.4.302%20%28GeminiLake%29/geminilake-gcc1220_glibc236_x86_64-GPL.txz" \
    -O /binary/geminilake-toolchain.txz \
    && tar -xvf /binary/geminilake-toolchain.txz -C /binary \
    && mv /binary/x86_64-pc-linux-gnu /binary/toolchain \
    && rm /binary/geminilake-toolchain.txz

# Fetch FFmpeg
RUN wget https://ffmpeg.org/releases/ffmpeg-7.0.1.tar.xz \
    -O /source/ffmpeg-7.0.1.tar.xz \
    && tar -xvf /source/ffmpeg-7.0.1.tar.xz -C /source \
    && mv /source/ffmpeg-7.0.1 /source/ffmpeg \
    && rm /source/ffmpeg-7.0.1.tar.xz

# Copy build script into container
# Put build rules and logics into a separate script for better maintainability
COPY build.sh /source/build.sh
RUN chmod +x /source/build.sh

ARG enable_libvpx=0
ARG enable_libx265=0
ARG enable_libx264=0
ARG enable_https=0

ENV ENABLE_LIBVPX=$enable_libvpx
ENV ENABLE_LIBX265=$enable_libx265
ENV ENABLE_LIBX264=$enable_libx264
ENV ENABLE_HTTPS=$enable_https