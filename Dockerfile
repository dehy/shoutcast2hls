FROM ubuntu:15.04
MAINTAINER Arnaud de Mouhy <arnaud.demouhy@akerbis.com>

RUN sed -i -e 's/\(universe\)$/\1 multiverse/g' /etc/apt/sources.list

RUN apt-get update \
 && apt-get -y upgrade \
 && apt-get -y install build-essential pkg-config yasm nginx \
                       libfdk-aac0 libfdk-aac-dev libmp3lame0 libmp3lame-dev

ADD https://www.libav.org/releases/libav-11.4.tar.gz /tmp/
WORKDIR /tmp
RUN tar xvf libav-11.4.tar.gz \
 && cd /tmp/libav-11.4 \
 && ./configure --disable-avplay \
            --disable-avserver \
            --enable-libfdk-aac \
            --enable-libmp3lame \
            --enable-nonfree \
 && make \
 && make install

#RUN apt-get -y purge build-essential pkg-config yasm libfdk-aac-dev libmp3lame-dev \
# && apt-get -y autoremove \
# && rm -rf /var/lib/apt/lists/* \
# && rm -rf /tmp/*

ADD rootfs /
ADD shoutcast2hls.sh /

CMD ["bash", "/entrypoint.sh"]
