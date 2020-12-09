#!/bin/bash

#This script will compile and install a static ffmpeg build with support for nvenc un ubuntu.
#See the prefix path and compile options if edits are needed to suit your needs.

#install required things from apt
installLibs(){
echo "Installing prerequisites"
sudo apt-get update
sudo apt-get -y --force-yes install autoconf automake build-essential libass-dev libfreetype6-dev libgpac-dev \
  libsdl1.2-dev libtheora-dev libtool libva-dev libvdpau-dev libvorbis-dev libxcb1-dev libxcb-shm0-dev \
  libxcb-xfixes0-dev pkg-config texi2html zlib1g-dev
}

#install CUDA SDK
InstallCUDASDK(){
echo "Installing CUDA and the latest driver repositories from repositories"
cd ~/ffmpeg_sources
wget -c -v -nc https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/cuda-repo-ubuntu1604_9.2.88-1_amd64.deb
sudo dpkg -i cuda-repo-ubuntu1604_9.2.88-1_amd64.deb
sudo apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/7fa2af80.pub
sudo apt-get -y update
sudo apt-get -y install cuda
sudo add-apt-repository ppa:graphics-drivers/ppa
sudo apt-get update && sudo apt-get -y upgrade
}

#Install nvidia SDK
installSDK(){
echo "Installing the nVidia NVENC SDK."
cd ~/ffmpeg_sources
cd ~/ffmpeg_sources
git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
cd nv-codec-headers
make
sudo make install
}

#Compile nasm
compileNasm(){
echo "Compiling nasm"
cd ~/ffmpeg_sources
wget http://www.nasm.us/pub/nasm/releasebuilds/2.14rc0/nasm-2.14rc0.tar.gz
tar xzvf nasm-2.14rc0.tar.gz
cd nasm-2.14rc0
./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin"
make -j$(nproc)
make -j$(nproc) install
make -j$(nproc) distclean
}

#Compile libfdk-acc
compileLibfdkcc(){
echo "Compiling libfdk-cc"
sudo apt-get install unzip
cd ~/ffmpeg_sources
wget -O fdk-aac.zip https://github.com/mstorsjo/fdk-aac/zipball/master
unzip fdk-aac.zip
cd mstorsjo-fdk-aac*
autoreconf -fiv
./configure --prefix="$HOME/ffmpeg_build" --disable-shared
make -j$(nproc)
make -j$(nproc) install
make -j$(nproc) distclean
}

#Compile ffmpeg
compileFfmpeg(){
echo "Compiling ffmpeg"
cd ~/ffmpeg_sources
git clone https://github.com/FFmpeg/FFmpeg -b master
cd FFmpeg
PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
  --enable-cuda-nvcc \
  --enable-cuvid \
  --enable-libnpp \
  --extra-cflags="-I/usr/local/cuda/include/" \
  --extra-ldflags=-L/usr/local/cuda/lib64/ \
  --enable-gpl \
  --enable-libass \
  --enable-libfdk-aac \
  --enable-vaapi \
  --enable-libfreetype \
  --enable-libtheora \
  --enable-libvorbis \
  --enable-nonfree \
  --enable-nvenc
PATH="$HOME/bin:$PATH" make -j$(nproc)
sudo make -j$(nproc) install
make -j$(nproc) distclean
hash -r
}

#The process
cd ~
mkdir ffmpeg_sources
installLibs
InstallCUDASDK
installSDK
compileNasm
compileLibfdkcc
compileFfmpeg
echo "Complete!"