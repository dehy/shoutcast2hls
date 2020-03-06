#!/bin/bash

cd /tmp/
git clone --depth 1 https://github.com/mstorsjo/fdk-aac
cd fdk-aac/
autoreconf -fiv
./configure --disable-shared
make
make install

cd ../
rm -rf fdk-aac/