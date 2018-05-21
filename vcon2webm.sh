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
if echo "$OUT" | grep -Eiq ".mp4$"; then
  #echo "--- x264, First Pass"
  ffmpeg -i "${IN}" \
    -hide_banner -loglevel error -stats -strict experimental \
    -codec:v libx264 -threads 0 -profile:v baseline -level 3.0 -preset slow \
    -b:v 1500k -maxrate 1500k -bufsize 3000k -pix_fmt yuv420p \
    -codec:a aac -b:a 192k \
    -pass 1 \
    -f mp4 \
    -y /dev/null
  #echo "--- x264, Second Pass"
  ffmpeg -i "${IN}" \
    -hide_banner -loglevel error -stats -strict experimental -movflags +faststart \
    -codec:v libx264 -threads 0 -profile:v baseline -level 3.0 -preset slow \
    -b:v 1500k -maxrate 1500k -bufsize 3000k -pix_fmt yuv420p \
    -codec:a aac -b:a 192k \
    -pass 2 \
    -y "${OUT}"
else
  #echo "--- webm, First Pass"
  ffmpeg -i "${IN}" \
    -hide_banner -loglevel error -stats \
    -codec:v libvpx -threads $CORES -slices 4 -deadline good -cpu-used 4 \
    -b:v 1500k -crf 10 -qmin 10 -qmax 42 -maxrate 1500k -bufsize 3000k -pix_fmt yuv420p \
    -codec:a libvorbis -qscale:a 6 \
    -pass 1 \
    -f webm \
    -y /dev/null

  #echo "--- webm, Second Pass"
  ffmpeg -i "${IN}" \
    -hide_banner -loglevel error -stats -movflags +faststart \
    -codec:v libvpx -threads $CORES -slices 4 -deadline good -cpu-used 1 \
    -b:v 1500k -crf 10 -qmin 10 -qmax 42 -maxrate 1500k -bufsize 3000k -pix_fmt yuv420p \
    -auto-alt-ref 1 -lag-in-frames 25 \
    -codec:a libvorbis -qscale:a 6 \
    -pass 2 \
    -f webm \
    -y "${OUT}"
fi
