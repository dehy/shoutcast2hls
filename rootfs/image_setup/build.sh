#!/bin/bash

set -xeu

apk add curl lame bash
apk add --virtual .build-dependencies build-base gnupg yasm git autoconf automake libtool lame-dev

cd /image_setup/

/bin/bash /image_setup/build_libfdk-aac.sh

curl http://ffmpeg.org/releases/ffmpeg-4.2.2.tar.gz > ffmpeg-4.2.2.tar.gz

gpg --recv-keys B4322F04D67658D8
gpg --verify ffmpeg-4.2.2.tar.gz.asc

tar xvf ffmpeg-4.2.2.tar.gz
cd ./ffmpeg-*/
./configure \
    --disable-ffplay \
    --disable-doc \
    --enable-libfdk-aac \
    --enable-libmp3lame \
    --enable-nonfree
make
make install

mv /image_setup/entrypoint.sh /

cd ../
rm -rf ./ffmpeg-*
apk del .build-dependencies
