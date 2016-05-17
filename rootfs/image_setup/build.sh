#!/bin/bash

set -xeu

sed -i \
    -e 's/\(universe\)$/\1 multiverse/g' \
    -e 's#http://archive\.ubuntu\.com/ubuntu/#mirror://mirrors.ubuntu.com/mirrors.txt#g' \
    /etc/apt/sources.list

apt-get update
apt-get -y --no-install-recommends install \
    build-essential pkg-config yasm nginx curl ca-certificates \
    libfdk-aac0 libfdk-aac-dev libmp3lame0 libmp3lame-dev

cd /image_setup/

curl https://www.libav.org/releases/libav-11.6.tar.gz > libav-11.6.tar.gz

sha1sum -c libav-11.6.tar.gz.sha1
gpg --keyserver x-hkp://pool.sks-keyservers.net --recv-keys E8F3A190
gpg --verify libav-11.6.tar.gz{.asc*,}

tar xvf libav-11.6.tar.gz
cd ./libav-*
./configure \
    --disable-avplay \
    --enable-libfdk-aac \
    --enable-libmp3lame \
    --enable-nonfree
make
make install

mv /image_setup/entrypoint.sh /

cd /

apt-get -y purge build-essential pkg-config yasm libfdk-aac-dev libmp3lame-dev curl
apt-get -y autoremove
rm -rf /var/lib/apt/lists/* /tmp/* /usr/share/man/*
