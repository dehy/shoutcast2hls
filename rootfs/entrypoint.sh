#!/bin/bash

if [ ! -z "$OUTPUT_DIRECTORY" ]; then
    opt_d="-d $OUTPUT_DIRECTORY"
fi

if [ ! -z "$FORMAT" ]; then
    opt_f="-f $FORMAT"
fi

if [ ! -z "$BITRATES" ]; then
    opt_b="-b $BITRATES"
fi

if [ ! -z "$PLAYLIST_NAME" ]; then
    opt_n="-n $PLAYLIST_NAME"
fi


bash /shoutcast2hls.sh $opt_d $opt_f $opt_b $opt_n $STREAM
