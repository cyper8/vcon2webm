#!/bin/bash

[ $# -lt 1 ] && exit 1;
IN=${1}
OUT=${2:-${IN%.*}.webm}
CORES=$(grep -c ^processor /proc/cpuinfo)
#CORES=2
if [ "$CORES" -gt "1" ]; then
  CORES="$(($CORES - 1))"
fi
#echo "conv ${IN} to ${OUT} in $CORES threads (argc:$#)"
#echo "--- webm, First Pass"
ffmpeg -i "${IN}" \
    -hide_banner -loglevel error -stats \
    -codec:v libvpx -threads $CORES -slices 4 -deadline good -cpu-used 4 \
    -b:v 1500k -crf 10 -qmin 0 -qmax 42 -maxrate 1800k -bufsize 4000k -pix_fmt yuv420p \
    -codev:a libvorbis -qscale:a 6 \
    -pass 1 \
    -f webm \
    -y /dev/null

#echo "--- webm, Second Pass"
ffmpeg -i "${IN}" \
    -hide_banner -loglevel error -stats \
    -codec:v libvpx -threads $CORES -slices 4 -deadline good -cpu-used 1 \
    -b:v 1500k -crf 10 -qmin 0 -qmax 42 -maxrate 1800k -bufsize 4000k -pix_fmt yuv420p \
    -auto-alt-ref 1 -lag-in-frames 25 \
    -codec:a libvorbis -qscale:a 6 \
    -pass 2 \
    -f webm \
    -y "${OUT}"
