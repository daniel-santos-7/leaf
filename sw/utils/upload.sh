#!/bin/bash

chmod 777 /dev/ttyUSB0

stty -F /dev/ttyUSB0 speed 9600 cs8 -cstopb -parenb

echo "sending data ..."

echo '1' > /dev/ttyUSB0

cat $1 /dev/zero | head -c64k > /dev/ttyUSB0

echo "OK"

cat /dev/ttyUSB0