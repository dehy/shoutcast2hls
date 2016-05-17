Shoutcast2HLS
===============

Shoutcast2HLS is a bash script embedded in a Docker container that can read any
Shoutcast audio stream and outputs a HTTP Live Streaming playlist.

It uses [libav](http://libav.org) as its core and creates a variant playlist for multiple bitrate streams.

## Usage

### Script-only

    ./shoutcast2hls.sh [options] <stream> where options are:
        -f <format>    | --output-format <format>       : Output encoding. Possible values are 'mp3', 'aac' or 'copy'.
                                                          The default is 'copy'.
        -d <directory> | --output-directory <directory> : Output directory
                                                          The default is '/tmp'
        -n <name>      | --name <name>                  : Output playlist name
                                                          The default is 'playlist'
        -b <bitrates>  | --bitrates <bitrates>          : List of output bitrates expressed in kilobits, separated by colons (:)
                                                          The default is '32:64:128'
        -c <time>      | --chunk-time <time>            : Chunck time in seconds for each HLS element
                                                          The default value is '10'
        -k <time>      | --keep-chunk <time>            : Get old chunck for 'x' minutes
                                                          The default value is '1'

Example:

    ./shoutcast2hls.sh -d /usr/share/nginx/html -f aac -n morow -b 32:64:128 http://stream.morow.com:8080/morow_hi.aacp

### Docker

    $ docker run -d -e "STREAM=http://stream.morow.com:8080/morow_hi.aacp" -e "OUTPUT_DIRECTORY=/usr/share/nginx/html" -e "FORMAT=aac" -e "BITRATES=32:64:128" -e "PLAYLIST_NAME=morow" --name shoutcast2hls akerbis/shoutcast2hls
    $ docker run -d -p 80:80 --volumes_from shoutcast2hls nginx:latest

### Docker Compose

    $ vi docker-compose.yml
    $ docker-compose up

The playlist file is now available at http://server/morow.m3u8

## Tutum

[![Deploy to Docker Cloud](https://files.cloud.docker.com/images/deploy-to-dockercloud.svg)](https://cloud.docker.com/stack/deploy/?repo=https://github.com/akerbis/shoutcast2hls.git)
