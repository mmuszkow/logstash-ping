#!/bin/bash
mkdir -p /opt/lib/
gcc -Wall -O2 -fpic -shared -o /opt/lib/libtinyping.so tinyping.c \
    || echo "Cannot install libtinyping.so" && exit 1
LS_DIR=""
for dir in /usr/local/logstash /opt/logstash; do
    [ -d "$dir" ] && LS_DIR="$dir" && break
done
if [ "x$LS_DIR" != "x" ]; then
    cp ping.rb $LS_DIR/lib/logstash/inputs/ && echo "Installed!"
else
    echo "Cannot determine Logstash location" && exit 2
fi
