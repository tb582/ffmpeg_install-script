#!/bin/bash -
#title           :ffmpeg.sh
#description     :This script will install ffmpeg and related codecs on	Centos7 
#author          :tb582
#date            :20171005
#version         :0.1
#usage           :bash ffmpeg.sh
#notes	         :We'll	use this as our	general	guide and fix/correct issues as	we find	them https://trac.ffmpeg.org/wiki/CompilationGuide/Centos
#bash_version    :4.2.46(1)-release (x86_64-redhat-linux-gnu)
#==============================================================================

today=$(date +%Y%m%d)
div=======================================

#Ensure Dependencies are installed and avail
sudo yum install yum-utils
sudo yum-config-manager --add-repo http://www.nasm.us/nasm.repo
sudo yum install autoconf automake bzip2 cmake freetype-devel gcc gcc-c++ git libtool make mercurial nasm pkgconfig zlib-devel
mkdir ~/ffmpeg_sources
cd ~
sudo yum install yasm
sudo make install

#Compile and Install

#NASM
cd /etc/yum.repo.d/
wget http://nasm.us/nasm.repo
sudo yum install nasm

#libx264
cd ~/ffmpeg_sources
git clone --depth 1 http://git.videolan.org/git/x264
cd x264
PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --enable-static
make
make install
echo

#libx265
cd ~/ffmpeg_sources
hg clone https://bitbucket.org/multicoreware/x265
cd ~/ffmpeg_sources/x265/build/linux
cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_SHARED:bool=off ../../source
make
make install
echo

#libfdk_aac
cd ~/ffmpeg_sources
git clone --depth 1 https://github.com/mstorsjo/fdk-aac
cd fdk-aac
autoreconf -fiv
./configure --prefix="$HOME/ffmpeg_build" --disable-shared
make
make install
echo

#libmp3lame
cd ~/ffmpeg_sources
curl -L -O http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.5.tar.gz
tar xzvf lame-3.99.5.tar.gz
cd lame-3.99.5
./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin" --disable-shared --enable-nasm
make
make install
echo

#libogg
cd ~/ffmpeg_sources
curl -O https://ftp.osuosl.org/pub/xiph/releases/ogg/libogg-1.3.2.tar.gz
tar xzvf libogg-1.3.2.tar.gz
cd libogg-1.3.2
./configure --prefix="$HOME/ffmpeg_build" --disable-shared
make
make install
echo

#libvorbis
cd ~/ffmpeg_sources
curl -L -O https://ftp.osuosl.org/pub/xiph/releases/vorbis/libvorbis-1.3.5.zip
unzip libvorbis-1.3.5.zip
sleep 3
cd libvorbis-1.3.5
./configure --prefix="$HOME/ffmpeg_build" --with-ogg="$HOME/ffmpeg_build" --disable-shared
make
make install
echo

#libvpx
cd ~/ffmpeg_sources
git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git
cd libvpx
./configure --prefix="$HOME/ffmpeg_build" --disable-examples --disable-unit-tests --enable-vp9-highbitdepth --as=yasm
PATH="$HOME/bin:$PATH" make
make install
echo

#FFmpeg
cd ~/ffmpeg_sources
curl -O http://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
tar xjvf ffmpeg-snapshot.tar.bz2
cd ffmpeg
PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure --prefix="$HOME/ffmpeg_build" \
  --extra-cflags="-I$HOME/ffmpeg_build/include" --extra-ldflags="-L$HOME/ffmpeg_build/lib -ldl" \
  --bindir="$HOME/bin" --pkg-config-flags="--static" \
  --enable-gpl \
  --enable-libfdk_aac \
  --enable-libfreetype \
  --enable-libmp3lame \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libx264 \
  --enable-libx265 \
  --enable-nonfree
make
make install
hash -r

# Create a weekly cron to keep things updated
rm ~/ffmpeg_update.sh
touch  ~/ffmpeg_update.sh
echo "0 0 7 * * ~/ffmpeg_update.sh > ~/cron.log" >> cronjob
crontab cronjob
rm cronjob

cat > ~/ffmpeg_update.sh << EOF
rm -rf ~/ffmpeg_build ~/bin/{ffmpeg,ffprobe,ffserver,lame,x264,x265}
sudo yum install autoconf automake cmake freetype-devel gcc gcc-c++ git libtool make mercurial nasm pkgconfig zlib-devel

# Update x264
cd ~/ffmpeg_sources/x264
make distclean
git pull
./configure
make
sudo make install

# Update x265
cd ~/ffmpeg_sources/x265
rm -rf ~/ffmpeg_sources/x265/build/linux/*
hg update
cd ~/ffmpeg_sources/x265/build/linux
cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_SHARED:bool=off ../../source
make
make install

#Update libfdk_aac
cd ~/ffmpeg_sources/fdk_aac
make distclean
git pull
./configure
make
make install

#Update libvpx
cd ~/ffmpeg_sources/libvpx
make distclean
git pull
./configure
make
make install

#Update FFMPEG
rm -rf ~/ffmpeg_sources/ffmpeg
cd ~/ffmpeg_sources
curl -O http://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
tar xjvf ffmpeg-snapshot.tar.bz2
cd ffmpeg
PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure --prefix="$HOME/ffmpeg_build" \
  --extra-cflags="-I$HOME/ffmpeg_build/include" --extra-ldflags="-L$HOME/ffmpeg_build/lib -ldl" \
  --bindir="$HOME/bin" --pkg-config-flags="--static" \
  --enable-gpl \
  --enable-libfdk_aac \
  --enable-libfreetype \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libx264 \
  --enable-libx265 \
  --enable-nonfree
make
make install
hash -r
EOF
