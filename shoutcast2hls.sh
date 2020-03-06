#!/bin/bash
#
# Shoutcast2HLS.sh, version 1
# by Arnaud de Mouhy <arnaud.demouhy@akerbis.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

set -eu

function print_usage {
    cat << EOF
Usage: ./shoutcast2hls.sh [options] <stream> where options are:

        -f <format>    | --output-format <format>       : Output encoding. Possible values are 'mp3', 'aac' or 'copy'.
                                                          The default value is 'copy'.
        -d <directory> | --output-directory <directory> : Output directory
                                                          The default value is '/tmp'
        -n <name>      | --name <name>                  : Output playlist name
                                                          The default value is 'playlist'
        -b <bitrates>  | --bitrates <bitrates>          : List of output bitrates expressed in kilobytes, separated by colons (:)
                                                          The default value is '32:64:128'
        -c <time>      | --chunk-time <time>            : Chunck time in seconds for each HLS element
                                                          The default value is '10'
        -k <time>      | --keep-chunk <time>            : Get old chunck for 'x' minutes
                                                          The default value is '1'

Example:
        ./shoutcast2hls.sh -d /usr/share/nginx/html -f mp3 -n morow -b 64:128 http://stream.morow.com:8080/morow_hi.aacp
EOF
}

function is_array() {
    local variable_name=$1
    [[ "$(declare -p $variable_name)" =~ "declare -a" ]]
}

function is_program_exist() {
    local r='0'
    type $1 >/dev/null 2>&1 || { local r='1'; }
    if [ ! "$r" -eq '0' ]; then
        error "$2"
    fi
}

platform=`uname`
if [ "$platform" == "Darwin" ]; then
    echo "OS X is not yet supported"
    exit 1;
fi

if [ $# -eq 0 ]; then
    print_usage
    exit 0
fi

echo $0 $@

## Defaults
OUTPUT_FORMAT="copy"
OUTPUT_DIRECTORY="/tmp"
PLAYLIST_NAME="playlist"
BITRATES="32:64:128"
CHUNK_SIZE=10
CHUNK_KEEP=1
#####

while [[ $# -gt 1 ]]; do
    key="$1"

    case $key in
        -c|--chunk-time)
            CHUNK_SIZE="$2"
            shift # past argument
            ;;
        -f|--output-format)
            OUTPUT_FORMAT="$2"
            shift # past argument
            ;;
        -k|--keep-chunk)
            CHUNK_KEEP="$2"
            shift # past argument
            ;;
        -d|--output-directory)
            OUTPUT_DIRECTORY="$2"
            shift # past argument
            ;;
        -n|--playlist-name)
            PLAYLIST_NAME="$2"
            shift # past argument
            ;;
        -b|--bitrates)
            BITRATES="$2"
            shift
            ;;
        -*)
            # unknown option
            echo
            echo "!! Unknown option $1"
            echo
            print_usage
            exit 1
            ;;
        *)
            # stream
            ;;
    esac
    shift # past argument or value
done

INPUT_STREAM=$1

if [ -z "$INPUT_STREAM" ]; then
    echo " !! Missing stream argument"
    print_usage
    exit 1
fi

if [ ! -d "$OUTPUT_DIRECTORY" ]; then
    echo "The output directory '$OUTPUT_DIRECTORY' is not a valid directory"
    print_usage
    exit 1
fi

if [ -z "${PLAYLIST_NAME}" ]; then
    PLAYLIST_NAME="playlist"
fi

if [[ $CHUNK_SIZE =~ ^-?[0-9]+$ && $CHUNK_SIZE > 0 ]]; then
    echo "Chunk time: $CHUNK_SIZE ok"
else
    echo "$CHUNK_SIZE is not a valid chunk time number"
fi

if [[ $CHUNK_KEEP =~ ^-?[0-9]+$ && $CHUNK_KEEP > 0 ]]; then
    echo "Keep the last $CHUNK_KEEP minute(s)"
else
    echo "$CHUNK_KEEP is not a valid time to keep chunk"
fi

IFS=':' read -a bitrates <<< "$BITRATES"
echo "Checking bitrates…"
for bitrate in "${bitrates[@]}"
do
    if [[ ${bitrate[@]} =~ ^-?[0-9]+$ && ${bitrate[@]} > 0 ]]; then
        echo "${bitrate[@]} is a valid bitrate number"
    else
        echo "${bitrate[@]} is not a valid bitrate number"
        print_usage
        exit 1
    fi
done

OUTPUT_LIB="copy"
case $OUTPUT_FORMAT in
    "aac")
        OUTPUT_LIB="libfdk_aac"
        ;;
    "mp3")
        OUTPUT_LIB="libmp3lame"
        ;;
    "copy")
        OUTPUT_LIB="copy"
        ;;
esac

echo "Detecting bitrate for $INPUT_STREAM stream… (it may take a while)"
is_program_exist "ffprobe" "ffprobe is not found. Please setup ffprobe first"
found_bitrate=$(ffprobe -show_format $INPUT_STREAM < /dev/null 2> /dev/null | grep icy-br | cut -d= -f2)
if [ -z "$found_bitrate" ]; then
echo "+ Cannot find the bitrate… Are you sure it is a Shoutcast stream ?"
exit 1
fi
echo "+ Found ${found_bitrate}k"

final_playlist="${OUTPUT_DIRECTORY}/${PLAYLIST_NAME}.m3u8"
echo "Writing variant playlist ${final_playlist}"
if [ -f "$final_playlist" ]; then
    rm $final_playlist
fi
touch $final_playlist
echo "#EXTM3U" >> $final_playlist

sbitrates=($(printf '%s\n' "${bitrates[@]}"|sort -r -n))
for index in "${!sbitrates[@]}"
do
    stream_playlist="${OUTPUT_DIRECTORY}/${PLAYLIST_NAME}_${sbitrates[$index]}k.m3u8"

    if [ "$OUTPUT_LIB" != "copy" ]; then
        bitrate_opt="-b:a ${sbitrates[$index]}k"
    fi
    if [ "$OUTPUT_LIB" == "libfdk_aac" -a "${sbitrates[$index]}" -lt "128" ]; then
        bitrate_opt="${bitrate_opt} -profile:a aac_he"
    fi
    if [ "$OUTPUT_LIB" == "libfdk_aac" -a "${sbitrates[$index]}" -lt "48" ]; then
        bitrate_opt="${bitrate_opt} -profile:a aac_he_v2"
    fi

    echo "New converter from $INPUT_STREAM to ${stream_playlist}…"
    echo "+ Output format: $OUTPUT_FORMAT"
    echo "+ Output bitrate: ${sbitrates[$index]}k"
    echo "+ Output playlist file $stream_playlist"
    is_program_exist "ffmpeg" "ffmpeg is not found. Please setup ffmpeg first"
    ffmpeg -i "$INPUT_STREAM" -vn -sn -c:a $OUTPUT_LIB $bitrate_opt -hls_time $CHUNK_SIZE $stream_playlist 2> /dev/null &

    echo "#EXT-X-STREAM-INF:BANDWIDTH=${sbitrates[$index]}000" >> $final_playlist
    echo "$(basename ${stream_playlist})" >> $final_playlist
done

echo "+++ The playlist is available at ${final_playlist}"

while true;
do
    sleep $(($CHUNK_KEEP * 60))
    echo "Removing files older than $CHUNK_KEEP minute(s)"
    find $OUTPUT_DIRECTORY -name \*.ts -mmin +$CHUNK_KEEP -delete
done
