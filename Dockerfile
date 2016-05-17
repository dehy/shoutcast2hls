FROM ubuntu:16.04
MAINTAINER Arnaud de Mouhy <arnaud.demouhy@akerbis.com>

ENV STREAM "http://stream.morow.com:8080/morow_hi.aacp"
ENV OUTPUT_DIRECTORY "/usr/share/nginx/html"
ENV FORMAT "aac"
ENV PLAYLIST_NAME "morow"
ENV BITRATES "32:64:128"

RUN sed -i -e 's/\(universe\)$/\1 multiverse/g' /etc/apt/sources.list

RUN apt-get update \
 && apt-get -y --no-install-recommends install build-essential pkg-config yasm nginx \
                       libfdk-aac0 libfdk-aac-dev libmp3lame0 libmp3lame-dev

ADD https://www.libav.org/releases/libav-11.6.tar.gz /tmp/
WORKDIR /tmp
RUN tar xvf libav-11.6.tar.gz \
 && cd /tmp/libav-11.6 \
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
