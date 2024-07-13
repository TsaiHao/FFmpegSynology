# Cross compile FFmpeg for Synology NAS

FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    autoconf \
    git \
    wget \
    curl

RUN mkdir /sources /binaries /downloads
WORKDIR /sources

# Download toolchain
# For Synology 224+ only, TODO: add more toolchains
RUN wget https://global.synologydownload.com/download/ToolChain/toolchain/7.2-72746/Intel%20x86%20Linux%204.4.302%20%28GeminiLake%29/geminilake-gcc1220_glibc236_x86_64-GPL.txz \
    -o /downloads/geminilake-gcc1220_glibc236_x86_64-GPL.txz \
    && tar -xvf /downloads/geminilake-gcc1220_glibc236_x86_64-GPL.txz -C /binaries